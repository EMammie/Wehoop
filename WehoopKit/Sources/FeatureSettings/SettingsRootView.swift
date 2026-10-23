/// FeatureSettings: settings: version from the bundle, data attribution, acknowledgements, debug-only fixture toggle (S6).
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
nonisolated public enum SettingsRoute: Hashable, Sendable {
    case root
}

/// The feature's root screen (S0 placeholder).
public struct SettingsRootView: View {
    public init() {}

    public var body: some View {
        PlaceholderScreen(title: "Settings", message: "Version, attribution and acknowledgements.")
    }
}
