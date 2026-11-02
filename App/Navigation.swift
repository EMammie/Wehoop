import Domain
import Foundation
import Observation

/// Every destination the app can push (M5 plan decision 7: navigation is the app's; features
/// only emit actions). Routes carry ids only. Player, team and standings arrive with S6.
enum AppRoute: Hashable, Codable, Sendable {
    case game(Game.ID)
}

/// A `wehoop://` link: which tab to select and the path to show on it.
struct DeepLink: Equatable {
    let tab: AppTab
    let path: [AppRoute]

    /// `wehoop://game/<game id>` opens the game on the Scores tab. Anything else is nil.
    init?(url: URL) {
        guard url.scheme?.lowercased() == "wehoop", let host = url.host()?.lowercased() else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        switch (host, parts.count) {
        case ("game", 1) where !parts[0].isEmpty:
            tab = .scores
            path = [.game(Game.ID(parts[0]))]
        default:
            return nil
        }
    }
}

/// The app's navigation state: the selected tab and one path per tab.
@Observable
final class AppNavigation {
    var selectedTab: AppTab = .scores
    private(set) var paths: [AppTab: [AppRoute]] = [:]

    func path(for tab: AppTab) -> [AppRoute] { paths[tab] ?? [] }

    func setPath(_ path: [AppRoute], for tab: AppTab) { paths[tab] = path }

    /// Selecting the tab that is already selected pops it to its root.
    func select(_ tab: AppTab) {
        if tab == selectedTab { paths[tab] = [] }
        selectedTab = tab
    }

    func push(_ route: AppRoute) {
        paths[selectedTab, default: []].append(route)
    }

    /// Shows a link: its tab, with its path replacing whatever that tab showed.
    func open(_ link: DeepLink) {
        selectedTab = link.tab
        paths[link.tab] = link.path
    }

    /// Opens `url` if it is a Wehoop link; returns false (and changes nothing) otherwise.
    @discardableResult
    func open(url: URL) -> Bool {
        guard let link = DeepLink(url: url) else { return false }
        open(link)
        return true
    }
}
