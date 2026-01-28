//
//  GamesDisplayResult.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Result structure containing organized games for display
struct GamesDisplayResult {
    /// Games currently live
    let liveGames: [Game]
    
    /// Games that are scheduled or upcoming
    let upcomingGames: [Game]
    
    /// Games that have finished
    let finishedGames: [Game]
    
    /// All games sorted by date descending (for backward compatibility)
    let allGames: [Game]
    
    /// Whether there are any live games
    var hasLiveGames: Bool {
        !liveGames.isEmpty
    }
    
    /// Whether there are any upcoming games
    var hasUpcomingGames: Bool {
        !upcomingGames.isEmpty
    }
    
    /// Whether there are any finished games
    var hasFinishedGames: Bool {
        !finishedGames.isEmpty
    }
    
    /// Whether there are no games at all
    var isEmpty: Bool {
        allGames.isEmpty
    }
}
