//
//  TeamThemeProvider.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Protocol for team theme provider
protocol TeamThemeProviding {
    func theme(for teamId: String) -> Theme
    func theme(for team: Team) -> Theme
    func clearCache()
}

/// Provides team-specific theming
class TeamThemeProvider: TeamThemeProviding {
    private var themes: [String: Theme] = [:]
    
    /// Get theme for a specific team
    func theme(for teamId: String) -> Theme {
        if let existingTheme = themes[teamId] {
            return existingTheme
        }
        
        // Create team-specific theme based on team ID
        let teamTheme = createTheme(for: teamId)
        themes[teamId] = teamTheme
        return teamTheme
    }
    
    /// Get theme for a Team model
    func theme(for team: Team) -> Theme {
        return theme(for: team.id)
    }
    
    /// Create a theme for a specific team ID
    private func createTheme(for teamId: String) -> Theme {
        let colorScheme: AppColorScheme
        let typography = Theme.wehoop.typography // Use brand typography for all teams
        
        switch teamId {
        case "team-1": // Mist BC
            colorScheme = AppColorScheme.teamColors(
                primary: Color(red: 0.3, green: 0.4, blue: 0.6), // Misty blue-gray
                secondary: Color(red: 0.5, green: 0.6, blue: 0.8), // Lighter mist
                accent: Color(red: 0.9, green: 0.9, blue: 0.95) // Light accent
            )
            
        case "team-2": // Lunar Owls BC
            colorScheme = AppColorScheme.teamColors(
                primary: Color(red: 0.15, green: 0.15, blue: 0.25), // Deep night blue
                secondary: Color(red: 0.3, green: 0.3, blue: 0.4), // Moonlit gray
                accent: Color(red: 0.9, green: 0.85, blue: 0.7) // Owl gold
            )
            
        case "team-3": // Rose BC
            colorScheme = AppColorScheme.teamColors(
                primary: Color(red: 0.8, green: 0.2, blue: 0.3), // Rose red
                secondary: Color(red: 0.9, green: 0.4, blue: 0.5), // Lighter rose
                accent: Color(red: 1.0, green: 0.7, blue: 0.8) // Pink accent
            )
            
        case "team-4": // Vinyl BC
            colorScheme = AppColorScheme.teamColors(
                primary: Color(red: 0.1, green: 0.1, blue: 0.1), // Deep black
                secondary: Color(red: 0.3, green: 0.3, blue: 0.3), // Charcoal
                accent: Color(red: 0.9, green: 0.9, blue: 0.9) // Silver accent
            )
            
        case "team-5": // Phantom BC
            colorScheme = AppColorScheme.teamColors(
                primary: Color(red: 0.2, green: 0.15, blue: 0.3), // Phantom purple
                secondary: Color(red: 0.4, green: 0.3, blue: 0.5), // Lighter purple
                accent: Color(red: 0.7, green: 0.6, blue: 0.9) // Lavender accent
            )
            
        case "team-6": // Laces BC
            colorScheme = AppColorScheme.teamColors(
                primary: Color(red: 0.9, green: 0.9, blue: 0.95), // White/cream
                secondary: Color(red: 0.7, green: 0.7, blue: 0.75), // Light gray
                accent: Color(red: 0.2, green: 0.2, blue: 0.3) // Dark accent
            )
            
        case "team-7": // Breeze
            colorScheme = AppColorScheme.teamColors(
                primary: Color(red: 0.4, green: 0.7, blue: 0.9), // Sky blue
                secondary: Color(red: 0.6, green: 0.85, blue: 0.95), // Light sky blue
                accent: Color(red: 0.2, green: 0.5, blue: 0.7) // Deep sky blue
            )
            
        case "team-8": // Hive
            colorScheme = AppColorScheme.teamColors(
                primary: Color(red: 1.0, green: 0.8, blue: 0.2), // Golden yellow
                secondary: Color(red: 1.0, green: 0.9, blue: 0.5), // Light golden
                accent: Color(red: 0.8, green: 0.6, blue: 0.1) // Amber
            )
            
        default:
            // Default theme for unknown teams
            colorScheme = AppColorScheme.teamColors(
                primary: Theme.wehoop.colorScheme.primary,
                secondary: Theme.wehoop.colorScheme.secondary,
                accent: Theme.wehoop.colorScheme.accent
            )
        }
        
        return Theme(
            colorScheme: colorScheme,
            typography: typography
        )
    }
    
    /// Clear cached themes (useful for testing or theme updates)
    func clearCache() {
        themes.removeAll()
    }
}
