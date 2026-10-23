import Testing
@testable import FeaturePlayers

struct PlayersRouteTests {
    @Test("Routes are value-equal, so a navigation path can be restored from them")
    func routesAreValueEqual() {
        #expect(PlayersRoute.root == PlayersRoute.root)
        #expect(Set([PlayersRoute.root, .root]).count == 1)
    }
}
