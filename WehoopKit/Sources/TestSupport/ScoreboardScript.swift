import Contracts
import Foundation
import LiveEngine

/// The Scores list's backend for fixture mode and tests: every league's golden `v_schedule`
/// rows laid out around `start`, with each golden game replayed through its recorded change
/// stream as the backend's `games` row would move, and the `league:{code}:scores` messages
/// the backend's 5 s sender would publish for it (backend plan §5).
///
/// - Each league's rows move by one offset, so the league's golden game tips off at `start`
///   and the other rows keep their distance to it (other days, or later the same day).
/// - A golden game's row is the game before any change until `start`; change `k` lands at
///   `start + k * stepInterval` (status, score, period, the last play's clock, seq), so the
///   game ends `count * stepInterval` after `start` and stays final.
/// - Golden games carry the demo label (`recorded`; `synthetic` for the hand-assembled
///   Unrivaled game), as the demo environment would show them (backend rev 4.15).
///
/// Time is an argument, never read from a clock, so every read is deterministic. Nothing
/// here edits a committed fixture: the rows are the goldens with fields replaced in memory.
public struct ScoreboardScript: Sendable {
    /// One game's row after some prefix of its change stream.
    struct Step: Sendable, Hashable {
        let seq: Int
        let status: Contracts.GameStatus
        let score: Score
        let period: PeriodRef?
        let clock: String?
        let elamTargetScore: Int?
    }

    struct Replayed: Sendable {
        let league: LeagueCode
        let replay: Contracts.ReplayKind
        /// Step 0 is the game before any change.
        let steps: [Step]
    }

    public let start: Date
    public let stepInterval: TimeInterval
    private let rowsByLeague: [String: [ScheduleRow]]
    private let replayed: [String: Replayed]

    public init(start: Date, stepInterval: TimeInterval = 0.2) throws {
        self.start = start
        self.stepInterval = stepInterval
        var replayed: [String: Replayed] = [:]
        var tipOff: [String: Date] = [:]
        for game in GoldenGame.allCases {
            let final = try Golden.snapshot(game)
            replayed[final.game.id] = Replayed(
                league: game.league, replay: Self.label(for: game),
                steps: Self.steps(from: Golden.pregameSnapshot(of: final), changes: try Golden.changes(game))
            )
            if tipOff[game.league.rawValue] == nil, let date = Self.parse(final.game.scheduledAt) {
                tipOff[game.league.rawValue] = date
            }
        }
        var rowsByLeague: [String: [ScheduleRow]] = [:]
        for league in LeagueCode.known {
            let offset = tipOff[league.rawValue].map { start.timeIntervalSince($0) } ?? 0
            rowsByLeague[league.rawValue] = try Golden.schedule(league).map { row in
                let moved = Self.parse(row.scheduledAt).map { $0.addingTimeInterval(offset) } ?? start
                return try Self.replacing(row, ["scheduled_at": Self.format(moved)])
            }
        }
        self.rowsByLeague = rowsByLeague
        self.replayed = replayed
    }

    /// The demo label a golden game carries in fixture mode.
    public static func label(for game: GoldenGame) -> Contracts.ReplayKind {
        game == .unrivaledElam ? .synthetic : .recorded
    }

    /// When the game `id` reaches its final row; nil for a game without a change stream.
    public func endTime(of id: String) -> Date? {
        replayed[id].map { time(ofStep: $0.steps.count - 1) }
    }

    // MARK: v_schedule

    /// The league's rows scheduled in `[from, to)` as they stand at `now`, by scheduled time.
    public func rows(league: LeagueCode, from: Date, to: Date, at now: Date) throws -> [ScheduleRow] {
        try (rowsByLeague[league.rawValue] ?? [])
            .filter { row in Self.parse(row.scheduledAt).map { $0 >= from && $0 < to } ?? false }
            .sorted { ($0.scheduledAt, $0.id) < ($1.scheduledAt, $1.id) }
            .map { try row($0, at: now) }
    }

    /// One row by game id as it stands at `now`.
    public func row(id: String, at now: Date) throws -> ScheduleRow? {
        for rows in rowsByLeague.values {
            if let row = rows.first(where: { $0.id == id }) { return try self.row(row, at: now) }
        }
        return nil
    }

