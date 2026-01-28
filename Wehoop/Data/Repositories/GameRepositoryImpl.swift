//
//  GameRepositoryImpl.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Implementation of GameRepository
class GameRepositoryImpl: GameRepository {
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
    
    func getGames(date: Date?) async throws -> [Game] {
        // Generate cache key based on date
        let dateString: String
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dateString = formatter.string(from: date)
        } else {
            dateString = "all"
        }
        let cacheKey = "games_\(dateString)"
        
        // Check cache first - return if fresh
        if let cachedGames: [Game] = cacheService.get([Game].self, forKey: cacheKey),
           !cacheService.isStale(forKey: cacheKey, maxAge: cacheStalenessThreshold) {
            return cachedGames
        }
        
        // Cache is stale or empty - try remote first
        var games: [Game] = []
        
        do {
            let remoteData = try await remoteDataSource.fetchGames(date: date)
            let decoder = JSONDecoder()
            let gameDTOs = try decoder.decode([GameDTO].self, from: remoteData)
            games = try gameDTOs.map { try $0.toDomain() }
            
            // Fetch box scores for live and finished games that don't have them
            games = await enrichGamesWithBoxScores(games)
            
            // Persist to cache
            if !games.isEmpty {
                cacheService.set(games, forKey: cacheKey, expiration: 300) // 5 minutes cache
            }
            
            // Persist to writable local data source if available
            if let writableDataSource = localDataSource as? WritableLocalDataSource {
                try writableDataSource.saveGames(remoteData)
            }
            
            return games
        } catch {
            // Remote failed - fall back to local data source
            if let localData = try localDataSource.loadGames() {
                let decoder = JSONDecoder()
                let gameDTOs = try decoder.decode([GameDTO].self, from: localData)
                games = try gameDTOs.map { try $0.toDomain() }
                
                // Filter by date if specified
                if let date = date {
                    let calendar = Calendar.current
                    games = games.filter { calendar.isDate($0.date, inSameDayAs: date) }
                }
                
                // Cache the local data
                if !games.isEmpty {
                    cacheService.set(games, forKey: cacheKey, expiration: 300)
                }
                
                return games
            }
            
            // Both remote and local failed - throw error
            throw error
        }
    }
    
    func getGames() async throws -> [Game] {
        return try await getGames(date: nil)
    }
    
    func getGame(id: String) async throws -> Game {
        let cacheKey = "game_\(id)"
        
        // Check cache first - return if fresh
        // However, for finished/live games, ensure they have a box score
        // If they don't, treat cache as stale to force a fresh fetch
        var shouldForceRefresh = false
        if let cachedGame: Game = cacheService.get(Game.self, forKey: cacheKey),
           !cacheService.isStale(forKey: cacheKey, maxAge: cacheStalenessThreshold) {
            // For finished/live games, ensure they have a box score
            // If not, treat as stale to allow fetching box score
            if (cachedGame.isFinished || cachedGame.isLive) && cachedGame.boxScore == nil {
                // Cache is stale for this purpose - clear it and fetch fresh
                cacheService.remove(forKey: cacheKey)
                shouldForceRefresh = true
            } else {
                return cachedGame
            }
        }
        
        // For finished/live games without box score, prioritize direct fetch
        // This is more reliable for historical games and ensures we get the box score
        if shouldForceRefresh {
            // Try fetching game directly by ID using game summary endpoint first
            // This endpoint includes box score and is more reliable for past games
            // Skip the getGames() path to avoid cached games without box scores
            do {
                let gameData = try await remoteDataSource.fetchGame(gameId: id)
                let decoder = JSONDecoder()
                let gameDTO = try decoder.decode(GameDTO.self, from: gameData)
                var game = try gameDTO.toDomain()
                
                // If game still doesn't have box score, try fetching it separately
                if (game.isFinished || game.isLive) && game.boxScore == nil {
                    do {
                        let boxScoreData = try await remoteDataSource.fetchBoxScore(gameId: id)
                        let boxScoreDTO = try decoder.decode(BoxScoreDTO.self, from: boxScoreData)
                        
                        // Create updated game with box score
                        game = Game(
                            id: game.id,
                            homeTeam: game.homeTeam,
                            awayTeam: game.awayTeam,
                            date: game.date,
                            status: game.status,
                            boxScore: try boxScoreDTO.toDomain(),
                            venue: game.venue,
                            league: game.league,
                            broadcastNetwork: game.broadcastNetwork,
                            timeZone: game.timeZone
                        )
                    } catch {
                        // Box score fetch failed, but we still have the game
                        Logger.error("Failed to fetch box score for game \(id): \(error.localizedDescription)")
                    }
                }
                
                // Cache the game (with or without box score)
                cacheService.set(game, forKey: cacheKey, expiration: 300)
                
                // Persist to writable local data source if available
                if let writableDataSource = localDataSource as? WritableLocalDataSource {
                    // Save the game to local storage
                }
                
                return game
            } catch {
                // Game fetch failed, continue to fallback
                Logger.error("Failed to fetch game \(id) from game summary: \(error.localizedDescription)")
                // Fall through to try other paths
            }
        }
        
        // Try to get from all games first (fastest if already cached)
        // Skip this if we're forcing a refresh (shouldForceRefresh) to avoid stale cached games
        if !shouldForceRefresh {
            let allGames = try await getGames()
            if let game = allGames.first(where: { $0.id == id }) {
            // If game exists but doesn't have box score, try fetching it for more complete data
            if game.boxScore == nil {
                do {
                    let boxScoreData = try await remoteDataSource.fetchBoxScore(gameId: id)
                    let decoder = JSONDecoder()
                    let boxScoreDTO = try decoder.decode(BoxScoreDTO.self, from: boxScoreData)
                    
                    // Create updated game with box score
                    let updatedGame = Game(
                        id: game.id,
                        homeTeam: game.homeTeam,
                        awayTeam: game.awayTeam,
                        date: game.date,
                        status: game.status,
                        boxScore: try boxScoreDTO.toDomain(),
                        venue: game.venue,
                        league: game.league,
                        broadcastNetwork: game.broadcastNetwork,
                        timeZone: game.timeZone

                    )
                    cacheService.set(updatedGame, forKey: cacheKey, expiration: 300)
                    
                    // Persist box score to writable local data source if available
                    if let writableDataSource = localDataSource as? WritableLocalDataSource {
                        try writableDataSource.saveBoxScore(boxScoreData, gameId: id)
                    }
                    
                    return updatedGame
                } catch {
                    // Box score fetch failed, return game without it
                    cacheService.set(game, forKey: cacheKey, expiration: 300)
                    return game
                }
            } else {
                cacheService.set(game, forKey: cacheKey, expiration: 300)
                return game
            }
            }
        }
        
        // If not found in games list, try fetching directly from data sources
        // Try local data source first
        if let localData = try localDataSource.loadGames() {
            let decoder = JSONDecoder()
            let gameDTOs = try decoder.decode([GameDTO].self, from: localData)
            if let gameDTO = gameDTOs.first(where: { $0.id == id }) {
                let game = try gameDTO.toDomain()
                cacheService.set(game, forKey: cacheKey, expiration: 300)
                return game
            }
        }
        
        // Try fetching game directly by ID using game summary endpoint (works for historical games)
        // This is more reliable than fetching all games, especially for past games
        do {
            let gameData = try await remoteDataSource.fetchGame(gameId: id)
            let decoder = JSONDecoder()
            let gameDTO = try decoder.decode(GameDTO.self, from: gameData)
            let game = try gameDTO.toDomain()
            
            // Cache the game
            cacheService.set(game, forKey: cacheKey, expiration: 300)
            
            // Persist to writable local data source if available
            if let writableDataSource = localDataSource as? WritableLocalDataSource {
                // Save the game to local storage
                // Note: We might need to add a saveGame method, but for now we can save it as part of games
                // For simplicity, we'll just cache it
            }
            
            return game
        } catch {
            // Game fetch failed, continue to fallback
            // Log the error for debugging
            Logger.error("Failed to fetch game \(id) from game summary: \(error.localizedDescription)")
        }
        
        // Fallback: Try remote data source (fetching all games)
        do {
          let remoteData = try await remoteDataSource.fetchGames(date: nil)
            let decoder = JSONDecoder()
            let gameDTOs = try decoder.decode([GameDTO].self, from: remoteData)
            if let gameDTO = gameDTOs.first(where: { $0.id == id }) {
                let game = try gameDTO.toDomain()
                cacheService.set(game, forKey: cacheKey, expiration: 300)
                return game
            }
        } catch {
            // Remote fetch failed
        }
        
        throw NSError(domain: "GameRepositoryError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Game not found: \(id)"])
    }
    
    // MARK: - Box Score Enrichment
    
    /// Enrich live and finished games with box scores by fetching them in parallel
    /// - Parameter games: Array of games to enrich
    /// - Returns: Array of games with box scores added for live/finished games
    private func enrichGamesWithBoxScores(_ games: [Game]) async -> [Game] {
        // Identify live and finished games without box scores
        let gamesNeedingBoxScores = games.filter { game in
            (game.isLive || game.isFinished) && game.boxScore == nil
        }
        
        // If no games need box scores, return games as-is
        guard !gamesNeedingBoxScores.isEmpty else {
            return games
        }
        
        // Fetch box scores in parallel using TaskGroup
        var enrichedGames = games
        
        await withTaskGroup(of: (gameId: String, boxScore: BoxScore?).self) { group in
            for game in gamesNeedingBoxScores {
                group.addTask {
                    do {
                        let boxScoreData = try await self.remoteDataSource.fetchBoxScore(gameId: game.id)
                        let decoder = JSONDecoder()
                        let boxScoreDTO = try decoder.decode(BoxScoreDTO.self, from: boxScoreData)
                        let boxScore = try boxScoreDTO.toDomain()
                        return (gameId: game.id, boxScore: boxScore)
                    } catch {
                        // Log error but don't fail - return game without box score
                        Logger.error("Failed to fetch box score for \(game.status.rawValue) game \(game.id): \(error.localizedDescription)")
                        return (gameId: game.id, boxScore: nil)
                    }
                }
            }
            
            // Collect results and update games
            for await result in group {
                if let index = enrichedGames.firstIndex(where: { $0.id == result.gameId }),
                   let boxScore = result.boxScore {
                    // Update game with box score
                    let game = enrichedGames[index]
                    enrichedGames[index] = Game(
                        id: game.id,
                        homeTeam: game.homeTeam,
                        awayTeam: game.awayTeam,
                        date: game.date,
                        status: game.status,
                        boxScore: boxScore,
                        venue: game.venue,
                        league: game.league,
                        broadcastNetwork: game.broadcastNetwork,
                        timeZone: game.timeZone
                    )
                }
            }
        }
        
        return enrichedGames
    }
}
