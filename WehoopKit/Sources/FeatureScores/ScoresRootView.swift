/// FeatureScores: the Scores tab: week strip, league switch, and live, upcoming and final sections from `v_schedule`, with live score updates (S5).
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
nonisolated public enum ScoresRoute: Hashable, Sendable {
    case root
}

/// The feature's root screen (S0 placeholder).
public struct ScoresRootView: View {
    public init() {}

    public var body: some View {
        PlaceholderScreen(title: "Scores", message: "Live, upcoming and final games by date.")
    }
}
