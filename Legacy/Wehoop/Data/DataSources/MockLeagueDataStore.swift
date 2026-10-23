//
//  MockLeagueDataStore.swift
//  Unrivaled
//
//  Created by E on 1/2/26.
//

import Foundation

/// Mock implementation of LeagueDataSource for development
/// Simulates network delays and loads data from local JSON files
class MockLeagueLeadersDataStore: LeagueDataSource {
    private let bundle: Bundle
    private let simulatedDelay: TimeInterval
    
    init(bundle: Bundle? = nil, simulatedDelay: TimeInterval = 0.5) {
        // Use provided bundle, or find the bundle containing MockData resources
        self.bundle = bundle ?? Bundle.mockDataBundle
        self.simulatedDelay = simulatedDelay
    }
    
    func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        guard let url = bundle.findResource(name: "league_leaders", extension: "json", subdirectory: "MockData") else {
            throw NSError(domain: "MockLeagueDataStoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "league_leaders.json not found in bundle: \(bundle.bundlePath)"])
        }
        
        // Load raw API response format
        let rawData = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let leadersResponse = try decoder.decode(SportradarLeagueLeadersDTO.self, from: rawData)
        
        // Fetch teams for player team references (same as real data source)
        guard let teamsUrl = bundle.findResource(name: "teams", extension: "json", subdirectory: "MockData") else {
            throw NSError(domain: "MockLeagueDataStoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "teams.json not found in bundle: \(bundle.bundlePath)"])
        }
        let teamsData = try Data(contentsOf: teamsUrl)
        let teamDTOs = try decoder.decode([TeamDTO].self, from: teamsData)
        let teamsDict = Dictionary(uniqueKeysWithValues: teamDTOs.map { ($0.id, $0) })
        
        // Transform using the same mapper as the real data source
        let leaders = SportradarDTOMapper.mapLeagueLeaders(leadersResponse, teams: teamsDict)
        
        // Encode as array of dictionaries with category and player (same format as real data source)
        struct LeaderEntry: Codable {
            let category: String
            let player: PlayerDTO
        }
        
        let leaderEntries = leaders.map { LeaderEntry(category: $0.category, player: $0.player) }
        let encoder = JSONEncoder()
        return try encoder.encode(leaderEntries)
    }
    
    func fetchStandings() async throws -> Data {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        guard let url = bundle.findResource(name: "standings", extension: "json", subdirectory: "MockData") else {
            // Fallback to teams.json if standings.json doesn't exist
            guard let teamsUrl = bundle.findResource(name: "teams", extension: "json", subdirectory: "MockData") else {
                throw NSError(domain: "MockLeagueDataStoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "standings.json or teams.json not found in bundle: \(bundle.bundlePath)"])
            }
            return try Data(contentsOf: teamsUrl)
        }
        
        return try Data(contentsOf: url)
    }
}
