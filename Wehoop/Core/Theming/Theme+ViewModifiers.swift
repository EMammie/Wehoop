//
//  Theme+ViewModifiers.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

// MARK: - View Extensions for Theme

extension View {
    /// Apply theme colors to a view
    func themed(_ color: ThemeColor) -> some View {
        self.foregroundColor(color.value)
    }
    
    /// Apply theme typography to text
    func themeFont(_ fontStyle: ThemeFontStyle) -> some View {
        self.font(fontStyle.font)
    }
}

// MARK: - Theme Color Helper

enum ThemeColor {
    case primary
    case secondary
    case accent
    case background
    case foreground
    
    func value(from theme: Theme) -> Color {
        switch self {
        case .primary:
            return theme.colorScheme.primary
        case .secondary:
            return theme.colorScheme.secondary
        case .accent:
            return theme.colorScheme.accent
        case .background:
            return theme.colorScheme.background
        case .foreground:
            return theme.colorScheme.foreground
        }
    }
}

extension ThemeColor {
    var value: Color {
        // This will be resolved via environment in actual usage
        // For now, return a default
        switch self {
        case .primary:
            return Theme.wehoop.colorScheme.primary
        case .secondary:
            return Theme.wehoop.colorScheme.secondary
        case .accent:
            return Theme.wehoop.colorScheme.accent
        case .background:
            return Theme.wehoop.colorScheme.background
        case .foreground:
            return Theme.wehoop.colorScheme.foreground
        }
    }
}

// MARK: - Theme Font Style Helper

enum ThemeFontStyle {
    case title
    case headline
    case body
    case caption
    
    var font: Font {
        switch self {
        case .title:
            return Theme.wehoop.typography.title
        case .headline:
            return Theme.wehoop.typography.headline
        case .body:
            return Theme.wehoop.typography.body
        case .caption:
            return Theme.wehoop.typography.caption
        }
    }
}

// MARK: - Environment-based Theme Access

extension View {
    /// Get theme from environment
    func withTheme(_ action: @escaping (Theme) -> some View) -> some View {
        EnvironmentReader { theme in
            action(theme)
        }
    }
}

private struct EnvironmentReader<Content: View>: View {
    @Environment(\.theme) private var theme
    let content: (Theme) -> Content
    
    var body: some View {
        content(theme)
    }
}
