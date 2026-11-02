import Foundation

/// A game's status, the backend's full set (`games.status`). A status this build does
/// not know is kept as `.unknown` and shown as such, never mapped to another status.
public enum GameStatus: Sendable, Hashable {
    case scheduled, created, timeTBD, ifNecessary
    case inProgress, halftime, delayed
    case complete, closed, cancelled, postponed, unnecessary
    case unknown(String)

    /// Where the game is in its life (backend plan §4's phase).
    public enum Phase: Sendable, Hashable {
        case pre, live, post
    }

    /// Nil for a status this build does not know.
    public var phase: Phase? {
        switch self {
        case .scheduled, .created, .timeTBD, .ifNecessary: .pre
        case .inProgress, .halftime, .delayed: .live
        case .complete, .closed, .cancelled, .postponed, .unnecessary: .post
        case .unknown: nil
        }
    }

    /// `closed`: statistics validated and final. `complete` is over but not yet final.
    public var isFinal: Bool { self == .closed }
}

/// How much of a game the provider covers.
public enum Coverage: Sendable, Hashable {
    /// Play-by-play, box score and clock.
    case full
    /// Score, status and period; player statistics only when the game is final.
    case extendedBoxscore
    /// A box score without play-by-play.
    case boxscore
    case unknown(String)
}

/// The kind of a period.
public enum PeriodKind: Sendable, Hashable {
    case quarter, half, overtime
    /// Unrivaled's untimed ending to a target score.
    case elam
    case unknown(String)
}

/// The period a game is in.
public struct GamePeriod: Sendable, Hashable {
    public let number: Int
    public let kind: PeriodKind?
    /// Order across all periods of the game (quarters, then overtimes or Elam).
    public let sequence: Int?

    public init(number: Int, kind: PeriodKind?, sequence: Int?) {
        self.number = number
        self.kind = kind
        self.sequence = sequence
    }
}

public struct Score: Sendable, Hashable {
    public let home: Int
    public let away: Int
    public init(home: Int, away: Int) {
        self.home = home
        self.away = away
    }
}

/// The game clock as last observed. `running` is `true` (counting down), `false` (stopped)
/// or `nil` (unknown: the display freezes; the app never guesses that a clock runs).
public struct GameClock: Sendable, Hashable {
    /// Seconds left in the period at `asOf`; nil for a period without a clock (Elam).
    public let remaining: Double?
    public let running: Bool?
    public let asOf: Date?

    public init(remaining: Double?, running: Bool?, asOf: Date?) {
        self.remaining = remaining
        self.running = running
        self.asOf = asOf
    }

    /// True when the display moves with time: the backend says the clock runs (never a guess).
    public var isCounting: Bool { running == true && remaining != nil && asOf != nil }

    /// Seconds left at device time `now`; frozen at `remaining` unless counting; nil without a clock.
    public func remaining(at now: Date) -> Double? {
        guard let remaining else { return nil }
        guard isCounting, let asOf else { return remaining }
        return max(0, remaining - max(0, now.timeIntervalSince(asOf)))
    }
}
