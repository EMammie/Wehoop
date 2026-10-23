//
//  LocalDataSource.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Protocol for local data source operations
protocol LocalDataSource {
    func loadGames() throws -> Data?
    func loadPlayers() throws -> Data?
    func loadTeams() throws -> Data?
    func loadBoxScore(gameId: String) throws -> Data?
}
