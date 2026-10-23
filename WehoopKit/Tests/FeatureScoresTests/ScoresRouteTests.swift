import Testing
@testable import FeatureScores

struct ScoresRouteTests {
    @Test("Routes are value-equal, so a navigation path can be restored from them")
    func routesAreValueEqual() {
        #expect(ScoresRoute.root == ScoresRoute.root)
        #expect(Set([ScoresRoute.root, .root]).count == 1)
    }
}
