//
//  MockRemoteDataSource.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Mock implementation of RemoteDataSource for development
/// Simulates network delays and loads data from local JSON files
class MockRemoteDataSource: RemoteDataSource {
    private let bundle: Bundle
    private let simulatedDelay: TimeInterval
    
    init(bundle: Bundle? = nil, simulatedDelay: TimeInterval = 0.5) {
        // Use provided bundle, or find the bundle containing MockData resources
        self.bundle = bundle ?? Bundle.mockDataBundle
        self.simulatedDelay = simulatedDelay
    }
    
    func fetchGames(date: Date?) async throws -> Data {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        guard let url = bundle.findResource(name: "games", extension: "json", subdirectory: "MockData") else {
            throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "games.json not found in bundle: \(bundle.bundlePath)"])
        }
        
        // For mock, return all games (date filtering would be handled by repository if needed)
        return try Data(contentsOf: url)
    }
    
    func fetchGames() async throws -> Data {
        return try await fetchGames(date: nil)
    }
    
    func fetchPlayers() async throws -> Data {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        guard let url = bundle.findResource(name: "players", extension: "json", subdirectory: "MockData") else {
            throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "players.json not found in bundle: \(bundle.bundlePath)"])
        }
        
        return try Data(contentsOf: url)
    }
    
    func fetchTeams() async throws -> Data {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        guard let url = bundle.findResource(name: "teams", extension: "json", subdirectory: "MockData") else {
            throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "teams.json not found in bundle: \(bundle.bundlePath)"])
        }
        
        return try Data(contentsOf: url)
    }
    
    func fetchBoxScore(gameId: String) async throws -> Data {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        guard let url = bundle.findResource(name: "boxscores", extension: "json", subdirectory: "MockData") else {
            throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "boxscores.json not found in bundle: \(bundle.bundlePath)"])
        }
        
        let data = try Data(contentsOf: url)
        
        // Parse and filter by gameId, then remove gameId field before returning
        if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let boxScoreDict = jsonArray.first(where: { ($0["gameId"] as? String) == gameId }) {
            // Create a new dictionary without the gameId field
            var boxScoreData = boxScoreDict
            boxScoreData.removeValue(forKey: "gameId")
            return try JSONSerialization.data(withJSONObject: boxScoreData)
        }
        
        throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "BoxScore not found for gameId: \(gameId)"])
    }
    
    func fetchGame(gameId: String) async throws -> Data {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        guard let url = bundle.findResource(name: "games", extension: "json", subdirectory: "MockData") else {
            throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "games.json not found in bundle: \(bundle.bundlePath)"])
        }
        
        let data = try Data(contentsOf: url)
        
        // Parse and find game by ID
        if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let gameDict = jsonArray.first(where: { ($0["id"] as? String) == gameId }) {
            return try JSONSerialization.data(withJSONObject: gameDict)
        }
        
        throw NSError(domain: "MockRemoteDataSourceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Game not found for gameId: \(gameId)"])
    }
}
