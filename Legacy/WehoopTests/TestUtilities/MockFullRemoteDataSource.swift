//
//  MockFullRemoteDataSource.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import Foundation
@testable import Wehoop

/// Mock remote data source that implements all specialized protocols
/// Used for testing protocol capability checks in repositories
class MockFullRemoteDataSource: RemoteDataSource, PlayerProfileDataSource, TeamProfileDataSource, LeagueDataSource {
  func fetchGame(gameId: String) async throws -> Data {
    return Data()
  }
  
    private let bundle: Bundle
    private let simulatedDelay: TimeInterval
    var fetchPlayerProfileCalled = false
    var fetchTeamProfileCalled = false
    var fetchTeamRosterCalled = false
    var fetchLeagueLeadersCalled = false
    var fetchStandingsCalled = false
    
    init(bundle: Bundle? = nil, simulatedDelay: TimeInterval = 0.01) {
        self.bundle = bundle ?? Bundle.mockDataBundle
        self.simulatedDelay = simulatedDelay
    }
    
    // MARK: - RemoteDataSource
    
  func fetchGames(date: Date?) async throws -> Data {
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        guard let url = bundle.findResource(name: "games", extension: "json", subdirectory: "MockData") else {
            throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "games.json not found"])
        }
        
        return try Data(contentsOf: url)
    }
    
    func fetchPlayers() async throws -> Data {
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        guard let url = bundle.findResource(name: "players", extension: "json", subdirectory: "MockData") else {
            throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "players.json not found"])
        }
        
        return try Data(contentsOf: url)
    }
    
    func fetchTeams() async throws -> Data {
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        guard let url = bundle.findResource(name: "teams", extension: "json", subdirectory: "MockData") else {
            throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "teams.json not found"])
        }
        
        return try Data(contentsOf: url)
    }
    
    func fetchBoxScore(gameId: String) async throws -> Data {
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        guard let url = bundle.findResource(name: "boxscores", extension: "json", subdirectory: "MockData") else {
            throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "boxscores.json not found"])
        }
        
        let data = try Data(contentsOf: url)
        
        // Parse and filter by gameId
        if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let boxScoreDict = jsonArray.first(where: { ($0["gameId"] as? String) == gameId }) {
            var boxScoreData = boxScoreDict
            boxScoreData.removeValue(forKey: "gameId")
            return try JSONSerialization.data(withJSONObject: boxScoreData)
        }
        
        throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "BoxScore not found for gameId: \(gameId)"])
    }
    
    // MARK: - PlayerProfileDataSource
    
    func fetchPlayerProfile(playerId: String) async throws -> Data {
        fetchPlayerProfileCalled = true
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        // Load all players and find the one matching the ID
        let playersData = try await fetchPlayers()
        let decoder = JSONDecoder()
        let playerDTOs = try decoder.decode([PlayerDTO].self, from: playersData)
        
        guard let playerDTO = playerDTOs.first(where: { $0.id == playerId }) else {
            throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Player not found: \(playerId)"])
        }
        
        let encoder = JSONEncoder()
        return try encoder.encode(playerDTO)
    }
    
    // MARK: - TeamProfileDataSource
    
    func fetchTeamProfile(teamId: String) async throws -> Data {
        fetchTeamProfileCalled = true
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        // Load all teams and find the one matching the ID
        let teamsData = try await fetchTeams()
        let decoder = JSONDecoder()
        let teamDTOs = try decoder.decode([TeamDTO].self, from: teamsData)
        
        guard let teamDTO = teamDTOs.first(where: { $0.id == teamId }) else {
            throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Team not found: \(teamId)"])
        }
        
        let encoder = JSONEncoder()
        return try encoder.encode(teamDTO)
    }
    
    func fetchTeamRoster(teamId: String) async throws -> Data {
        fetchTeamRosterCalled = true
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        // Load all players and filter by team
        let playersData = try await fetchPlayers()
        let decoder = JSONDecoder()
        let playerDTOs = try decoder.decode([PlayerDTO].self, from: playersData)
        
        let teamPlayers = playerDTOs.filter { $0.team.id == teamId }
        
        let encoder = JSONEncoder()
        return try encoder.encode(teamPlayers)
    }
    
    // MARK: - LeagueDataSource
    
    func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
        fetchLeagueLeadersCalled = true
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        // Return empty array for now (can be enhanced with actual leader data)
        struct LeaderEntry: Codable {
            let category: String
            let player: PlayerDTO
        }
        
        let emptyLeaders: [LeaderEntry] = []
        let encoder = JSONEncoder()
        return try encoder.encode(emptyLeaders)
    }
    
    func fetchStandings() async throws -> Data {
        fetchStandingsCalled = true
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        // Return teams data as standings (can be enhanced with actual standings data)
        return try await fetchTeams()
    }
}
