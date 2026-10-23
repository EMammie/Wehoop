import DesignSystem
import Testing
import UIKit

struct BundledFontTests {
    @Test("The app bundle carries the brand fonts and UIKit resolves them by name")
    func brandFontsResolveInTheApp() {
        #expect(WehoopFonts.register().isEmpty)
        #expect(UIFont(name: FontFamily.displayExtraBold, size: 17)?.familyName == "Barlow Condensed")
        #expect(UIFont(name: FontFamily.body, size: 17)?.familyName == "DM Sans")
    }
}
