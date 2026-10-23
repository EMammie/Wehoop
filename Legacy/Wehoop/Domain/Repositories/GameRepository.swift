//
//  GameRepository.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Protocol for game repository operations
protocol GameRepository {
    /// Get games, optionally filtered by date
    /// - Parameter date: Optional date to filter games. If nil, returns all games.
    /// - Returns: Array of games for the specified date or all games if date is nil
    func getGames(date: Date?) async throws -> [Game]
    
    /// Get games (backward compatibility - calls getGames(date: nil))
    func getGames() async throws -> [Game]
    
    func getGame(id: String) async throws -> Game
}
