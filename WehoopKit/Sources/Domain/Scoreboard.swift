import Foundation

/// One game's line in a league scoreboard message (`league:{code}:scores`, backend plan §5):
/// the game's row as the backend last wrote it, sent at most every 5 s.
public struct ScoreUpdate: Sendable, Hashable {
    public let gameId: Game.ID
    public let score: Score
    public let status: GameStatus
    public let period: GamePeriod?
    /// Seconds left in the period as last observed; nil without a clock. The message does
    /// not say whether it runs, so a list shows it frozen.
    public let clockRemaining: Double?
    /// The highest change seq the backend had for the game.
    public let latestSeq: Int
    public let observedAt: Date?
    public let replay: ReplayKind?

    public init(
        gameId: Game.ID, score: Score, status: GameStatus, period: GamePeriod?, clockRemaining: Double?,
        latestSeq: Int, observedAt: Date?, replay: ReplayKind?
    ) {
        self.gameId = gameId
        self.score = score
        self.status = status
        self.period = period
        self.clockRemaining = clockRemaining
        self.latestSeq = latestSeq
        self.observedAt = observedAt
        self.replay = replay
    }
}

/// What a league's scoreboard subscription delivers.
public enum LiveScoresEvent: Sendable, Hashable {
    /// The channel joined or rejoined. Anything may have changed while it was away (the
    /// channel is best-effort and never replays), so the list re-reads the schedule.
    case subscribed
    /// Games of the league whose row changed, each with its latest state.
    case updates([ScoreUpdate])
}

/// Live score updates for list screens.
public protocol LiveScoresSource: Sendable {
    /// Updates of `league` while the consuming task runs. The stream finishes when the
    /// channel is lost for good; the caller subscribes again.
    func scores(league: League.Code) -> AsyncStream<LiveScoresEvent>
}

extension Game {
    /// Whether a reading of this game at (`seq`, `observedAt`) is newer than this row: the
    /// newer `observedAt` wins; without both times, or at the same time, the higher seq wins.
    /// An equal reading is not newer (a repeated message changes nothing).
    public func isOlder(thanSeq seq: Int, observedAt: Date?) -> Bool {
        if let mine = self.observedAt, let theirs = observedAt, mine != theirs { return theirs > mine }
        return seq > lastSeq
    }

    /// Whether `other` (the same game, read again) is newer than this row.
    public func isOlder(than other: Game) -> Bool {
        isOlder(thanSeq: other.lastSeq, observedAt: other.observedAt)
    }

    /// This game with a scoreboard update applied; nil when the update is for another game
    /// or not newer than this row (a stale or repeated delta).
    public func applying(_ update: ScoreUpdate) -> Game? {
        guard update.gameId == id, isOlder(thanSeq: update.latestSeq, observedAt: update.observedAt) else { return nil }
        return Game(
            id: id, league: league, scheduledAt: scheduledAt, status: update.status, coverage: coverage,
            home: home, away: away, score: update.score, period: update.period, elamTargetScore: elamTargetScore,
            clock: GameClock(remaining: update.clockRemaining, running: nil, asOf: update.observedAt),
            title: title, tournamentName: tournamentName, seasonYear: seasonYear,
            lastSeq: max(lastSeq, update.latestSeq), replay: update.replay ?? replay,
            observedAt: update.observedAt ?? observedAt
        )
    }
}
