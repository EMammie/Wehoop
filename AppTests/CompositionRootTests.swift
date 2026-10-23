import Testing
@testable import Wehoop

struct CompositionRootTests {
    @Test("Without the fixtures launch argument the app uses live data")
    func defaultsToLiveData() {
        #expect(CompositionRoot(arguments: ["Wehoop"]).dataMode == .live)
    }

    @Test("-WehoopFixtures switches the app to fixture data")
    func fixturesArgumentSelectsFixtures() {
        #expect(CompositionRoot(arguments: ["Wehoop", "-WehoopFixtures"]).dataMode == .fixtures)
    }

    @Test("Tabs appear as Scores, Leaders, Players, Teams, Favorites")
    func tabOrder() {
        #expect(CompositionRoot(arguments: []).tabs == [.scores, .leaders, .players, .teams, .favorites])
    }
}
