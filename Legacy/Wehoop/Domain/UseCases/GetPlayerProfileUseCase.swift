//
//  GetPlayerProfileUseCase.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Use case for retrieving a player's profile
class GetPlayerProfileUseCase {
    private let playerRepository: PlayerRepository
    private let playerId: String
    
    init(playerRepository: PlayerRepository, playerId: String) {
        self.playerRepository = playerRepository
        self.playerId = playerId
    }
    
    func execute() async throws -> Player {
        return try await playerRepository.getPlayer(id: playerId)
    }
}
