//
//  CompactGameCardView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Compact game card view matching mockup design
struct CompactGameCardView: View {
    let game: Game
    @Environment(\.theme) private var theme
    @Environment(\.teamThemeProvider) private var teamThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            // Away team
            teamView(team: game.awayTeam, score: game.boxScore?.awayScore, isWinning: isAwayTeamWinning)
            
            // VS separator
            Text("vs")
                .font(theme.typography.caption)
                .foregroundColor(theme.colorScheme.secondary)
            
            // Home team
            teamView(team: game.homeTeam, score: game.boxScore?.homeScore, isWinning: isHomeTeamWinning)
            
            Spacer()
            
            // Quarter/Status info
            VStack(alignment: .trailing, spacing: 4) {
                if game.isLive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(theme.typography.caption)
                            .foregroundColor(.red)
                    }
                } else {
                  if game.status != .scheduled {
                    Text(game.status.displayName)
                      .font(theme.typography.caption)
                      .foregroundColor(theme.colorScheme.secondary)
                  }
                }
                
                // Only show quarter indicator for live games, not finished games
                if game.isLive,
                   let boxScore = game.boxScore,
                   let quarters = boxScore.quarters,
                   !quarters.isEmpty {
                    Text("Q\(quarters.count)")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colorScheme.secondary)
                }
                
                // Show broadcast and schedule info for scheduled games
                if game.status == .scheduled {
                    scheduledGameInfo
                }
            }
        }
        .padding()
        .background(theme.colorScheme.background)
        .cornerRadius(12)
        .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    /// Check if away team is winning (only for finished games)
    private var isAwayTeamWinning: Bool {
        guard game.isFinished,
              let boxScore = game.boxScore else {
            return false
        }
        return boxScore.awayScore > boxScore.homeScore
    }
    
    /// Check if home team is winning (only for finished games)
    private var isHomeTeamWinning: Bool {
        guard game.isFinished,
              let boxScore = game.boxScore else {
            return false
        }
        return boxScore.homeScore > boxScore.awayScore
    }
    
    /// Determine if scores should be displayed
    private var shouldShowScores: Bool {
        return (game.isLive || game.isFinished) && game.boxScore != nil
    }

  @ViewBuilder
    private func teamView(team: Team, score: Int?, isWinning: Bool = false) -> some View {
        let teamTheme = teamThemeProvider.theme(for: team)
        
        // For games without scores (scheduled, postponed, cancelled), stack team name above logo
        if !shouldShowScores || score == nil {

                VStack(spacing: 6) {
                    Text(team.name)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colorScheme.foreground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    // Team logo
                    ZStack {
                        Circle()
                            .fill(teamTheme.colorScheme.primary.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Text(team.abbreviation)
                            .font(theme.typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(teamTheme.colorScheme.primary)
                    }
                }
                .frame(width: 70)
        }
        
        // For live/finished games with scores, show score prominently next to logo
        return
            HStack(spacing: 8) {
                // Team logo
                ZStack {
                    Circle()
                        .fill(teamTheme.colorScheme.primary.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(team.abbreviation)
                        .font(theme.typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(teamTheme.colorScheme.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.abbreviation)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colorScheme.secondary)
                    
                    if let score = score {
                        Text("\(score)")
                            .font(theme.typography.title)
                            .fontWeight(.bold)
                            .foregroundColor(isWinning ? theme.colorScheme.primary : theme.colorScheme.foreground)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                }
                .frame(minWidth: 50) // Ensure consistent width for scores
            }

    }
    
    /// Scheduled game information (broadcast network, date/time, timezone)
    @ViewBuilder
    private var scheduledGameInfo: some View {
        VStack(alignment: .center, spacing: 2) {
            // Broadcast network
            if let network = game.broadcastNetwork {
                Text(network)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colorScheme.secondary)
            }
            
            // Scheduled date and time
            Text(formattedScheduledTime)
                .font(theme.typography.caption)
                .foregroundColor(theme.colorScheme.secondary)
        }
    }
    
    /// Format scheduled date and time with timezone
    private var formattedScheduledTime: String {
        let formatter = DateFormatter()
        
        // Format date and time in readable format
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        // Use game's timezone if available, otherwise use system timezone
        if let timeZoneString = game.timeZone,
           let timeZone = TimeZone(identifier: timeZoneString) {
            formatter.timeZone = timeZone
        } else {
            formatter.timeZone = TimeZone.current
        }
        
        let dateTimeString = formatter.string(from: game.date)
        
        // Add timezone abbreviation
        let timeZoneAbbreviation: String
        if let timeZoneString = game.timeZone,
           let timeZone = TimeZone(identifier: timeZoneString) {
            let abbreviation = timeZone.abbreviation(for: game.date) ?? ""
            timeZoneAbbreviation = abbreviation.replacingOccurrences(of: "GMT", with: "")
        } else {
            timeZoneAbbreviation = formatter.timeZone.abbreviation(for: game.date)?.replacingOccurrences(of: "GMT", with: "") ?? ""
        }
        
        return "\(dateTimeString) \(timeZoneAbbreviation)"
    }
}

#Preview {
    VStack(spacing: 12) {
        // Live game example
        VStack(alignment: .leading, spacing: 4) {
            Text("Live Game")
                .font(.caption)
                .foregroundColor(.secondary)
            CompactGameCardView(game: GameFixtures.liveGame())
        }
        
        // Finished game example
        VStack(alignment: .leading, spacing: 4) {
            Text("Finished Game")
                .font(.caption)
                .foregroundColor(.secondary)
            CompactGameCardView(game: GameFixtures.finishedGame())
        }
        
        // Scheduled game example
        VStack(alignment: .leading, spacing: 4) {
            Text("Scheduled Game")
                .font(.caption)
                .foregroundColor(.secondary)
            CompactGameCardView(game: GameFixtures.scheduledGame())
        }
        
        // Postponed game example
        VStack(alignment: .leading, spacing: 4) {
            Text("Postponed Game")
                .font(.caption)
                .foregroundColor(.secondary)
            CompactGameCardView(game: GameFixtures.postponedGame())
        }
        
        // Cancelled game example
        VStack(alignment: .leading, spacing: 4) {
            Text("Cancelled Game")
                .font(.caption)
                .foregroundColor(.secondary)
            CompactGameCardView(game: GameFixtures.cancelledGame())
        }
    }
    .padding()
    .environment(\.theme, Theme.wehoop)
    .environment(\.teamThemeProvider, TeamThemeProvider())
}
