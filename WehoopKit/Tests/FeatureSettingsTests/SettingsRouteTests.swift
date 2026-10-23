import Testing
@testable import FeatureSettings

struct SettingsRouteTests {
    @Test("Routes are value-equal, so a navigation path can be restored from them")
    func routesAreValueEqual() {
        #expect(SettingsRoute.root == SettingsRoute.root)
        #expect(Set([SettingsRoute.root, .root]).count == 1)
    }
}
