import Testing
@testable import FeatureStandings

struct StandingsRouteTests {
    @Test("Routes are value-equal, so a navigation path can be restored from them")
    func routesAreValueEqual() {
        #expect(StandingsRoute.root == StandingsRoute.root)
        #expect(Set([StandingsRoute.root, .root]).count == 1)
    }
}
