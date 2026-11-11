import Contracts
import Foundation

/// Durable game state: what `status`, `period`, `event_*` and `stats_*` changes own
/// (backend plan §3). Equal values mean the same game on screen. The clock is not
/// here; it is an observation carried by pulses (`ClockObservation`).
public struct GameState: Sendable, Hashable {
    /// Fields no change ever carries: they come from the snapshot and never move.
    public struct Identity: Sendable, Hashable {
        public let id: String
        public let league: String
        public let providerGameId: String
        public let scheduledAt: String
        public let coverage: String
        public let homeTeamId: String?
        public let awayTeamId: String?
        /// The demo replay label (backend rev 4.15); nil for a real game.
        public let replay: ReplayKind?
    }

    /// One current play: the provider's ordering key (backend migration 0013) and its body.
    public struct Event: Sendable, Hashable {
        public let providerEventId: String
        public let providerSequence: Int?
        public let providerNumber: Int?
        public let body: LiveEvent
        /// `body.wallClock` parsed once, for ordering.
        let wallClockDate: Date?

        public init(providerEventId: String, providerSequence: Int?, providerNumber: Int?, body: LiveEvent) {
            self.providerEventId = providerEventId
            self.providerSequence = providerSequence
            self.providerNumber = providerNumber
            self.body = body
            self.wallClockDate = body.wallClock.flatMap(ISODate.parse)
        }

        /// The snapshot's order: period sequence, provider sequence, provider number,
        /// wall clock, provider event id; a missing value sorts first (SQL `nulls first`).
        public static func serverOrder(_ lhs: Event, _ rhs: Event) -> Bool {
            if lhs.body.period.sequence != rhs.body.period.sequence {
                return lhs.body.period.sequence < rhs.body.period.sequence
            }
            if let ordered = nullsFirst(lhs.providerSequence, rhs.providerSequence) { return ordered }
            if let ordered = nullsFirst(lhs.providerNumber, rhs.providerNumber) { return ordered }
            if let ordered = nullsFirst(lhs.wallClockDate, rhs.wallClockDate) { return ordered }
            return lhs.providerEventId < rhs.providerEventId
        }
    }

    public let identity: Identity
    public internal(set) var status: GameStatus
    public internal(set) var score: Score
    public internal(set) var period: PeriodRef?
    public internal(set) var elamTargetScore: Int?
    /// The line score, ordered by period sequence.
    public internal(set) var periods: [PeriodBody.Period]
    /// Team box lines by provider team id.
    public internal(set) var teamStats: [String: StatsTeamBody]
    /// Player box lines by provider player id (provider-keyed, like the backend's rows).
    public internal(set) var playerStats: [String: StatsPlayerBody]
    /// Current, non-deleted plays by provider event id.
    public internal(set) var eventsById: [String: Event]

    /// Current plays in the snapshot's order.
    public var events: [Event] {
        eventsById.values.sorted(by: Event.serverOrder)
    }
}

/// The clock as last observed (snapshot or pulse). `ClockModel` turns it into a display.
public struct ClockObservation: Sendable, Hashable {
    public let clock: String?
    public let clockDecimal: String?
    /// `true` counts down, `false` is stopped, `nil` is unknown (display frozen).
    public let running: Bool?
    public let asOf: String?
    public let observedAt: String?
}

/// What applying one change did.
public enum ChangeOutcome: Sendable, Equatable {
    /// Applied; `lastSeq` advanced by one. A change of a type this build does not know is
    /// applied too: its seq advances and nothing else changes (plan rev 4.11 (5)).
    case applied
    /// `seq <= lastSeq`: already folded (seq is the stream's unique key per game). Ignored.
    case duplicate
    /// `seq > lastSeq + 1`: something is missing. Ignored; the caller pages `/changes`.
    case gap(expected: Int, received: Int)
    /// A change of another game. Ignored.
    case foreignGame
}

/// What applying one pulse did.
public struct PulseOutcome: Sendable, Equatable {
    /// False when the pulse is not newer than the last observation (it changed nothing).
    public let applied: Bool
    /// The pulse reports a `latestSeq` beyond `lastSeq`: the caller pages `/changes`.
    public let behind: Bool
}

/// The pure reducer of one game (Wehoop M5 plan, LiveEngine). Built from a snapshot,
/// folded change by change in seq order; nothing else mutates game state.
public struct LiveGameState: Sendable, Hashable {
    public private(set) var game: GameState
    public private(set) var clock: ClockObservation
    public private(set) var lastSeq: Int
    /// Changes of a type this build did not know, folded as seq advances only.
    public private(set) var unknownChanges = 0

