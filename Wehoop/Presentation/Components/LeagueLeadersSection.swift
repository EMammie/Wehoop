//
//  LeagueLeadersSection.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Compact section showing top players with profile pictures
struct LeagueLeadersSection: View {
    let players: [Player]
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tonight's Leaders")
                .font(theme.typography.headline)
                .foregroundColor(theme.colorScheme.foreground)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(players.prefix(5).enumerated()), id: \.element.id) { index, player in
                        VStack(spacing: 8) {
                            // Profile picture placeholder
                            ZStack {
                                Circle()
                                    .fill(theme.colorScheme.secondary.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                
                                Text(player.name.prefix(1))
                                    .font(theme.typography.headline)
                                    .foregroundColor(theme.colorScheme.primary)
                            }
                            
                            Text(player.name)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colorScheme.foreground)
                                .lineLimit(1)
                                .frame(width: 60)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    LeagueLeadersSection(players: GameFixtures.topPlayers())
        .environment(\.theme, Theme.wehoop)
        .environment(\.teamThemeProvider, TeamThemeProvider())
}
