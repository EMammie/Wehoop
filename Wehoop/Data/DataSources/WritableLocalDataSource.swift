//
//  WritableLocalDataSource.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Protocol for writable local data source operations
/// Extends LocalDataSource with save methods for persisting data
protocol WritableLocalDataSource: LocalDataSource {
    /// Save games data to local storage
    /// - Parameter data: The games data to save
    /// - Throws: Error if persistence fails
    func saveGames(_ data: Data) throws
    
    /// Save players data to local storage
    /// - Parameter data: The players data to save
    /// - Throws: Error if persistence fails
    func savePlayers(_ data: Data) throws
    
    /// Save teams data to local storage
    /// - Parameter data: The teams data to save
    /// - Throws: Error if persistence fails
    func saveTeams(_ data: Data) throws
    
    /// Save box score data to local storage
    /// - Parameters:
    ///   - data: The box score data to save
    ///   - gameId: The game ID associated with the box score
    /// - Throws: Error if persistence fails
    func saveBoxScore(_ data: Data, gameId: String) throws
}
