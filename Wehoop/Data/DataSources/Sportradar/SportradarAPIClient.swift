//
//  SportradarAPIClient.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Client for building Sportradar API endpoint URLs
/// 
/// URL Pattern: {base}/{access}/{version}/{language}/{resource}/{path}/{endpoint}
/// Example: https://api.sportradar.com/unrivaled/trial/v8/en/league/2026/01/16/changes.json
class SportradarAPIClient {
    private let apiConfiguration: APIConfiguration
    private let accessLevel: SportradarEndpoints.AccessLevel
    private let language: SportradarEndpoints.Language
    
    /// Initialize the API client
    /// - Parameters:
    ///   - apiConfiguration: API configuration with base URL and credentials
    ///   - accessLevel: API access level (defaults to .trial)
    ///   - language: Response language (defaults to .english)
    init(
        apiConfiguration: APIConfiguration,
        accessLevel: SportradarEndpoints.AccessLevel = .trial,
        language: SportradarEndpoints.Language = .english
    ) {
        self.apiConfiguration = apiConfiguration
        self.accessLevel = accessLevel
        self.language = language
    }
    
    // MARK: - URL Building Helpers
    
    /// Build base path for a resource type
    /// - Parameter resource: Resource type (league, teams, etc.)
    /// - Returns: Base path string
    private func basePath(for resource: SportradarEndpoints.ResourceType) -> String {
        return "\(accessLevel.rawValue)/\(apiConfiguration.apiVersion)/\(language.rawValue)/\(resource.rawValue)"
    }
    
    /// Build full URL for an endpoint
    /// - Parameters:
    ///   - resource: Resource type
    ///   - pathComponents: Additional path components (e.g., date, IDs)
    ///   - endpoint: Endpoint file name
    /// - Returns: Full URL string
    private func buildURL(
        resource: SportradarEndpoints.ResourceType,
        pathComponents: [String] = [],
        endpoint: SportradarEndpoints.Endpoint
    ) -> String {
        let basePath = basePath(for: resource)
        let path = pathComponents.isEmpty ? basePath : "\(basePath)/\(pathComponents.joined(separator: "/"))"
        let fullPath = "\(path)/\(endpoint.endpointPath)"
        
        let base = apiConfiguration.baseURL.hasSuffix("/") 
            ? String(apiConfiguration.baseURL.dropLast()) 
            : apiConfiguration.baseURL
        
        return "\(base)/\(fullPath)"
    }
    
    // MARK: - Daily Endpoints
    
    /// Daily Change Log - IDs and timestamps for modified data
    /// - Parameter date: Date for the change log (format: YYYY/MM/DD)
    /// - Returns: Full URL string
    func dailyChanges(date: Date) -> String {
        let dateString = formatDate(date)
        return buildURL(
            resource: .league,
            pathComponents: [dateString],
            endpoint: .dailyChanges
        )
    }
    
    /// Daily Injuries - Details for all injuries updated on a date
    /// - Parameter date: Date for injuries (format: YYYY/MM/DD)
    /// - Returns: Full URL string
    func dailyInjuries(date: Date) -> String {
        let dateString = formatDate(date)
        return buildURL(
            resource: .league,
            pathComponents: [dateString],
            endpoint: .dailyInjuries
        )
    }
    
    /// Daily Schedule - Game details for league-defined day
    /// - Parameter date: Date for schedule (format: YYYY/MM/DD)
    /// - Returns: Full URL string
    func dailySchedule(date: Date) -> String {
        let dateString = formatDate(date)
        return buildURL(
            resource: .games,
            pathComponents: [dateString],
            endpoint: .dailySchedule
        )
    }
    
    /// Daily Transfers - Information for transfers added/edited during day
    /// - Parameter date: Date for transfers (format: YYYY/MM/DD)
    /// - Returns: Full URL string
    func dailyTransfers(date: Date) -> String {
        let dateString = formatDate(date)
        return buildURL(
            resource: .league,
            pathComponents: [dateString],
            endpoint: .dailyTransfers
        )
    }
    
