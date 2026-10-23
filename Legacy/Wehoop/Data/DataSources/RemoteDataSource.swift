//
//  RemoteDataSource.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

// MARK: - Base Protocol

/// Core remote data source operations
/// All remote data sources must implement these basic operations
protocol RemoteDataSource {
    /// Fetch games, optionally filtered by date
    /// - Parameter date: Optional date to filter games. If nil, returns all games.
    /// - Returns: Games data encoded as JSON
    func fetchGames(date: Date?) async throws -> Data
    
    /// Fetch all games (backward compatibility - calls fetchGames(date: nil))
//    func fetchGames() async throws -> Data
    
    /// Fetch all players
    func fetchPlayers() async throws -> Data
    
    /// Fetch all teams
    func fetchTeams() async throws -> Data
    
    /// Fetch box score for a specific game
    /// - Parameter gameId: Unique game identifier
    func fetchBoxScore(gameId: String) async throws -> Data
    
    /// Fetch full game details by game ID (including box score)
    /// - Parameter gameId: Unique game identifier
    /// - Returns: Full game data encoded as JSON (GameDTO)
    func fetchGame(gameId: String) async throws -> Data
}

// MARK: - Specialized Protocols

/// Data source that supports fetching individual player profiles
/// Implement this protocol if your data source can fetch detailed player information by ID
protocol PlayerProfileDataSource {
    /// Fetch detailed player profile by player ID
    /// - Parameter playerId: Unique player identifier
    /// - Returns: PlayerDTO encoded as Data
    func fetchPlayerProfile(playerId: String) async throws -> Data
}

/// Data source that supports fetching individual team profiles and rosters
/// Implement this protocol if your data source can fetch detailed team information by ID
protocol TeamProfileDataSource {
    /// Fetch detailed team profile by team ID
    /// - Parameter teamId: Unique team identifier
    /// - Returns: TeamDTO encoded as Data
    func fetchTeamProfile(teamId: String) async throws -> Data
    
    /// Fetch team roster (list of players) by team ID
    /// - Parameter teamId: Unique team identifier
    /// - Returns: Array of PlayerDTO encoded as Data
    func fetchTeamRoster(teamId: String) async throws -> Data
}

/// Data source that supports fetching league-wide statistics and data
/// Implement this protocol if your data source can fetch league leaders and standings
protocol LeagueDataSource {
    /// Fetch league leaders for various statistical categories
    /// - Parameters:
    ///   - seasonYear: Season year (e.g., "2026"). Defaults to current year.
    ///   - seasonType: Season type (e.g., "REG" for regular season). Defaults to "REG".
    /// - Returns: Array of leader entries (category + PlayerDTO) encoded as Data
    func fetchLeagueLeaders(seasonYear: String?, seasonType: String) async throws -> Data
    
    /// Fetch current league standings
    /// - Returns: Array of TeamDTO with updated win/loss records encoded as Data
    func fetchStandings() async throws -> Data
}

// MARK: - Convenience Type Alias

/// Full-featured remote data source with all capabilities
/// This type alias represents a data source that implements all specialized protocols
typealias FullRemoteDataSource = RemoteDataSource & PlayerProfileDataSource & TeamProfileDataSource & LeagueDataSource
