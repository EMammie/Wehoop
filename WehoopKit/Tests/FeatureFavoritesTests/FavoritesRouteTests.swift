import Testing
@testable import FeatureFavorites

struct FavoritesRouteTests {
    @Test("Routes are value-equal, so a navigation path can be restored from them")
    func routesAreValueEqual() {
        #expect(FavoritesRoute.root == FavoritesRoute.root)
        #expect(Set([FavoritesRoute.root, .root]).count == 1)
    }
}
