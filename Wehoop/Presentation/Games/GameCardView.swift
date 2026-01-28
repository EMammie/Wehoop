//
//  GameCardView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Card view for displaying a game
struct GameCardView: View {
    let game: Game
    @State private var showBoxScore = false
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status indicator
            if game.isLive {
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Spacer()
                }
            } else {
                HStack {
                    Text(game.status.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if let date = formatDate(game.date) {
                        Text(date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Teams and score
            HStack(spacing: 16) {
                // Away team
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.awayTeam.abbreviation)
                        .font(.headline)
                    Text(game.awayTeam.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Score
                if let boxScore = game.boxScore {
                    VStack(spacing: 4) {
                        Text("\(boxScore.awayScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(boxScore.homeScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(width: 60)
                } else {
                    Text("TBD")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(width: 60)
                }
                
                // Home team
                VStack(alignment: .trailing, spacing: 4) {
                    Text(game.homeTeam.abbreviation)
                        .font(.headline)
                    Text(game.homeTeam.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Box score button
            if game.boxScore != nil {
                Button(action: {
                    showBoxScore = true
                }) {
                    HStack {
                        Text("View Box Score")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(theme.colorScheme.accent)
                }
            }
        }
        .padding()
        .background(theme.colorScheme.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: game.status)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(game.boxScore != nil ? "Double tap to view box score" : "")
        .sheet(isPresented: $showBoxScore) {
            if let boxScore = game.boxScore {
                BoxScoreView(game: game, boxScore: boxScore)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var accessibilityLabel: String {
        var label = "\(game.awayTeam.name) vs \(game.homeTeam.name)"
        if let boxScore = game.boxScore {
            label += ", Score: \(boxScore.awayScore) to \(boxScore.homeScore)"
        }
        if game.isLive {
            label += ", Live"
        } else {
            label += ", \(game.status.displayName)"
        }
        return label
    }
}

// MARK: - Previews

#Preview("Finished Game") {
    GameCardView(game: GameFixtures.finishedGame())
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Live Game") {
    GameCardView(game: GameFixtures.liveGame())
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Scheduled Game") {
    GameCardView(game: GameFixtures.scheduledGame())
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Postponed Game") {
    GameCardView(game: GameFixtures.postponedGame())
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Cancelled Game") {
    GameCardView(game: GameFixtures.cancelledGame())
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Close Score Game") {
    GameCardView(game: GameFixtures.gameWithCloseScore())
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("High Score Game") {
    GameCardView(game: GameFixtures.gameWithHighScore())
        .padding()
        .background(Color(.systemGroupedBackground))
}
