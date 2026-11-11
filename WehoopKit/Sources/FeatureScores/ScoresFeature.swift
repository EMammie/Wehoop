/// FeatureScores: the Scores tab. A week strip (today selected), the league switch (leagues
/// are data: the `leagues` rows, never a code named here), and live, upcoming and final
/// sections for the selected league and day from `v_schedule`, kept current by the
/// league's scoreboard channel (`league:{code}:scores`).
///
/// It depends only on Domain and DesignSystem. Navigation is the app's (M5 plan decision 7):
/// a tapped game is an action, never a route of this feature.
import Domain
import Foundation

/// What the Scores tab reads.
public struct ScoresDependencies: Sendable {
    /// The leagues to switch between, in display order.
    public let leagues: any LeagueRepository
    /// `v_schedule` by league and day.
    public let schedule: any ScheduleRepository
    /// The league's scoreboard updates.
    public let liveScores: any LiveScoresSource
    /// Days are this calendar's days (the user's time zone).
    public let calendar: Calendar
    public let now: @Sendable () -> Date

    public init(
        leagues: any LeagueRepository, schedule: any ScheduleRepository, liveScores: any LiveScoresSource,
        calendar: Calendar = .current, now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.leagues = leagues
        self.schedule = schedule
        self.liveScores = liveScores
        self.calendar = calendar
        self.now = now
    }
}

/// The hops out of the Scores tab; the app turns them into routes.
public struct ScoresActions {
    public var didSelectGame: @MainActor (Game.ID) -> Void

    public init(didSelectGame: @escaping @MainActor (Game.ID) -> Void = { _ in }) {
        self.didSelectGame = didSelectGame
    }
}
