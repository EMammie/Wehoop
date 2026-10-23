/// DesignSystem: the Wehoop brand as tokens and shared components.
///
/// - Colors from wehoop-landing `globals.css` (ink, paper, peach, lime, muted) with
///   dark-mode pairs, plus semantic status colors (live, final, delayed): `WehoopColor`.
/// - Type: Barlow Condensed for display, DM Sans for body, bundled under the OFL and
///   scaled with Dynamic Type: `WehoopFont`, registered once by `WehoopFonts.register()`.
/// - Spacing, radius and elevation: `Spacing`, `Radius`, `Elevation`.
/// - Later slices add team palettes keyed by `league:alias`, the Reduce Motion policy
///   and the components ported from the old app (EmptyState, ErrorState, StatBox, ...).
///
/// Depends on nothing but SwiftUI. Main-actor isolated by default; pure value types
/// that must be usable anywhere are marked `nonisolated`.
