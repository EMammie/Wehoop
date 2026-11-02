import Foundation

public enum GameTag {}
public enum TeamTag {}
public enum PlayerTag {}

/// One game as the schedule lists it (`v_schedule`).
public struct Game: Sendable, Hashable, Identifiable {
    public typealias ID = Identifier<GameTag>

    /// One side of a game. A team the backend has not resolved yet has no id.
    public struct Side: Sendable, Hashable {
        public let teamId: Team.ID?
        public let name: String?
        public let market: String?
        public let alias: String?

        public init(teamId: Team.ID?, name: String?, market: String?, alias: String?) {
            self.teamId = teamId
            self.name = name
            self.market = market
            self.alias = alias
        }
    }

    public let id: ID
    public let league: League.Code
    public let scheduledAt: Date
    public let status: GameStatus
    public let coverage: Coverage
    public let home: Side
    public let away: Side
    public let score: Score
    public let period: GamePeriod?
    public let elamTargetScore: Int?
    public let clock: GameClock
    /// A title the schedule gives the game (a tournament round), if any.
    public let title: String?
    public let tournamentName: String?
    public let seasonYear: Int?
    /// The highest change seq the backend had for this game when the row was read.
    public let lastSeq: Int

    public init(
        id: ID, league: League.Code, scheduledAt: Date, status: GameStatus, coverage: Coverage,
        home: Side, away: Side, score: Score, period: GamePeriod?, elamTargetScore: Int?,
        clock: GameClock, title: String?, tournamentName: String?, seasonYear: Int?, lastSeq: Int
    ) {
        self.id = id
        self.league = league
        self.scheduledAt = scheduledAt
        self.status = status
        self.coverage = coverage
        self.home = home
        self.away = away
        self.score = score
        self.period = period
        self.elamTargetScore = elamTargetScore
        self.clock = clock
        self.title = title
        self.tournamentName = tournamentName
        self.seasonYear = seasonYear
        self.lastSeq = lastSeq
    }
}

/// Namespace for team ids until the Team entity arrives with the team screens (S6).
public enum Team {
    public typealias ID = Identifier<TeamTag>
}
