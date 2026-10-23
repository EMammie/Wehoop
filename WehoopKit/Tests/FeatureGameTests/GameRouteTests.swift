import Testing
@testable import FeatureGame

struct GameRouteTests {
    @Test("Routes are value-equal, so a navigation path can be restored from them")
    func routesAreValueEqual() {
        #expect(GameRoute.root == GameRoute.root)
        #expect(Set([GameRoute.root, .root]).count == 1)
    }
}
