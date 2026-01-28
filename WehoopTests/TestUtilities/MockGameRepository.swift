//
//  MockGameRepository.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import Foundation
@testable import Wehoop

/// Mock implementation of GameRepository for testing
class MockGameRepository: GameRepository {
    var games: [Game] = []
    var getGamesError: Error?
    var getGameError: Error?
    var getGamesCallCount = 0
    var getGameCallCount = 0
    
    func getGames(date: Date?) async throws -> [Game] {
        getGamesCallCount += 1
        if let error = getGamesError {
            throw error
        }
        
        // Filter by date if provided
        if let date = date {
            let calendar = Calendar.current
            return games.filter { calendar.isDate($0.date, inSameDayAs: date) }
        }
        
        return games
    }
    
    func getGames() async throws -> [Game] {
        return try await getGames(date: nil)
    }
    
    func getGame(id: String) async throws -> Game {
        getGameCallCount += 1
        if let error = getGameError {
            throw error
        }
        guard let game = games.first(where: { $0.id == id }) else {
            throw NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Game not found"])
        }
        return game
    }
}
