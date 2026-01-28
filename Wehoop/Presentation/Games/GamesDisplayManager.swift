//
//  GamesDisplayManager.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Manager for organizing and categorizing games for display
struct GamesDisplayManager {
    /// Organize games into live, upcoming, and finished categories
    /// - Parameter games: Array of games to organize
    /// - Returns: GamesDisplayResult with categorized and sorted games
    static func organize(_ games: [Game]) -> GamesDisplayResult {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Categorize games
        var liveGames: [Game] = []
        var upcomingGames: [Game] = []
        var finishedGames: [Game] = []
        
        for game in games {
            let gameDate = calendar.startOfDay(for: game.date)
            
            // Live games: status == .live
            if game.status == .live {
                liveGames.append(game)
            }
            // Upcoming games: status == .scheduled OR date >= today OR status == .postponed
            else if game.status == .scheduled || game.status == .postponed || gameDate >= today {
                upcomingGames.append(game)
            }
            // Finished games: status == .finished OR (date < today AND has scores) OR status == .cancelled
            else if game.status == .finished || game.status == .cancelled || (gameDate < today && game.boxScore != nil) {
                finishedGames.append(game)
            }
            // Fallback: if game date is in the past but no status indicates finished, check if it has scores
            else if gameDate < today && game.boxScore != nil {
                finishedGames.append(game)
            }
            // Default: treat as upcoming if we can't determine
            else {
                upcomingGames.append(game)
            }
        }
        
        // Sort all categories by date descending (most recent first)
        let sortByDateDescending: (Game, Game) -> Bool = { $0.date > $1.date }
        liveGames.sort(by: sortByDateDescending)
        upcomingGames.sort(by: sortByDateDescending)
        finishedGames.sort(by: sortByDateDescending)
        
        // Create allGames array (all games sorted by date descending)
        let allGames = games.sorted(by: sortByDateDescending)
        
        return GamesDisplayResult(
            liveGames: liveGames,
            upcomingGames: upcomingGames,
            finishedGames: finishedGames,
            allGames: allGames
        )
    }
}
