//
//  GetGamesUseCase.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Use case for retrieving games
class GetGamesUseCase {
    private let gameRepository: GameRepository
    
    init(gameRepository: GameRepository) {
        self.gameRepository = gameRepository
    }
    
    /// Execute the use case with optional date filter
    /// - Parameter date: Optional date to filter games. If nil, returns all games.
    /// - Returns: Array of games for the specified date or all games if date is nil
    func execute(date: Date?) async throws -> [Game] {
        return try await gameRepository.getGames(date: date)
    }
    
    /// Execute the use case (backward compatibility - calls execute(date: nil))
    func execute() async throws -> [Game] {
        return try await execute(date: nil)
    }
    
    /// Get a single game by ID with full details including box score
    /// - Parameter id: The game ID
    /// - Returns: The game with full details
    func execute(gameId: String) async throws -> Game {
        return try await gameRepository.getGame(id: gameId)
    }
}
