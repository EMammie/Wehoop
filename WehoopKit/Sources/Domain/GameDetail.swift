import Foundation

/// Which side of a game a team, play or line belongs to.
public enum TeamSide: Sendable, Hashable, CaseIterable {
    case home, away
}

/// One period of the line score.
public struct PeriodLine: Sendable, Hashable {
    public let period: GamePeriod
    public let score: Score

    public init(period: GamePeriod, score: Score) {
        self.period = period
        self.score = score
    }
}

/// One play of the play-by-play, as the game screen shows it. `id` is the provider's event
/// id: a corrected play keeps its id and replaces the row in place.
public struct Play: Sendable, Hashable, Identifiable {
    public enum Kind: Sendable, Hashable {
        case tipOff
        case shot(made: Bool, points: Int)
        case freeThrow(made: Bool)
        case rebound
        case turnover
        case foul
        case timeout
        case substitution
        case periodStart
        case periodEnd
        case gameStatus
        case elamTarget(Int)
        case awardedPoint(Int)
        case review
        /// A play this build has no presentation for; its description still shows.
        case other
    }

    public let id: String
    public let period: GamePeriod
    /// The game clock as the provider printed it; nil for plays without one (Elam ending).
    public let clock: String?
    public let kind: Kind
    public let side: TeamSide?
    public let playerName: String?
    public let description: String?
    /// The score after this play.
    public let score: Score

    public init(
        id: String, period: GamePeriod, clock: String?, kind: Kind, side: TeamSide?,
        playerName: String?, description: String?, score: Score
    ) {
        self.id = id
        self.period = period
        self.clock = clock
        self.kind = kind
        self.side = side
        self.playerName = playerName
        self.description = description
        self.score = score
    }

    /// True for a made shot, a made free throw or an awarded point.
    public var isScoring: Bool {
        switch kind {
        case .shot(let made, _), .freeThrow(let made): made
        case .awardedPoint: true
        default: false
        }
    }
}

/// Box score numbers; nil is "not reported", which the screen shows as a dash, never 0.
public struct BoxStats: Sendable, Hashable {
    public var minutes: String?
    public var points: Int?
    public var fieldGoalsMade: Int?
    public var fieldGoalsAttempted: Int?
    public var threesMade: Int?
    public var threesAttempted: Int?
    public var freeThrowsMade: Int?
    public var freeThrowsAttempted: Int?
    public var offensiveRebounds: Int?
    public var defensiveRebounds: Int?
    public var rebounds: Int?
    public var assists: Int?
    public var steals: Int?
    public var blocks: Int?
    public var turnovers: Int?
    public var fouls: Int?
    public var plusMinus: Int?

    public init() {}
}

/// A team's line of the box score.
public struct TeamBoxLine: Sendable, Hashable {
    public let side: TeamSide
    public let stats: BoxStats

    public init(side: TeamSide, stats: BoxStats) {
        self.side = side
        self.stats = stats
    }
}

/// A player's line of the box score, keyed by the provider's player id (the row the backend
/// stores; two provider ids of one person stay two lines).
public struct PlayerBoxLine: Sendable, Hashable, Identifiable {
    public let id: String
    public let side: TeamSide?
    public let name: String
    public let jersey: String?
    public let position: String?
    public let starter: Bool
    public let played: Bool?
    public let notPlayingReason: String?
    public let stats: BoxStats

    public init(
        id: String, side: TeamSide?, name: String, jersey: String?, position: String?, starter: Bool,
        played: Bool?, notPlayingReason: String?, stats: BoxStats
    ) {
        self.id = id
        self.side = side
        self.name = name
        self.jersey = jersey
        self.position = position
        self.starter = starter
        self.played = played
        self.notPlayingReason = notPlayingReason
        self.stats = stats
    }
}

/// Everything below the game screen's header: line score, plays and box score.
public struct GameDetail: Sendable, Hashable {
    public let periods: [PeriodLine]
    /// Current plays in the backend's order (period, provider sequence, …).
    public let plays: [Play]
    public let teamLines: [TeamBoxLine]
    public let playerLines: [PlayerBoxLine]

    public init(periods: [PeriodLine], plays: [Play], teamLines: [TeamBoxLine], playerLines: [PlayerBoxLine]) {
        self.periods = periods
        self.plays = plays
        self.teamLines = teamLines
        self.playerLines = playerLines
    }

    public static let empty = GameDetail(periods: [], plays: [], teamLines: [], playerLines: [])
}
