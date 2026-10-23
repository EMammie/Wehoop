//
//  MockLeagueLeadersRepository.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import Foundation
@testable import Wehoop

/// Mock implementation of LeagueLeadersRepository for testing
/// Similar to MockFullRemoteDataSource - supports bundle loading and simulated delays
class MockLeagueLeadersRepository: LeagueLeadersRepository {
    private let bundle: Bundle?
    private let simulatedDelay: TimeInterval
    
    // Tracking properties
    var getLeagueLeadersCallCount = 0
    var lastCategory: StatCategory?
    var lastLimit: Int?
    
    // Error simulation
    var getLeagueLeadersError: Error?
    
    // Custom data override (takes precedence over bundle loading)
    var customLeaders: [Player]?
    
    // Default leaders (used if no bundle or custom data)
    var defaultLeaders: [Player] = []
    
    init(bundle: Bundle? = nil, simulatedDelay: TimeInterval = 0.01) {
        self.bundle = bundle ?? Bundle.mockDataBundle
        self.simulatedDelay = simulatedDelay
    }
    
    func getLeagueLeaders(category: StatCategory, limit: Int) async throws -> [Player] {
        getLeagueLeadersCallCount += 1
        lastCategory = category
        lastLimit = limit
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        // Check for error simulation
        if let error = getLeagueLeadersError {
            throw error
        }
        
        // Use custom leaders if provided
        if let customLeaders = customLeaders {
            return filterAndLimit(players: customLeaders, category: category, limit: limit)
        }
        
        // Try to load from bundle if available
        if let bundle = bundle {
            if let leaders = try? loadLeadersFromBundle(bundle: bundle, category: category, limit: limit) {
                return leaders
            }
        }
        
        // Fall back to default leaders
        return filterAndLimit(players: defaultLeaders, category: category, limit: limit)
    }
    
    // MARK: - Helper Methods
    
    /// Load leaders from JSON file in bundle
    private func loadLeadersFromBundle(bundle: Bundle, category: StatCategory, limit: Int) throws -> [Player] {
        // Try to load from league_leaders.json if it exists
        if let url = bundle.findResource(name: "league_leaders", extension: "json", subdirectory: "MockData") {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            // Decode LeaderEntry structure
            struct LeaderEntry: Codable {
                let category: String
                let player: PlayerDTO
            }
            
            let leaderEntries = try decoder.decode([LeaderEntry].self, from: data)
            
            // Filter by requested category
            let apiCategoryString = category.apiCategoryString
            let filteredEntries = leaderEntries.filter { $0.category.lowercased() == apiCategoryString.lowercased() }
            
            // Map to domain models and apply limit
            let players = try filteredEntries
                .prefix(limit)
                .map { try $0.player.toDomain() }
            
            return players
        }
        
        // If league_leaders.json doesn't exist, try loading from players.json
        // and filter/sort by the requested category
        if let url = bundle.findResource(name: "players", extension: "json", subdirectory: "MockData") {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let playerDTOs = try decoder.decode([PlayerDTO].self, from: data)
            let players = try playerDTOs.map { try $0.toDomain() }
            
            // Filter and sort by category
            return filterAndLimit(players: players, category: category, limit: limit)
        }
        
        throw NSError(
            domain: "MockLeagueLeadersRepositoryError",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "league_leaders.json or players.json not found in bundle"]
        )
    }
    
    /// Filter players by category and apply limit
    private func filterAndLimit(players: [Player], category: StatCategory, limit: Int) -> [Player] {
        // Filter players with stats in the requested category and sort by value
        let playersWithStats = players.compactMap { player -> (Player, Double)? in
            guard let stat = player.statistic(for: category) else {
                return nil
            }
            return (player, stat.value)
        }
        
        // Sort by stat value descending and take top N
        return playersWithStats
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }
}
