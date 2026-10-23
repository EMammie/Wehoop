import Testing
@testable import FeatureLeaders

struct LeadersRouteTests {
    @Test("Routes are value-equal, so a navigation path can be restored from them")
    func routesAreValueEqual() {
        #expect(LeadersRoute.root == LeadersRoute.root)
        #expect(Set([LeadersRoute.root, .root]).count == 1)
    }
}
