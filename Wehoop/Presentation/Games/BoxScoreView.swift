//
//  BoxScoreView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// View for displaying a game's box score
struct BoxScoreView: View {
    let game: Game
    let boxScore: BoxScore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Score summary
                    scoreSummary
                    
                    // Team stats
                    teamStatsSection
                    
                    // Quarter scores
                    if let quarters = boxScore.quarters, !quarters.isEmpty {
                        quarterScoresSection(quarters: quarters)
                    }
                }
                .padding()
            }
            .navigationTitle("Box Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var scoreSummary: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(game.awayTeam.abbreviation)
                        .font(.headline)
                    Text(game.awayTeam.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(boxScore.awayScore)")
                    .font(.system(size: 36, weight: .bold))
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text(game.homeTeam.abbreviation)
                        .font(.headline)
                    Text(game.homeTeam.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(boxScore.homeScore)")
                    .font(.system(size: 36, weight: .bold))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var teamStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Team Statistics")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                statsRow(title: "Points", home: boxScore.homeStats.points, away: boxScore.awayStats.points)
                statsRow(title: "Rebounds", home: boxScore.homeStats.rebounds, away: boxScore.awayStats.rebounds)
                statsRow(title: "Assists", home: boxScore.homeStats.assists, away: boxScore.awayStats.assists)
                
                if let homeSteals = boxScore.homeStats.steals, let awaySteals = boxScore.awayStats.steals {
                    statsRow(title: "Steals", home: homeSteals, away: awaySteals)
                }
                
                if let homeBlocks = boxScore.homeStats.blocks, let awayBlocks = boxScore.awayStats.blocks {
                    statsRow(title: "Blocks", home: homeBlocks, away: awayBlocks)
                }
                
                if let homeTurnovers = boxScore.homeStats.turnovers, let awayTurnovers = boxScore.awayStats.turnovers {
                    statsRow(title: "Turnovers", home: homeTurnovers, away: awayTurnovers)
                }
                
                if let homeFG = boxScore.homeStats.fieldGoalPercentage, let awayFG = boxScore.awayStats.fieldGoalPercentage {
                    statsRow(title: "FG%", home: String(format: "%.1f%%", homeFG), away: String(format: "%.1f%%", awayFG))
                }
                
                if let home3PT = boxScore.homeStats.threePointPercentage, let away3PT = boxScore.awayStats.threePointPercentage {
                    statsRow(title: "3PT%", home: String(format: "%.1f%%", home3PT), away: String(format: "%.1f%%", away3PT))
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    private func statsRow(title: String, home: Any, away: Any) -> some View {
        HStack {
            Text("\(away)")
                .frame(width: 60, alignment: .trailing)
            Text(title)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("\(home)")
                .frame(width: 60, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5)
                        .offset(y: -0.25),
                    alignment: .bottom
                )
        )
    }
    
    private func quarterScoresSection(quarters: [QuarterScore]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quarter Scores")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 80)
                ForEach(quarters) { quarter in
                    Text(quarter.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 0) {
                Text(game.awayTeam.abbreviation)
                    .font(.subheadline)
                    .frame(width: 80, alignment: .leading)
                ForEach(quarters) { quarter in
                    Text("\(quarter.awayScore)")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 0) {
                Text(game.homeTeam.abbreviation)
                    .font(.subheadline)
                    .frame(width: 80, alignment: .leading)
                ForEach(quarters) { quarter in
                    Text("\(quarter.homeScore)")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Previews

#Preview("Box Score - Finished Game") {
    BoxScoreView(
        game: GameFixtures.finishedGame(),
        boxScore: GameFixtures.boxScore()
    )
}

#Preview("Box Score - Live Game") {
    BoxScoreView(
        game: GameFixtures.liveGame(),
        boxScore: GameFixtures.boxScore(
            homeScore: 45,
            awayScore: 48,
            homeStats: GameFixtures.teamStats(points: 45, rebounds: 22, assists: 10, steals: 3, blocks: 2, turnovers: 6, fieldGoalPercentage: 44.2, threePointPercentage: 36.5, freeThrowPercentage: 80.0, fouls: 8),
            awayStats: GameFixtures.teamStats(points: 48, rebounds: 24, assists: 11, steals: 5, blocks: 3, turnovers: 5, fieldGoalPercentage: 50.8, threePointPercentage: 42.1, freeThrowPercentage: 85.7, fouls: 9)
        )
    )
}

#Preview("Box Score - Close Game") {
    BoxScoreView(
        game: GameFixtures.gameWithCloseScore(),
        boxScore: GameFixtures.boxScore(homeScore: 61, awayScore: 60)
    )
}

#Preview("Box Score - High Scoring Game") {
    BoxScoreView(
        game: GameFixtures.gameWithHighScore(),
        boxScore: GameFixtures.boxScore(
            homeScore: 75,
            awayScore: 68,
            homeStats: GameFixtures.teamStats(points: 75, rebounds: 32, assists: 18, steals: 8, blocks: 4, turnovers: 7, fieldGoalPercentage: 52.3, threePointPercentage: 41.2, freeThrowPercentage: 88.5, fouls: 10),
            awayStats: GameFixtures.teamStats(points: 68, rebounds: 28, assists: 15, steals: 5, blocks: 2, turnovers: 9, fieldGoalPercentage: 48.7, threePointPercentage: 38.9, freeThrowPercentage: 82.3, fouls: 12)
        )
    )
}
