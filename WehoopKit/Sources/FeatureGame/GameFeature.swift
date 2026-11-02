/// FeatureGame: the game screen. A header with rolling score digits, the clock, period and
/// Elam target; the line score; play-by-play; team and player box score; and a coverage
/// label, all from one followed live game (`LiveGameSource`, the app's `GameSyncRegistry`).
///
/// It depends only on Domain and DesignSystem. Navigation is the app's (M5 plan decision 7):
/// this feature declares no route and pushes nothing.
import Domain

/// What the game screen reads.
public struct GameDependencies: Sendable {
    /// The live game: snapshot, then every change and clock pulse, then the final state.
    public let liveGames: any LiveGameSource
    /// The schedule row, for team names (the live state carries provider ids only).
    public let schedule: any ScheduleRepository

    public init(liveGames: any LiveGameSource, schedule: any ScheduleRepository) {
        self.liveGames = liveGames
        self.schedule = schedule
    }
}
