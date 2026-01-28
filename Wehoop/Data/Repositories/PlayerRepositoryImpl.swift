//
//  PlayerRepositoryImpl.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Implementation of PlayerRepository
class PlayerRepositoryImpl: PlayerRepository {
    private let remoteDataSource: RemoteDataSource
    private let localDataSource: LocalDataSource
    private let cacheService: CacheService
    
    /// Cache staleness threshold: 15 minutes
    private let cacheStalenessThreshold: TimeInterval = 15 * 60
    
    init(remoteDataSource: RemoteDataSource, localDataSource: LocalDataSource, cacheService: CacheService) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.cacheService = cacheService
    }
    
    func getPlayers() async throws -> [Player] {
        let cacheKey = "players_all"
        
        // Check cache first - return if fresh
        if let cachedPlayers: [Player] = cacheService.get([Player].self, forKey: cacheKey),
           !cacheService.isStale(forKey: cacheKey, maxAge: cacheStalenessThreshold) {
            return cachedPlayers
        }
        
        // Cache is stale or empty - try remote first
        var players: [Player] = []
        
        do {
            let remoteData = try await remoteDataSource.fetchPlayers()
            let decoder = JSONDecoder()
            let playerDTOs = try decoder.decode([PlayerDTO].self, from: remoteData)
            players = try playerDTOs.map { try $0.toDomain() }
            
            // Persist to cache
            if !players.isEmpty {
                cacheService.set(players, forKey: cacheKey, expiration: 600) // 10 minutes cache
            }
            
            // Persist to writable local data source if available
            if let writableDataSource = localDataSource as? WritableLocalDataSource {
                try writableDataSource.savePlayers(remoteData)
            }
            
            return players
        } catch {
            // Remote failed - fall back to local data source
            if let localData = try localDataSource.loadPlayers() {
                let decoder = JSONDecoder()
                let playerDTOs = try decoder.decode([PlayerDTO].self, from: localData)
                players = try playerDTOs.map { try $0.toDomain() }
                
                // Cache the local data
                if !players.isEmpty {
                    cacheService.set(players, forKey: cacheKey, expiration: 600)
                }
                
                return players
            }
            
            // Both remote and local failed - throw error
            throw error
        }
    }
    
    func getPlayer(id: String) async throws -> Player {
        let cacheKey = "player_\(id)"
        
        // Check cache first - return if fresh
        if let cachedPlayer: Player = cacheService.get(Player.self, forKey: cacheKey),
           !cacheService.isStale(forKey: cacheKey, maxAge: cacheStalenessThreshold) {
            return cachedPlayer
        }
        
        // If data source supports player profiles, try fetching directly (more efficient)
        if let profileDataSource = remoteDataSource as? PlayerProfileDataSource {
            do {
                let remoteData = try await profileDataSource.fetchPlayerProfile(playerId: id)
                let decoder = JSONDecoder()
                let playerDTO = try decoder.decode(PlayerDTO.self, from: remoteData)
                let player = try playerDTO.toDomain()
                cacheService.set(player, forKey: cacheKey, expiration: 600)
                
                // Persist to writable local data source if available
                if let writableDataSource = localDataSource as? WritableLocalDataSource {
                    // Note: We save the full players array, so we'd need to merge this single player
                    // For now, we'll just cache it - full persistence can be handled in getPlayers()
                }
                
                return player
            } catch {
                // Profile fetch failed, fall through to other methods
            }
        }
        
        // Try to get from all players first
        let allPlayers = try await getPlayers()
        if let player = allPlayers.first(where: { $0.id == id }) {
            cacheService.set(player, forKey: cacheKey, expiration: 600)
            return player
        }
        
        // If not found in players list, try fetching directly from data sources
        // Try local data source
        if let localData = try localDataSource.loadPlayers() {
            let decoder = JSONDecoder()
            let playerDTOs = try decoder.decode([PlayerDTO].self, from: localData)
            if let playerDTO = playerDTOs.first(where: { $0.id == id }) {
                let player = try playerDTO.toDomain()
                cacheService.set(player, forKey: cacheKey, expiration: 600)
                return player
            }
        }
        
        // Try remote data source (fallback to fetching all players)
        do {
            let remoteData = try await remoteDataSource.fetchPlayers()
            let decoder = JSONDecoder()
            let playerDTOs = try decoder.decode([PlayerDTO].self, from: remoteData)
            if let playerDTO = playerDTOs.first(where: { $0.id == id }) {
                let player = try playerDTO.toDomain()
                cacheService.set(player, forKey: cacheKey, expiration: 600)
                return player
            }
        } catch {
            // Remote fetch failed
        }
        
        throw NSError(domain: "PlayerRepositoryError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Player not found: \(id)"])
    }
}
