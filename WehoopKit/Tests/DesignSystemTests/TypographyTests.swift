import CoreText
import Testing
@testable import DesignSystem

@MainActor
struct TypographyTests {
    @Test("Every bundled font registers, and CoreText resolves each family by name")
    func bundledFontsResolve() {
        #expect(WehoopFonts.register().isEmpty)
        let expectations = [
            FontFamily.displaySemiBold: "Barlow Condensed",
            FontFamily.displayBold: "Barlow Condensed",
            FontFamily.displayExtraBold: "Barlow Condensed",
            FontFamily.body: "DM Sans",
        ]
        for (name, family) in expectations {
            let font = CTFontCreateWithName(name as CFString, 17, nil)
            #expect(CTFontCopyFamilyName(font) as String == family, "\(name) fell back to another font")
        }
    }

    @Test("Registering twice is harmless")
    func registerIsIdempotent() {
        WehoopFonts.register()
        #expect(WehoopFonts.register().isEmpty)
    }

    @Test("Display styles use Barlow Condensed and text styles use DM Sans")
    func stylesUseBrandFamilies() {
        let display: Set<WehoopFont> = [.displayLarge, .displayMedium, .displaySmall, .score]
        for style in WehoopFont.allCases {
            let name = style.spec.name
            if display.contains(style) {
                #expect(name.hasPrefix("BarlowCondensed-"), "\(style)")
            } else {
                #expect(name == FontFamily.body, "\(style)")
            }
        }
    }
}
