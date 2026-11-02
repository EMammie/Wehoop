import Domain
import Foundation
import Testing
@testable import Wehoop

struct NavigationTests {
    @Test("wehoop://game/<id> opens the game on the Scores tab")
    func gameLink() throws {
        let link = try #require(DeepLink(url: URL(string: "wehoop://game/2cca74a3-7639-4f3b-a27c-7591d0be1838")!))
        #expect(link.tab == .scores)
        #expect(link.path == [.game(Game.ID("2cca74a3-7639-4f3b-a27c-7591d0be1838"))])
    }

    @Test("Bad links open nothing and leave the navigation alone", arguments: [
        "https://example.com/game/1", "wehoop://game", "wehoop://game/a/b", "wehoop://player/1", "wehoop://",
    ])
    func badLinks(_ string: String) throws {
        let navigation = AppNavigation()
        navigation.select(.teams)
        let url = try #require(URL(string: string))
        #expect(navigation.open(url: url) == false)
        #expect(navigation.selectedTab == .teams)
        #expect(navigation.path(for: .scores).isEmpty)
    }

    @Test("Opening a link selects its tab and replaces that tab's path")
    func openReplacesPath() throws {
        let navigation = AppNavigation()
        navigation.push(.game(Game.ID("old")))
        navigation.select(.players)
        #expect(navigation.open(url: try #require(URL(string: "wehoop://game/new"))))
        #expect(navigation.selectedTab == .scores)
        #expect(navigation.path(for: .scores) == [.game(Game.ID("new"))])
    }

    @Test("Re-selecting the current tab pops it to its root; selecting another tab keeps both paths")
    func reselectPops() {
        let navigation = AppNavigation()
        navigation.push(.game(Game.ID("g1")))
        navigation.select(.teams)
        #expect(navigation.path(for: .scores).count == 1)
        navigation.select(.scores)
        #expect(navigation.path(for: .scores).count == 1)
        navigation.select(.scores)
        #expect(navigation.path(for: .scores).isEmpty)
    }

    @Test("Routes round-trip through Codable (state restoration in M6 needs nothing new)")
    func routesAreCodable() throws {
        let route = AppRoute.game(Game.ID("g1"))
        let decoded = try JSONDecoder().decode(AppRoute.self, from: JSONEncoder().encode(route))
        #expect(decoded == route)
    }
}
