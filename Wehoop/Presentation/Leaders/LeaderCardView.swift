//
//  LeaderCardView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Card view for displaying a stat leader
struct LeaderCardView: View {
    let player: Player
    let rank: Int
    let category: StatCategory
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text("\(rank)")
                .font(theme.typography.title)
                .fontWeight(.bold)
                .foregroundColor(rankColor)
                .frame(width: 40)
            
            // Player info
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colorScheme.foreground)
                HStack {
                    Text(player.team.abbreviation)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colorScheme.secondary)
                    
                        Text("• \(player.positionAbbreviation)")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colorScheme.secondary)

                }
            }
            
            Spacer()

            // Stat value
            if let stat = player.statistic(for: category) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(stat.formattedValue)
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colorScheme.primary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: stat.value)
                    Text(stat.name)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colorScheme.secondary)
                        .transition(.opacity)
                }
            }
        }
        .padding()
        .background(theme.colorScheme.background)
        .cornerRadius(12)
        .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: rank)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow // Gold
        case 2: return .gray // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return theme.colorScheme.primary
        }
    }
}

#Preview("Scoring - Rank 2") {
    LeaderCardView(player: GameFixtures.breannaStewart(), rank: 2, category: .scoring)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Rebounding - Rank 1") {
    LeaderCardView(player: GameFixtures.breannaStewart(), rank: 1, category: .rebounding)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Assists - Rank 3") {
    LeaderCardView(player: GameFixtures.sabrinaIonescu(), rank: 3, category: .assists)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Defense - Rank 1") {
    LeaderCardView(player: GameFixtures.breannaStewart(), rank: 1, category: .defense)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Shooting - Rank 2") {
    LeaderCardView(player: GameFixtures.breannaStewart(), rank: 2, category: .shooting)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Top Rank (Gold)") {
    LeaderCardView(player: GameFixtures.caitlinClark(), rank: 1, category: .scoring)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Second Rank (Silver)") {
    LeaderCardView(player: GameFixtures.rickeaJackson(), rank: 2, category: .scoring)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Third Rank (Bronze)") {
    LeaderCardView(player: GameFixtures.sabrinaIonescu(), rank: 3, category: .scoring)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Lower Rank") {
    LeaderCardView(player: GameFixtures.breannaStewart(), rank: 5, category: .rebounding)
        .padding()
        .background(Color(.systemGroupedBackground))
}
