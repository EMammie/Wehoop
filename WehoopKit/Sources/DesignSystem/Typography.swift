import CoreText
import Foundation
import SwiftUI

/// Registers the bundled fonts with CoreText for this process.
///
/// Call once at launch (the app does it in `WehoopApp.init`). If registration fails,
/// `Font.custom` falls back to the system font, so text still renders.
public enum WehoopFonts {
    /// The font files shipped in this module's bundle (`Resources/Fonts`, OFL).
    nonisolated public static let fileNames = [
        "BarlowCondensed-SemiBold", "BarlowCondensed-Bold", "BarlowCondensed-ExtraBold",
        "DMSans-Variable",
    ]

    private static var failures: [String]?

    /// Registers every bundled font. Idempotent: later calls return the first result.
    /// Returns the file names that failed to register (empty on success).
    @discardableResult
    public static func register() -> [String] {
        if let failures { return failures }
        var failed: [String] = []
        for name in fileNames {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") else {
                failed.append(name)
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                let code = error.map { CFErrorGetCode($0.takeRetainedValue()) }
                if code != CTFontManagerError.alreadyRegistered.rawValue { failed.append(name) }
            }
        }
        failures = failed
        return failed
    }
}

/// The font families, by the names CoreText resolves after registration.
nonisolated public enum FontFamily {
    /// Barlow Condensed ships as static weights, addressed by PostScript name.
    public static let displaySemiBold = "BarlowCondensed-SemiBold"
    public static let displayBold = "BarlowCondensed-Bold"
    public static let displayExtraBold = "BarlowCondensed-ExtraBold"
    /// DM Sans ships as one variable font; `.weight(_:)` picks the instance.
    public static let body = "DM Sans"
}

/// Text styles. Each scales with Dynamic Type relative to a system text style.
public enum WehoopFont: CaseIterable, Sendable {
    case displayLarge, displayMedium, displaySmall, score
    case headline, body, callout, subheadline, footnote, caption, eyebrow

    nonisolated public var spec: Spec {
        switch self {
        case .displayLarge: Spec(FontFamily.displayExtraBold, 48, .largeTitle)
        case .displayMedium: Spec(FontFamily.displayBold, 34, .title)
        case .displaySmall: Spec(FontFamily.displayBold, 24, .title2)
        case .score: Spec(FontFamily.displayExtraBold, 40, .largeTitle)
        case .headline: Spec(FontFamily.body, 17, .headline, weight: .semibold)
        case .body: Spec(FontFamily.body, 17, .body)
        case .callout: Spec(FontFamily.body, 16, .callout)
        case .subheadline: Spec(FontFamily.body, 15, .subheadline)
        case .footnote: Spec(FontFamily.body, 13, .footnote)
        case .caption: Spec(FontFamily.body, 12, .caption)
        case .eyebrow: Spec(FontFamily.body, 11, .caption2, weight: .bold)
        }
    }

    public var font: Font {
        let spec = spec
        let base = Font.custom(spec.name, size: spec.size, relativeTo: spec.relativeTo)
        return spec.weight.map { base.weight($0) } ?? base
    }

    /// The pure description of a text style.
    nonisolated public struct Spec: Sendable, Equatable {
        public let name: String
        public let size: CGFloat
        public let relativeTo: Font.TextStyle
        public let weight: Font.Weight?

        init(_ name: String, _ size: CGFloat, _ relativeTo: Font.TextStyle, weight: Font.Weight? = nil) {
            self.name = name
            self.size = size
            self.relativeTo = relativeTo
            self.weight = weight
        }
    }
}

public extension View {
    /// Applies a Wehoop text style.
    func wehoopFont(_ style: WehoopFont) -> some View {
        font(style.font)
    }
}
