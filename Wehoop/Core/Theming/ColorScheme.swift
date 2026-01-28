//
//  ColorScheme.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// App color scheme definition
struct AppColorScheme {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let foreground: Color
    
    /// Create a team-specific color scheme
    static func teamColors(primary: Color, secondary: Color, accent: Color) -> AppColorScheme {
        AppColorScheme(
            primary: primary,
            secondary: secondary,
            accent: accent,
            background: Color(.systemBackground),
            foreground: Color(.label)
        )
    }
}
