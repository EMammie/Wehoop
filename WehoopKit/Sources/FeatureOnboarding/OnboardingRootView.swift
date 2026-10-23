/// FeatureOnboarding: the onboarding flow ported from the old app, with `TimelineView` instead of a timer (S7).
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
nonisolated public enum OnboardingRoute: Hashable, Sendable {
    case root
}

/// The feature's root screen (S0 placeholder).
public struct OnboardingRootView: View {
    public init() {}

    public var body: some View {
        PlaceholderScreen(title: "Onboarding", message: "A quick tour of Wehoop.")
    }
}
