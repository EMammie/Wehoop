//
//  InMemoryLocalDataSource.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// In-memory implementation of LocalDataSource and WritableLocalDataSource
/// Stores data in memory using dictionaries, suitable for runtime persistence
/// Can later be replaced with a relational database implementation
class InMemoryLocalDataSource: LocalDataSource, WritableLocalDataSource {
    private var games: Data?
    private var players: Data?
    private var teams: Data?
    private var boxScores: [String: Data] = [:]
    
    private let lock = NSLock()
    
    // MARK: - LocalDataSource
    
    func loadGames() throws -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return games
    }
    
    func loadPlayers() throws -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return players
    }
    
    func loadTeams() throws -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return teams
    }
    
    func loadBoxScore(gameId: String) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return boxScores[gameId]
    }
    
    // MARK: - WritableLocalDataSource
    
    func saveGames(_ data: Data) throws {
        lock.lock()
        defer { lock.unlock() }
        games = data
    }
    
    func savePlayers(_ data: Data) throws {
        lock.lock()
        defer { lock.unlock() }
        players = data
    }
    
    func saveTeams(_ data: Data) throws {
        lock.lock()
        defer { lock.unlock() }
        teams = data
    }
    
    func saveBoxScore(_ data: Data, gameId: String) throws {
        lock.lock()
        defer { lock.unlock() }
        boxScores[gameId] = data
    }
}
