//
//  MockPlayerRepository.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import Foundation
@testable import Wehoop

/// Mock implementation of PlayerRepository for testing
class MockPlayerRepository: PlayerRepository {
    var players: [Player] = []
    var getPlayersError: Error?
    var getPlayerError: Error?
    var getPlayersCallCount = 0
    var getPlayerCallCount = 0
    
    func getPlayers() async throws -> [Player] {
        getPlayersCallCount += 1
        if let error = getPlayersError {
            throw error
        }
        return players
    }
    
    func getPlayer(id: String) async throws -> Player {
        getPlayerCallCount += 1
        if let error = getPlayerError {
            throw error
        }
        guard let player = players.first(where: { $0.id == id }) else {
            throw NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Player not found"])
        }
        return player
    }
}
