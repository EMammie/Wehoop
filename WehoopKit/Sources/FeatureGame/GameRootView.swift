/// FeatureGame: the game screen: header with rolling score digits, clock, period and Elam target; play-by-play; team and player box score; coverage label, all driven by `GameSync` (S4).
///
/// Like every feature it will have a `Route` enum, a `Dependencies` struct of Domain
/// protocols, and `@Observable` view models with one `State` enum. It depends only on
/// Domain and DesignSystem: never on Data, never on another feature.
///
/// S0 placeholder.
import DesignSystem
import Domain
import SwiftUI

/// Destinations inside this feature's navigation stack.
nonisolated public enum GameRoute: Hashable, Sendable {
    case root
}

/// The feature's root screen (S0 placeholder).
public struct GameRootView: View {
    public init() {}

    public var body: some View {
        PlaceholderScreen(title: "Game", message: "Live clock, play-by-play and box scores.")
    }
}
