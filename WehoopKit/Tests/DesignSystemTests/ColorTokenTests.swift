import SwiftUI
import Testing
@testable import DesignSystem

struct ColorTokenTests {
    @Test("Brand palette matches wehoop-landing globals.css")
    func brandPaletteMatchesLanding() {
        #expect(BrandPalette.ink.hex == 0x29183B)
        #expect(BrandPalette.paper.hex == 0xFFF8ED)
        #expect(BrandPalette.peach.hex == 0xF7B497)
        #expect(BrandPalette.lime.hex == 0xD9ED79)
        #expect(BrandPalette.muted.hex == 0x685E70)
    }

    nonisolated static let textTokens: [(String, ColorPair)] = [
        ("textPrimary", WehoopColor.textPrimary),
        ("textSecondary", WehoopColor.textSecondary),
        ("tint", WehoopColor.tint),
        ("statusLive", WehoopColor.statusLive),
        ("statusFinal", WehoopColor.statusFinal),
        ("statusDelayed", WehoopColor.statusDelayed),
    ]

    @Test("Text and status colors meet WCAG AA (4.5:1) on every surface in both appearances",
          arguments: textTokens, [ColorScheme.light, .dark])
    func textContrast(token: (String, ColorPair), scheme: ColorScheme) {
        for surface in [WehoopColor.background, WehoopColor.surface] {
            let ratio = token.1.resolved(for: scheme).contrast(with: surface.resolved(for: scheme))
            #expect(ratio >= 4.5, "\(token.0) in \(scheme) is \(ratio):1")
        }
    }

    @Test("Text on the peach and lime accents meets WCAG AA")
    func onAccentContrast() {
        for fill in [WehoopColor.accent, WehoopColor.highlight] {
            for scheme in [ColorScheme.light, .dark] {
                #expect(WehoopColor.onAccent.resolved(for: scheme).contrast(with: fill.resolved(for: scheme)) >= 4.5)
            }
        }
    }

    @Test("Background, surface and primary text change between light and dark")
    func darkModeHasDistinctPairs() {
        for pair in [WehoopColor.background, WehoopColor.surface, WehoopColor.textPrimary] {
            #expect(pair.light != pair.dark)
        }
    }

    @Test("Contrast of black on white is 21:1")
    func contrastFormula() {
        #expect(abs(RGB(0x000000).contrast(with: RGB(0xFFFFFF)) - 21) < 0.001)
    }
}
