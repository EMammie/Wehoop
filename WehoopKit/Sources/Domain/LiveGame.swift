import Foundation

/// A game while it is followed live: what the game screen header shows. Built by
/// WehoopData from LiveEngine's folded state, with the line score, plays and box score.
public struct LiveGame: Sendable, Hashable, Identifiable {
    public let id: Game.ID
    public let league: League.Code
    public let status: GameStatus
    public let coverage: Coverage
    public let score: Score
    public let period: GamePeriod?
    public let elamTargetScore: Int?
    /// `asOf` is already on this device's clock (corrected by the server offset), so a
    /// view counts down from it with `Date.now` alone.
    public let clock: GameClock
    /// The last change seq folded into this value.
    public let seq: Int
    /// Set when the demo environment replays a recording; nil for a real game. It comes
    /// from the snapshot, so it survives reconnects and re-snapshots.
    public let replay: ReplayKind?
    public let detail: GameDetail

    public init(
        id: Game.ID, league: League.Code, status: GameStatus, coverage: Coverage, score: Score,
        period: GamePeriod?, elamTargetScore: Int?, clock: GameClock, seq: Int, replay: ReplayKind?,
        detail: GameDetail = .empty
    ) {
        self.id = id
        self.league = league
        self.status = status
        self.coverage = coverage
        self.score = score
        self.period = period
        self.elamTargetScore = elamTargetScore
        self.clock = clock
        self.seq = seq
        self.replay = replay
        self.detail = detail
    }
}

/// One published state of a live game.
public struct LiveGameUpdate: Sendable, Hashable {
    public enum Cause: Sendable, Hashable {
        /// The first state, or a fresh snapshot.
        case snapshot
        /// A durable change (score, status, play, stats).
        case change
        /// Only the clock moved.
        case clock
        /// The game closed and the final snapshot replaced the folded state.
        case final
    }

    public let game: LiveGame
    public let cause: Cause

    public init(game: LiveGame, cause: Cause) {
        self.game = game
        self.cause = cause
    }
}
