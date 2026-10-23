/// FeaturePlayers: player search, the player profile and a player's career across leagues (S6).
///
/// Like every feature it will have a `Route` enum, a `Dependencies` struct of Domain
/// protocols, and `@Observable` view models with one `State` enum. It depends only on
/// Domain and DesignSystem: never on WehoopData, never on another feature.
///
/// S0 placeholder.
import DesignSystem
import Domain
import SwiftUI

/// Destinations inside this feature's navigation stack.
nonisolated public enum PlayersRoute: Hashable, Sendable {
    case root
}

/// The feature's root screen (S0 placeholder).
public struct PlayersRootView: View {
    public init() {}

    public var body: some View {
        PlaceholderScreen(title: "Players", message: "Search players and follow their careers.")
    }
}
