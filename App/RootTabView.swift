import DesignSystem
import FeatureFavorites
import FeatureLeaders
import FeaturePlayers
import FeatureScores
import FeatureTeams
import SwiftUI

/// The app's top-level tabs, in display order.
enum AppTab: String, CaseIterable, Identifiable {
    case scores, leaders, players, teams, favorites

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .scores: "Scores"
        case .leaders: "Leaders"
        case .players: "Players"
        case .teams: "Teams"
        case .favorites: "Favorites"
        }
    }

    var systemImage: String {
        switch self {
        case .scores: "sportscourt"
        case .leaders: "chart.bar"
        case .players: "person.2"
        case .teams: "person.3"
        case .favorites: "star"
        }
    }
}

/// Root navigation: one `NavigationStack` per tab, its path owned by `AppNavigation`.
struct RootTabView: View {
    let root: CompositionRoot
    @Bindable var navigation: AppNavigation
    var isOnline = true

    var body: some View {
        TabView(selection: Binding(get: { navigation.selectedTab }, set: { navigation.select($0) })) {
            ForEach(root.tabs) { tab in
                Tab(value: tab) {
                    NavigationStack(path: Binding(get: { navigation.path(for: tab) }, set: { navigation.setPath($0, for: tab) })) {
                        rootView(for: tab)
                            .toolbarBackground(.wehoopBackground, for: .navigationBar)
                            .navigationDestination(for: AppRoute.self) { root.destination(for: $0) }
                    }
                } label: {
                    Label(String(localized: tab.title), systemImage: tab.systemImage)
                }
            }
        }
        .tint(.wehoopTint)
        .safeAreaInset(edge: .top, spacing: 0) {
            if !isOnline { OfflineBanner() }
        }
    }

    @ViewBuilder
    private func rootView(for tab: AppTab) -> some View {
        switch tab {
        case .scores: ScoresRootView()
        case .leaders: LeadersRootView()
        case .players: PlayersRootView()
        case .teams: TeamsRootView()
        case .favorites: FavoritesRootView()
        }
    }
}

/// Shown while the device has no network; followed games catch up when it returns.
struct OfflineBanner: View {
    var body: some View {
        Label(String(localized: "Offline: showing the last update"), systemImage: "wifi.slash")
            .wehoopFont(.caption)
            .foregroundStyle(Color.wehoopOnAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .background(Color.wehoopAccent)
    }
}

#Preview {
    RootTabView(root: CompositionRoot(arguments: [CompositionRoot.fixturesArgument]), navigation: AppNavigation())
}
