import SwiftUI

/// A full-screen "not built yet" state for features that are still skeletons.
/// Replaced by each feature's real screen in its slice; `EmptyState` arrives with S6.
public struct PlaceholderScreen: View {
    private let title: LocalizedStringResource
    private let message: LocalizedStringResource

    public init(title: LocalizedStringResource, message: LocalizedStringResource) {
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: Spacing.m) {
            Text(title)
                .wehoopFont(.displayMedium)
                .foregroundStyle(.wehoopTextPrimary)
            Text(message)
                .wehoopFont(.body)
                .foregroundStyle(.wehoopTextSecondary)
                .multilineTextAlignment(.center)
            Text("COMING IN M5")
                .wehoopFont(.eyebrow)
                .tracking(1.7)
                .foregroundStyle(.wehoopOnAccent)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.xs)
                .background(.wehoopHighlight, in: .capsule)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.wehoopBackground)
        .accessibilityElement(children: .combine)
    }
}
