import Testing
@testable import FeatureOnboarding

struct OnboardingRouteTests {
    @Test("Routes are value-equal, so a navigation path can be restored from them")
    func routesAreValueEqual() {
        #expect(OnboardingRoute.root == OnboardingRoute.root)
        #expect(Set([OnboardingRoute.root, .root]).count == 1)
    }
}