    public init(snapshot: Snapshot) {
        let g = snapshot.game
        game = GameState(
            identity: .init(
                id: g.id, league: g.league, providerGameId: g.providerGameId, scheduledAt: g.scheduledAt,
                coverage: snapshot.coverage, homeTeamId: g.homeTeamId, awayTeamId: g.awayTeamId,
                replay: g.replay
            ),
            status: g.status,
            score: g.score,
            period: g.period,
            elamTargetScore: g.elamTargetScore,
            periods: snapshot.periods
                .map { PeriodBody.Period(number: $0.number, type: $0.type, sequence: $0.sequence, score: $0.score) }
                .sorted { $0.sequence < $1.sequence },
            teamStats: Dictionary(snapshot.teamStats.map { ($0.providerTeamId, $0) }) { _, last in last },
            playerStats: Dictionary(snapshot.playerStats.map { ($0.providerPlayerId, $0) }) { _, last in last },
            eventsById: Dictionary(
                snapshot.events.map {
                    (
                        $0.providerEventId,
                        GameState.Event(
                            providerEventId: $0.providerEventId, providerSequence: $0.providerSequence,
                            providerNumber: $0.providerNumber, body: $0.body
                        )
                    )
                }
            ) { _, last in last }
        )
        clock = ClockObservation(
            clock: g.clock, clockDecimal: g.clockDecimal, running: g.clockRunning,
            asOf: g.clockAsOf, observedAt: g.observedAt
        )
        lastSeq = snapshot.seq
    }

    public var isClosed: Bool { game.status == .closed }

    /// Fold one change. Only `seq == lastSeq + 1` of this game changes anything.
    @discardableResult
    public mutating func apply(_ change: GameChange) -> ChangeOutcome {
        guard change.gameId == game.identity.id else { return .foreignGame }
        switch checkSequence(change.seq, after: lastSeq) {
        case .duplicate: return .duplicate
        case .gap: return .gap(expected: lastSeq + 1, received: change.seq)
        case .next: break
        }
        fold(change.type)
        lastSeq = change.seq
        return .applied
    }

    /// The effect of one change on the durable state (seq is handled by `apply`).
    private mutating func fold(_ kind: GameChange.Kind) {
        switch kind {
        case .eventInsert(let insert):
            game.eventsById[insert.providerEventId] = .init(
                providerEventId: insert.providerEventId, providerSequence: insert.providerSequence,
                providerNumber: insert.providerNumber, body: insert.body
            )
        case .eventUpdate(let update):
            game.eventsById[update.providerEventId] = .init(
                providerEventId: update.providerEventId, providerSequence: update.providerSequence,
                providerNumber: update.providerNumber, body: update.body
            )
        case .eventDelete(let delete):
            game.eventsById[delete.providerEventId] = nil
        case .status(let status):
            game.status = status.body.status
            game.score = status.body.score
            game.period = status.body.period
            // The backend omits the Elam target (never sends null) when the game has none.
            if let target = status.body.elamTargetScore { game.elamTargetScore = target }
        case .period(let period):
            game.periods = period.body.periods.sorted { $0.sequence < $1.sequence }
        case .statsTeam(let stats):
            game.teamStats[stats.body.providerTeamId] = stats.body
        case .statsPlayer(let stats):
            game.playerStats[stats.body.providerPlayerId] = stats.body
        case .unknown:
            unknownChanges += 1
        }
    }

    /// Fold one pulse: the newest `observedAt` wins, and only the clock moves. Pulses
    /// never touch score, period or status (backend plan §3).
    @discardableResult
    public mutating func apply(_ pulse: Pulse) -> PulseOutcome {
        guard pulse.gameId == game.identity.id else { return PulseOutcome(applied: false, behind: false) }
        let behind = pulse.latestSeq > lastSeq
        if let current = clock.observedAt.flatMap(ISODate.parse),
           let incoming = ISODate.parse(pulse.observedAt),
           incoming <= current {
            return PulseOutcome(applied: false, behind: behind)
        }
        clock = ClockObservation(
            clock: pulse.clock, clockDecimal: pulse.clockDecimal, running: pulse.clockRunning,
            asOf: pulse.clockAsOf, observedAt: pulse.observedAt
        )
        return PulseOutcome(applied: true, behind: behind)
    }
}

/// `nil` when equal, else whether `lhs` sorts first with missing values first.
func nullsFirst<T: Comparable>(_ lhs: T?, _ rhs: T?) -> Bool? {
    switch (lhs, rhs) {
    case (nil, nil): nil
    case (nil, _): true
    case (_, nil): false
    case let (lhs?, rhs?): lhs == rhs ? nil : lhs < rhs
    }
}

/// ISO 8601 timestamps as the backend writes them (`Z` or `+00:00`, with or without fractions).
enum ISODate {
    private static let styles: [Date.ISO8601FormatStyle] = [
        .init(includingFractionalSeconds: true),
        .init(),
        .init(timeZoneSeparator: .colon, includingFractionalSeconds: true),
        .init(timeZoneSeparator: .colon),
    ]

    static func parse(_ string: String) -> Date? {
        for style in styles {
            if let date = try? Date(string, strategy: style) { return date }
        }
        return nil
    }
}
