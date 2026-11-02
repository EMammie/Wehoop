import Domain
import Testing
@testable import Wehoop

struct CompositionRootTests {
    private let configured: [String: Any] = [
        "WehoopAPIURL": "http://127.0.0.1:3000",
        "WehoopSupabaseURL": "http://127.0.0.1:54321",
        "WehoopSupabaseAnonKey": "not-a-real-key",
    ]

    @Test("Without the fixtures launch argument the app uses live data")
    func defaultsToLiveData() {
        let root = CompositionRoot(arguments: ["Wehoop"], infoDictionary: configured)
        #expect(root.dataMode == .live)
        guard case .live = root.backend else { Issue.record("expected the live backend"); return }
        #expect(root.gameDependencies != nil)
    }

    @Test("-WehoopFixtures switches the app to fixture data")
    func fixturesArgumentSelectsFixtures() {
        let root = CompositionRoot(arguments: ["Wehoop", "-WehoopFixtures"], infoDictionary: [:])
        #expect(root.dataMode == .fixtures)
        guard case .fixtures = root.backend else { Issue.record("expected the fixture backend"); return }
        #expect(root.gameDependencies != nil)
    }

    @Test("Live mode without an anon key is 'not configured', naming the missing setting, instead of crashing")
    func missingKeyIsNotConfigured() {
        var info = configured
        info["WehoopSupabaseAnonKey"] = ""
        let root = CompositionRoot(arguments: ["Wehoop"], infoDictionary: info)
        guard case .unconfigured(let reason) = root.backend else { Issue.record("expected unconfigured"); return }
        #expect(reason.contains("WEHOOP_SUPABASE_ANON_KEY"))
        #expect(root.gameDependencies == nil)
    }

    @Test("Tabs appear as Scores, Leaders, Players, Teams, Favorites")
    func tabOrder() {
        #expect(CompositionRoot(arguments: [], infoDictionary: configured).tabs == [.scores, .leaders, .players, .teams, .favorites])
    }

    @Test("-WehoopOpenURL <link> is opened at launch; without a link after it, nothing is")
    func launchURL() {
        let link = "wehoop://game/g1"
        #expect(CompositionRoot(arguments: ["Wehoop", "-WehoopOpenURL", link], infoDictionary: [:]).launchURL?.absoluteString == link)
        #expect(CompositionRoot(arguments: ["Wehoop", "-WehoopOpenURL"], infoDictionary: [:]).launchURL == nil)
    }

    @Test("Fixture mode knows every golden game by its id")
    func fixtureGames() {
        #expect(FixtureBackend.goldenIds().count == 4)
    }
}
