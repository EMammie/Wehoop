//
//  LeagueLeadersRepositoryImpl.swift
//  Unrivaled
//
//  Created by E on 1/2/26.
//

import Foundation

/// Implementation of LeagueLeadersRepository
class LeagueLeadersRepositoryImpl: LeagueLeadersRepository {
    private let leagueLeaderDataSource: LeagueDataSource
    private let localDataSource: LocalDataSource
    private let cacheService: CacheService
    
    /// Cache staleness threshold: 15 minutes
    private let cacheStalenessThreshold: TimeInterval = 15 * 60
    
    init(leagueLeaderDataSource: LeagueDataSource, localDataSource: LocalDataSource, cacheService: CacheService) {
        self.leagueLeaderDataSource = leagueLeaderDataSource
        self.localDataSource = localDataSource
        self.cacheService = cacheService
    }
    
    func getLeagueLeaders(category: StatCategory, limit: Int) async throws -> [Player] {
        let cacheKey = "league_leaders_\(category.rawValue)_\(limit)"
        
        // Check cache first - return if fresh
        if let cachedLeaders: [Player] = cacheService.get([Player].self, forKey: cacheKey),
           !cacheService.isStale(forKey: cacheKey, maxAge: cacheStalenessThreshold) {
            return cachedLeaders
        }
        
        // Cache is stale or empty - try remote first
        var leaders: [Player] = []
        
        do {
            // Default to current year and regular season
            let seasonYear = String(Calendar.current.component(.year, from: Date()))
            let remoteData = try await leagueLeaderDataSource.fetchLeagueLeaders(seasonYear: seasonYear, seasonType: "REG")
            let decoder = JSONDecoder()
            
            // Decode LeaderEntry structure
            struct LeaderEntry: Codable {
                let category: String
                let player: PlayerDTO
            }
            
            let leaderEntries = try decoder.decode([LeaderEntry].self, from: remoteData)
            
            // Filter by requested category and map to domain models
            // The API returns many categories, so we need to match based on the category type
            let apiCategoryString = category.apiCategoryString
            let filteredEntries = leaderEntries.filter { entry in
                let entryCategory = entry.category.lowercased()
                var matches = false
                
                // Match exact category name or check if it's a related category
                if entryCategory == apiCategoryString.lowercased() {
                    matches = true
                }
                // For scoring, also match "points"
                else if category == .scoring && (entryCategory == "points" || entryCategory == "point") {
                    matches = true
                }
                // For rebounding, match "rebounds" or "rebound"
                else if category == .rebounding && entryCategory.contains("rebound") {
                    matches = true
                }
                // For assists, match "assists" or "assist"
                else if category == .assists && entryCategory.contains("assist") {
                    matches = true
                }
                // For defense, match "steals" or "blocks"
                else if category == .defense && (entryCategory.contains("steal") || (entryCategory.contains("block") && !entryCategory.contains("blocked_att"))) {
                    matches = true
                }
                // For shooting, match percentage categories
                else if category == .shooting && (entryCategory.contains("pct") || entryCategory.contains("percentage")) {
                    matches = true
                }
                // For efficiency, match "efficiency"
                else if category == .efficiency && entryCategory.contains("efficiency") {
                    matches = true
                }
                // For turnovers, match "turnovers" or "turnover"
                else if category == .turnovers && entryCategory.contains("turnover") {
                    matches = true
                }
                
                return matches
            }
            
            // Map to domain models and apply limit
            leaders = try filteredEntries
                .prefix(limit)
                .map { try $0.player.toDomain() }
            
            // Persist to cache
            if !leaders.isEmpty {
                cacheService.set(leaders, forKey: cacheKey, expiration: 600) // 10 minutes cache
            }
            
            // Persist to writable local data source if available
            if let writableDataSource = localDataSource as? WritableLocalDataSource {
                try writableDataSource.savePlayers(remoteData)
            }
            
            return leaders
        } catch {
            // Remote failed - fall back to local data source
            // Note: Local data source may not have league leaders structure,
            // so we'll try to get all players and filter locally as fallback
            if let localData = try localDataSource.loadPlayers() {
                let decoder = JSONDecoder()
                let playerDTOs = try decoder.decode([PlayerDTO].self, from: localData)
                let allPlayers = try playerDTOs.map { try $0.toDomain() }
                
                // Filter players with stats in the requested category and sort by value
                let playersWithStats = allPlayers.compactMap { player -> (Player, Double)? in
                    guard let stat = player.statistic(for: category) else {
                        return nil
                    }
                    return (player, stat.value)
                }
                
                // Sort by stat value descending and take top N
                leaders = playersWithStats
                    .sorted { $0.1 > $1.1 }
                    .prefix(limit)
                    .map { $0.0 }
                
                // Cache the local data
                if !leaders.isEmpty {
                    cacheService.set(leaders, forKey: cacheKey, expiration: 600)
                }
                
                return leaders
            }
            
            // Both remote and local failed - throw error
            throw error
        }
    }
}
