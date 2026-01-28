//
//  JSONLocalDataSource.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// JSON file-based implementation of LocalDataSource
class JSONLocalDataSource: LocalDataSource {
    private let bundle: Bundle
    
    init(bundle: Bundle? = nil) {
        // Use provided bundle, or find the bundle containing MockData resources
        self.bundle = bundle ?? Bundle.mockDataBundle
    }
    
    func loadGames() throws -> Data? {
        guard let url = bundle.findResource(name: "games", extension: "json", subdirectory: "MockData") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
    
    func loadPlayers() throws -> Data? {
        guard let url = bundle.findResource(name: "players", extension: "json", subdirectory: "MockData") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
    
    func loadTeams() throws -> Data? {
        guard let url = bundle.findResource(name: "teams", extension: "json", subdirectory: "MockData") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
    
    func loadBoxScore(gameId: String) throws -> Data? {
        guard let url = bundle.findResource(name: "boxscores", extension: "json", subdirectory: "MockData") else {
            return nil
        }
        
        let data = try Data(contentsOf: url)
        
        // Parse and filter by gameId, then remove gameId field before returning
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let boxScoreDict = jsonArray.first(where: { ($0["gameId"] as? String) == gameId }) {
            // Create a new dictionary without the gameId field
            var boxScoreData = boxScoreDict
            boxScoreData.removeValue(forKey: "gameId")
            return try? JSONSerialization.data(withJSONObject: boxScoreData)
        }
        
        return nil
    }
}