    // MARK: league:{code}:scores

    /// The message the backend would publish at `through` for the league's games whose row
    /// moved in `(after, through]`, each with its row at `through`; nil when none moved.
    public func scoreboard(league: LeagueCode, after: Date, through: Date) -> Scoreboard? {
        let deltas = replayed
            .filter { $0.value.league == league }
            .sorted { $0.key < $1.key }
            .compactMap { id, game -> ScoreboardDelta? in
                let index = stepIndex(at: through, of: game)
                guard index != stepIndex(at: after, of: game) else { return nil }
                let step = game.steps[index]
                return ScoreboardDelta(
                    gameId: id, score: step.score, status: step.status, period: step.period, clock: step.clock,
                    latestSeq: step.seq, observedAt: Self.format(time(ofStep: index)), replay: game.replay
                )
            }
        guard !deltas.isEmpty else { return nil }
        return Scoreboard(v: 1, type: "scores", league: league, deltas: deltas, sentAt: Self.format(through))
    }

    // MARK: Steps

    private func stepIndex(at now: Date, of game: Replayed) -> Int {
        let elapsed = now.timeIntervalSince(start)
        guard elapsed >= stepInterval else { return 0 }
        return min(game.steps.count - 1, Int((elapsed / stepInterval).rounded(.down)))
    }

    private func time(ofStep index: Int) -> Date {
        start.addingTimeInterval(Double(index) * stepInterval)
    }

    private func row(_ row: ScheduleRow, at now: Date) throws -> ScheduleRow {
        guard let game = replayed[row.id] else { return row }
        let index = stepIndex(at: now, of: game)
        let step = game.steps[index]
        let observedAt: Any = index == 0 ? NSNull() : Self.format(time(ofStep: index))
        return try Self.replacing(row, [
            "status": step.status.rawValue,
            "home_points": step.score.home,
            "away_points": step.score.away,
            "current_period": Self.json(step.period?.number),
            "period_type": Self.json(step.period?.type.rawValue),
            "current_period_sequence": Self.json(step.period?.sequence),
            "elam_target_score": Self.json(step.elamTargetScore),
            "clock": Self.json(step.clock),
            "clock_decimal": NSNull(),
            "clock_running": NSNull(),
            "clock_as_of": observedAt,
            "observed_at": observedAt,
            "last_seq": step.seq,
            "replay": game.replay.rawValue,
        ])
    }

    /// The row after each prefix of the change stream, folded by LiveEngine.
    static func steps(from pregame: Snapshot, changes: [GameChange]) -> [Step] {
        var state = LiveGameState(snapshot: pregame)
        var clock: String?
        var steps = [Self.step(state, clock: clock)]
        for change in changes {
            state.apply(change)
            switch change.type {
            case .eventInsert(let insert): clock = insert.body.clock ?? clock
            case .eventUpdate(let update): clock = update.body.clock ?? clock
            default: break
            }
            steps.append(Self.step(state, clock: clock))
        }
        return steps
    }

    private static func step(_ state: LiveGameState, clock: String?) -> Step {
        let game = state.game
        return Step(
            seq: state.lastSeq, status: game.status, score: game.score, period: game.period,
            clock: game.period == nil ? nil : clock, elamTargetScore: game.elamTargetScore
        )
    }

    // MARK: JSON

    /// `row` with the given `v_schedule` columns replaced (NSNull for null).
    private static func replacing(_ row: ScheduleRow, _ fields: [String: Any]) throws -> ScheduleRow {
        guard var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(row)) as? [String: Any] else {
            return row
        }
        object.merge(fields) { _, new in new }
        return try JSONDecoder().decode(ScheduleRow.self, from: JSONSerialization.data(withJSONObject: object))
    }

    private static func json(_ value: (any Sendable)?) -> Any { value ?? NSNull() }

    private static let iso = Date.ISO8601FormatStyle(includingFractionalSeconds: true)

    static func format(_ date: Date) -> String { iso.format(date) }

    static func parse(_ string: String) -> Date? {
        for style in [
            iso, .init(), .init(timeZoneSeparator: .colon, includingFractionalSeconds: true), .init(timeZoneSeparator: .colon),
        ] {
            if let date = try? Date(string, strategy: style) { return date }
        }
        return nil
    }
}
