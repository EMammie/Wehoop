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

/// Root navigation: one `NavigationStack` per tab. Typed paths arrive with each feature.
struct RootTabView: View {
    let tabs: [AppTab]
    @State private var selection: AppTab = .scores

    var body: some View {
        TabView(selection: $selection) {
            ForEach(tabs) { tab in
                Tab(value: tab) {
                    NavigationStack {
                        rootView(for: tab)
                            .toolbarBackground(.wehoopBackground, for: .navigationBar)
                    }
                } label: {
                    Label(String(localized: tab.title), systemImage: tab.systemImage)
                }
            }
        }
        .tint(.wehoopTint)
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

#Preview {
    RootTabView(tabs: AppTab.allCases)
}
