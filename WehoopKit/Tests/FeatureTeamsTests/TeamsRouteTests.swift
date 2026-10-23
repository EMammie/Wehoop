import Testing
@testable import FeatureTeams

struct TeamsRouteTests {
    @Test("Routes are value-equal, so a navigation path can be restored from them")
    func routesAreValueEqual() {
        #expect(TeamsRoute.root == TeamsRoute.root)
        #expect(Set([TeamsRoute.root, .root]).count == 1)
    }
}
