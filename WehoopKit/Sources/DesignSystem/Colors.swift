import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// An sRGB color as a 24-bit hex value plus opacity. Pure data, so it can be tested
/// (contrast, exact brand values) without rendering anything.
nonisolated public struct RGB: Sendable, Hashable {
    public let hex: UInt32
    public let opacity: Double

    public init(_ hex: UInt32, opacity: Double = 1) {
        self.hex = hex & 0xFFFFFF
        self.opacity = opacity
    }

    public var red: Double { Double((hex >> 16) & 0xFF) / 255 }
    public var green: Double { Double((hex >> 8) & 0xFF) / 255 }
    public var blue: Double { Double(hex & 0xFF) / 255 }

    /// WCAG 2.x relative luminance (opacity ignored).
    public var relativeLuminance: Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// WCAG 2.x contrast ratio between two opaque colors (1...21).
    public func contrast(with other: RGB) -> Double {
        let (high, low) = relativeLuminance > other.relativeLuminance
            ? (relativeLuminance, other.relativeLuminance)
            : (other.relativeLuminance, relativeLuminance)
        return (high + 0.05) / (low + 0.05)
    }
}

/// A light and a dark value for one token.
nonisolated public struct ColorPair: Sendable, Hashable {
    public let light: RGB
    public let dark: RGB

    public init(light: RGB, dark: RGB) {
        self.light = light
        self.dark = dark
    }

    /// One value for both appearances.
    public init(_ both: RGB) {
        self.init(light: both, dark: both)
    }

    public func resolved(for scheme: ColorScheme) -> RGB {
        scheme == .dark ? dark : light
    }
}

/// The brand palette, exactly as `wehoop-landing/app/globals.css` defines it.
nonisolated public enum BrandPalette {
    public static let ink = RGB(0x29183B)
    public static let paper = RGB(0xFFF8ED)
    public static let peach = RGB(0xF7B497)
    public static let lime = RGB(0xD9ED79)
    public static let muted = RGB(0x685E70)
}

/// Semantic color tokens. Views use these, never raw hex.
nonisolated public enum WehoopColor {
    // Surfaces
    public static let background = ColorPair(light: BrandPalette.paper, dark: RGB(0x1A1024))
    public static let surface = ColorPair(light: RGB(0xFFFDF7), dark: BrandPalette.ink)
    public static let separator = ColorPair(
        light: RGB(0x29183B, opacity: 0.15),
        dark: RGB(0xFFF8ED, opacity: 0.15)
    )

    // Text
    public static let textPrimary = ColorPair(light: BrandPalette.ink, dark: BrandPalette.paper)
    public static let textSecondary = ColorPair(light: BrandPalette.muted, dark: RGB(0xC3B8CB))

    // Brand accents (fills; put `onAccent` text on them)
    public static let accent = ColorPair(BrandPalette.peach)
    public static let highlight = ColorPair(BrandPalette.lime)
    public static let onAccent = ColorPair(BrandPalette.ink)

    // Game status
    public static let statusLive = ColorPair(light: RGB(0xAC4B22), dark: BrandPalette.peach)
    public static let statusFinal = ColorPair(light: BrandPalette.muted, dark: RGB(0xC3B8CB))
    public static let statusDelayed = ColorPair(light: RGB(0x7A5200), dark: RGB(0xE8B450))
}

public extension Color {
    /// A color that follows the current light or dark appearance.
    nonisolated init(_ pair: ColorPair) {
        #if canImport(UIKit)
        // Built in a nonisolated context: UIKit may call the provider off the main thread.
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? pair.dark : pair.light)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(rgb: isDark ? pair.dark : pair.light)
        })
        #endif
    }

    /// One fixed color, the same in both appearances.
    nonisolated init(_ rgb: RGB) {
        self.init(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.opacity)
    }
}

#if canImport(UIKit)
nonisolated private extension UIColor {
    convenience init(rgb: RGB) {
        self.init(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: rgb.opacity)
    }
}
#elseif canImport(AppKit)
nonisolated private extension NSColor {
    convenience init(rgb: RGB) {
        self.init(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: rgb.opacity)
    }
}
#endif

public extension ShapeStyle where Self == Color {
    static var wehoopBackground: Color { Color(WehoopColor.background) }
    static var wehoopSurface: Color { Color(WehoopColor.surface) }
    static var wehoopSeparator: Color { Color(WehoopColor.separator) }
    static var wehoopTextPrimary: Color { Color(WehoopColor.textPrimary) }
    static var wehoopTextSecondary: Color { Color(WehoopColor.textSecondary) }
    static var wehoopAccent: Color { Color(WehoopColor.accent) }
    static var wehoopHighlight: Color { Color(WehoopColor.highlight) }
    static var wehoopOnAccent: Color { Color(WehoopColor.onAccent) }
    static var wehoopLive: Color { Color(WehoopColor.statusLive) }
    static var wehoopFinal: Color { Color(WehoopColor.statusFinal) }
    static var wehoopDelayed: Color { Color(WehoopColor.statusDelayed) }
}
