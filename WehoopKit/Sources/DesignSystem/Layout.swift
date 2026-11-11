import SwiftUI

/// Spacing scale in points (4-pt grid).
nonisolated public enum Spacing {
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

/// Minimum sizes for things people tap.
nonisolated public enum TapTarget {
    /// The smallest side of a tappable control (above the 44 pt platform minimum, for the date strip's cells).
    public static let minimum: CGFloat = 48
}

/// Corner radii. `pill` matches the landing page's rounded buttons and chips.
nonisolated public enum Radius {
    public static let small: CGFloat = 4
    public static let medium: CGFloat = 8
    public static let large: CGFloat = 12
    public static let pill: CGFloat = 30
}

/// A shadow level. The brand is flat: cards get a faint ink shadow, nothing more.
nonisolated public struct Elevation: Sendable, Hashable {
    public let color: RGB
    public let radius: CGFloat
    public let y: CGFloat

    public static let flat = Elevation(color: RGB(0x29183B, opacity: 0), radius: 0, y: 0)
    public static let card = Elevation(color: RGB(0x29183B, opacity: 0.08), radius: 12, y: 4)
    public static let raised = Elevation(color: RGB(0x29183B, opacity: 0.14), radius: 18, y: 8)
}

public extension View {
    /// Applies an elevation token as a shadow.
    func elevation(_ level: Elevation) -> some View {
        shadow(color: Color(level.color), radius: level.radius, x: 0, y: level.y)
    }
}
