//
//  PlayerCardView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Card view for displaying a player
struct PlayerCardView: View {
    let player: Player
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            // Player info
            VStack(alignment: .leading, spacing: 8) {
                Text(player.displayName)
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colorScheme.foreground)
                
                HStack(spacing: 12) {
                    Text(player.team.abbreviation)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colorScheme.secondary)
                    

                        Text("• \(player.positionAbbreviation)")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colorScheme.secondary)

                }
                
                // Key stats
                HStack(spacing: 16) {
                    if player.pointsPerGame > 0 {
                        statBadge(label: "PTS", value: String(format: "%.1f", player.pointsPerGame))
                    }
                    if player.reboundsPerGame > 0 {
                        statBadge(label: "REB", value: String(format: "%.1f", player.reboundsPerGame))
                    }
                    if player.assistsPerGame > 0 {
                        statBadge(label: "AST", value: String(format: "%.1f", player.assistsPerGame))
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(theme.typography.caption)
                .foregroundColor(theme.colorScheme.secondary)
        }
        .padding()
        .background(theme.colorScheme.background)
        .cornerRadius(12)
        .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: player.id)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(player.displayName), \(player.team.name), \(player.positionAbbreviation)")
        .accessibilityHint("Double tap to view player profile")
    }
    
    private func statBadge(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(theme.typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(theme.colorScheme.primary)
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colorScheme.secondary)
        }
    }
}

#Preview("Player Card - With Stats") {
    PlayerCardView(player: GameFixtures.breannaStewart())
        .padding()
        .background(Color(.systemGroupedBackground))
        .environment(\.theme, Theme.wehoop)
}

#Preview("Player Card - Guard") {
    PlayerCardView(player: GameFixtures.sabrinaIonescu())
        .padding()
        .background(Color(.systemGroupedBackground))
        .environment(\.theme, Theme.wehoop)
}

#Preview("Player Card - Forward") {
    PlayerCardView(player: GameFixtures.rickeaJackson())
        .padding()
        .background(Color(.systemGroupedBackground))
        .environment(\.theme, Theme.wehoop)
}

#Preview("Player Card - Center") {
    PlayerCardView(player: GameFixtures.caitlinClark())
        .padding()
        .background(Color(.systemGroupedBackground))
        .environment(\.theme, Theme.wehoop)
}
