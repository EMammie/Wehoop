//
//  PlayerRepository.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Protocol for player repository operations
protocol PlayerRepository {
    func getPlayers() async throws -> [Player]
    func getPlayer(id: String) async throws -> Player
}
