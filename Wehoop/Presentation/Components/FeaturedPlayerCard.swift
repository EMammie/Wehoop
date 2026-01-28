//
//  FeaturedPlayerCard.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Large player card with image, name, team, and primary stat
struct FeaturedPlayerCard: View {
    let player: Player
    let statValue: String
    let statLabel: String
    @Environment(\.theme) private var theme
    @Environment(\.teamThemeProvider) private var teamThemeProvider
    
    var body: some View {
        let teamTheme = teamThemeProvider.theme(for: player.team)
        
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Profile picture placeholder
                ZStack {
                    Circle()
                        .fill(teamTheme.colorScheme.primary.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Text(player.name.prefix(1))
                        .font(theme.typography.title)
                        .foregroundColor(teamTheme.colorScheme.primary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(player.name)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colorScheme.foreground)
                    
                    Text(player.team.name)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colorScheme.secondary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(statValue)
                                .font(theme.typography.title)
                                .fontWeight(.bold)
                                .foregroundColor(theme.colorScheme.primary)
                            
                            Text(statLabel)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colorScheme.secondary)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(theme.colorScheme.background)
        .cornerRadius(12)
        .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    FeaturedPlayerCard(
        player: GameFixtures.rickeaJackson(),
        statValue: "23.7",
        statLabel: "PPG"
    )
    .padding()
    .environment(\.theme, Theme.wehoop)
    .environment(\.teamThemeProvider, TeamThemeProvider())
}