    // MARK: - Game Endpoints
    
    /// Game Boxscore - Team scores by quarter and leader statistics
    /// 
    /// Example URL: https://api.sportradar.com/unrivaled/trial/v8/en/games/838316ea-ab7b-4581-a1dd-74229d1970d5/boxscore.json
    /// - Parameter gameId: Unique game identifier (e.g., "838316ea-ab7b-4581-a1dd-74229d1970d5")
    /// - Returns: Full URL string following pattern: {base}/{access}/{version}/{language}/games/{gameId}/boxscore.json
    func gameBoxscore(gameId: String) -> String {
        return buildURL(
            resource: .games,
            pathComponents: [gameId],
            endpoint: .gameBoxscore
        )
    }
    
    /// Game Summary - Top-level boxscore with detailed stats
    /// - Parameter gameId: Unique game identifier
    /// - Returns: Full URL string
    func gameSummary(gameId: String) -> String {
        return buildURL(
            resource: .games,
            pathComponents: [gameId],
            endpoint: .gameSummary
        )
    }
    
    /// Game Play-by-Play - Detailed real-time game events
    /// - Parameter gameId: Unique game identifier
    /// - Returns: Full URL string
    func gamePlayByPlay(gameId: String) -> String {
        return buildURL(
            resource: .games,
            pathComponents: [gameId],
            endpoint: .gamePlayByPlay
        )
    }
    
    // MARK: - Team Endpoints
    
    /// Teams - Complete list of active teams
    /// - Returns: Full URL string
    func teams() -> String {
        return buildURL(
            resource: .league,
            endpoint: .teams
        )
    }
    
    /// Team Profile - Top-level team information and roster
    /// - Parameter teamId: Unique team identifier
    /// - Returns: Full URL string
    func teamProfile(teamId: String) -> String {
        return buildURL(
            resource: .teams,
            pathComponents: [teamId],
            endpoint: .teamProfile
        )
    }
    
    /// Team Roster - Full roster of active players
    /// - Parameter teamId: Unique team identifier
    /// - Returns: Full URL string
    func teamRoster(teamId: String) -> String {
        return buildURL(
            resource: .teams,
            pathComponents: [teamId],
            endpoint: .teamRoster
        )
    }
    
    // MARK: - Player Endpoints
    
    /// Player Profile - Biographical information and seasonal statistics
    /// - Parameter playerId: Unique player identifier
    /// - Returns: Full URL string
    func playerProfile(playerId: String) -> String {
        return buildURL(
            resource: .players,
            pathComponents: [playerId],
            endpoint: .playerProfile
        )
    }
    
    // MARK: - League Endpoints
    
    /// League Hierarchy - League and team identification
    /// - Returns: Full URL string
    func leagueHierarchy() -> String {
        return buildURL(
            resource: .league,
            endpoint: .leagueHierarchy
        )
    }
    
    /// League Leaders - Leader information for various categories
    /// - Parameters:
    ///   - seasonYear: Season year (e.g., "2026")
    ///   - seasonType: Season type (e.g., "REG" for regular season)
    /// - Returns: Full URL string
    func leagueLeaders(seasonYear: String, seasonType: String) -> String {
        // Path structure: seasons/{year}/{type}/leaders.json
        // Note: This endpoint uses "seasons" as the base path, not "league"
        let basePath = "\(accessLevel.rawValue)/\(apiConfiguration.apiVersion)/\(language.rawValue)/seasons/\(seasonYear)/\(seasonType)"
        let fullPath = "\(basePath)/\(SportradarEndpoints.Endpoint.leagueLeaders.endpointPath)"
        
        let base = apiConfiguration.baseURL.hasSuffix("/") 
            ? String(apiConfiguration.baseURL.dropLast()) 
            : apiConfiguration.baseURL
        
        return "\(base)/\(fullPath)"
    }
    
