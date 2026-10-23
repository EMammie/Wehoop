//
//  Theme.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// App theme configuration
struct Theme {
    let colorScheme: AppColorScheme
    let typography: Typography
}

/// Default Wehoop brand theme
extension Theme {
    static let wehoop = Theme(
        colorScheme: AppColorScheme(
            primary: Color(red: 0.2, green: 0.1, blue: 0.4), // Deep purple/brand color
            secondary: Color(red: 0.4, green: 0.3, blue: 0.6), // Lighter purple
            accent: Color(red: 1.0, green: 0.6, blue: 0.2), // Orange accent
            background: Color(.systemBackground),
            foreground: Color(.label)
        ),
        typography: Typography(
            title: .system(size: 34, weight: .bold, design: .default),
            headline: .system(size: 22, weight: .semibold, design: .default),
            body: .system(size: 17, weight: .regular, design: .default),
            caption: .system(size: 12, weight: .regular, design: .default)
        )
    )
}