    /// Standings - Detailed team records across categories
    /// - Returns: Full URL string
    func standings() -> String {
        return buildURL(
            resource: .league,
            endpoint: .standings
        )
    }
    
    /// Rankings - League ranking for each team
    /// - Returns: Full URL string
    func rankings() -> String {
        return buildURL(
            resource: .league,
            endpoint: .rankings
        )
    }
    
    /// Seasonal Statistics - Complete team and player statistics
    /// - Parameters:
    ///   - seasonId: Season identifier
    ///   - seasonType: Type of season (regular, playoffs, etc.)
    /// - Returns: Full URL string
    func seasonalStatistics(seasonId: String, seasonType: String? = nil) -> String {
        var pathComponents = [seasonId]
        if let seasonType = seasonType {
            pathComponents.append(seasonType)
        }
        return buildURL(
            resource: .league,
            pathComponents: pathComponents,
            endpoint: .seasonalStatistics
        )
    }
    
    // MARK: - Season Endpoints
    
    /// Seasons - List of all available seasons
    /// - Returns: Full URL string
    func seasons() -> String {
        return buildURL(
            resource: .league,
            endpoint: .seasons
        )
    }
    
    // MARK: - Series Endpoints
    
    /// Series Schedule - Schedule details for every match-up in a series
    /// - Parameter seriesId: Unique series identifier
    /// - Returns: Full URL string
    func seriesSchedule(seriesId: String) -> String {
        return buildURL(
            resource: .series,
            pathComponents: [seriesId],
            endpoint: .seriesSchedule
        )
    }
    
    /// Series Statistics - Detailed team and player statistics for a series
    /// - Parameter seriesId: Unique series identifier
    /// - Returns: Full URL string
    func seriesStatistics(seriesId: String) -> String {
        return buildURL(
            resource: .series,
            pathComponents: [seriesId],
            endpoint: .seriesStatistics
        )
    }
    
    // MARK: - Tournament Endpoints
    
    /// Tournament List - Summarized list of all tournaments
    /// - Parameter seasonId: Season identifier
    /// - Returns: Full URL string
    func tournamentList(seasonId: String) -> String {
        return buildURL(
            resource: .tournaments,
            pathComponents: [seasonId],
            endpoint: .tournamentList
        )
    }
    
    /// Tournament Schedule - Date, time, location for tournament match-ups
    /// - Parameter tournamentId: Unique tournament identifier
    /// - Returns: Full URL string
    func tournamentSchedule(tournamentId: String) -> String {
        return buildURL(
            resource: .tournaments,
            pathComponents: [tournamentId],
            endpoint: .tournamentSchedule
        )
    }
    
    /// Tournament Summary - Tournament information including location and status
    /// - Parameter tournamentId: Unique tournament identifier
    /// - Returns: Full URL string
    func tournamentSummary(tournamentId: String) -> String {
        return buildURL(
            resource: .tournaments,
            pathComponents: [tournamentId],
            endpoint: .tournamentSummary
        )
    }
    
    // MARK: - Injury Endpoints
    
    /// Injuries - Information concerning all active player injuries
    /// - Returns: Full URL string
    func injuries() -> String {
        return buildURL(
            resource: .league,
            endpoint: .injuries
        )
    }
    
    // MARK: - Schedule Endpoints
    
    /// Schedule - Date, time, location for every match-up in full season
    /// - Parameter seasonId: Season identifier
    /// - Returns: Full URL string
    func schedule(seasonId: String) -> String {
        return buildURL(
            resource: .league,
            pathComponents: [seasonId],
            endpoint: .dailySchedule // Reusing schedule endpoint
        )
    }
    
    // MARK: - Helper Methods
    
    /// Format date as YYYY/MM/DD for API paths
    /// - Parameter date: Date to format
    /// - Returns: Formatted date string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}
