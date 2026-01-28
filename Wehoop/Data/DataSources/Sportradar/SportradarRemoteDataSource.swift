//
//  SportradarRemoteDataSource.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

// MARK: - Sportradar Remote Data Source Errors

/// Custom error type for SportradarRemoteDataSource operations
enum SportradarRemoteDataSourceError: LocalizedError {
    // URL Issues
    case invalidURL(String)
    case malformedURL(String)
    
    // Request Errors
    case networkError(Error)
    case httpError(statusCode: Int, message: String?)
    case requestTimeout
    case noConnection
    
    // Parsing Issues
    case decodingError(Error, endpoint: String)
    case mappingError(Error, endpoint: String)
    case invalidResponseFormat(endpoint: String)
    case missingRequiredData(String)
    
    // Data Issues
    case emptyResponse(endpoint: String)
    case boxScoreNotFound(gameId: String)
    
    var errorDescription: String? {
        switch self {
        // URL Issues
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .malformedURL(let url):
            return "Malformed URL: \(url)"
        
        // Request Errors
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode, let message):
            return "HTTP error \(statusCode): \(message ?? "No error details")"
        case .requestTimeout:
            return "Request timed out"
        case .noConnection:
            return "No network connection available"
        
        // Parsing Issues
        case .decodingError(let error, let endpoint):
            return "Failed to decode response from \(endpoint): \(error.localizedDescription)"
        case .mappingError(let error, let endpoint):
            return "Failed to map data from \(endpoint): \(error.localizedDescription)"
        case .invalidResponseFormat(let endpoint):
            return "Invalid response format from \(endpoint)"
        case .missingRequiredData(let field):
            return "Missing required data: \(field)"
        
        // Data Issues
        case .emptyResponse(let endpoint):
            return "Empty response from \(endpoint)"
        case .boxScoreNotFound(let gameId):
            return "BoxScore not found for game: \(gameId)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .httpError(let statusCode, _):
            switch statusCode {
            case 400:
                return "Bad request - check API parameters"
            case 401:
                return "Unauthorized - check API key"
            case 403:
                return "Forbidden - API key may not have access"
            case 404:
                return "Resource not found"
            case 429:
                return "Rate limit exceeded - too many requests"
            case 500...599:
                return "Server error - Sportradar API issue"
            default:
                return "HTTP error \(statusCode)"
            }
        case .noConnection:
            return "Check your internet connection"
        case .requestTimeout:
            return "Request took too long - server may be slow"
        case .decodingError(_, let endpoint):
            return "Response from \(endpoint) doesn't match expected format"
        case .mappingError(_, let endpoint):
            return "Data from \(endpoint) couldn't be converted to app format"
        default:
            return nil
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .httpError(let statusCode, _):
            switch statusCode {
            case 401, 403:
                return "Verify your API key in Config.xcconfig is correct and has proper permissions"
            case 429:
                return "Wait a moment and try again, or implement rate limiting"
            case 500...599:
                return "This appears to be a Sportradar API issue. Try again later"
            default:
                return "Check the API endpoint and parameters"
            }
        case .noConnection:
            return "Check your internet connection and try again"
        case .requestTimeout:
            return "Try again in a moment, or check your network connection"
        case .decodingError, .mappingError, .invalidResponseFormat:
            return "This may indicate an API response format change. Check Sportradar API documentation"
        default:
            return nil
        }
    }
    
    /// Extract HTTP status code if available
    var statusCode: Int? {
        if case .httpError(let code, _) = self {
            return code
        }
        return nil
    }
    
    /// Check if error is retryable
    var isRetryable: Bool {
        switch self {
        case .requestTimeout, .noConnection:
            return true
        case .httpError(let statusCode, _):
            // Retry on 5xx errors and 429 (rate limit)
            return statusCode >= 500 || statusCode == 429
        default:
            return false
        }
    }
}

/// Sportradar API implementation of RemoteDataSource
/// Fetches data from Sportradar Unrivaled API and transforms it to app DTO format
/// Implements all specialized protocols for full API coverage
class SportradarRemoteDataSource: RemoteDataSource, PlayerProfileDataSource, TeamProfileDataSource, LeagueDataSource {
    private let networkService: NetworkService
    private let apiClient: SportradarAPIClient
    
    /// Initialize the Sportradar remote data source
    /// - Parameters:
    ///   - networkService: Network service for making HTTP requests
    ///   - apiClient: Sportradar API client for building endpoint URLs
    init(networkService: NetworkService, apiClient: SportradarAPIClient) {
        self.networkService = networkService
        self.apiClient = apiClient
    }
    
    // MARK: - RemoteDataSource Implementation
    
    func fetchTeams() async throws -> Data {
        // Build URL using API client
        let url = apiClient.teams()
        
        // Validate URL
        guard URL(string: url) != nil else {
            throw SportradarRemoteDataSourceError.invalidURL(url)
        }
        
        do {
            // Fetch and decode Sportradar response
            let sportradarResponse: SportradarTeamsResponseDTO = try await networkService.request(url)
            
            // Map to app DTOs
            let teamDTOs = SportradarDTOMapper.mapTeams(sportradarResponse)
            
            // Validate we got data
            guard !teamDTOs.isEmpty else {
                throw SportradarRemoteDataSourceError.emptyResponse(endpoint: "teams")
            }
            
            // Encode back to Data for repository
            let encoder = JSONEncoder()
            return try encoder.encode(teamDTOs)
        } catch let error as NetworkError {
            // Map NetworkError to our custom error type
            throw mapNetworkError(error, endpoint: "teams")
        } catch let error as DecodingError {
            throw SportradarRemoteDataSourceError.decodingError(error, endpoint: "teams")
        } catch {
            // Wrap other errors
            if let networkError = error as? NetworkError {
                throw mapNetworkError(networkError, endpoint: "teams")
            }
            throw SportradarRemoteDataSourceError.networkError(error)
        }
    }
    
    func fetchPlayers() async throws -> Data {
        // Note: Sportradar doesn't have a "list all players" endpoint
        // This would typically require fetching from teams/rosters or using a different approach
        // For now, return empty array (allows app to continue with local/cached data)
        let emptyPlayers: [PlayerDTO] = []
        let encoder = JSONEncoder()
        return try encoder.encode(emptyPlayers)
    }
    
    func fetchGames(date: Date? = nil) async throws -> Data {
        // Use provided date, or fall back to this past Monday's games (for testing)
        let calendar = Calendar.current
        let targetDate: Date
        
        if let date = date {
            targetDate = date
        } else {
            // Fallback: Find this past Monday
            let today = Date()
            let weekday = calendar.component(.weekday, from: today)
            let daysFromMonday = (weekday + 5) % 7 // Convert Sunday=1 to Monday=0
            targetDate = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        }
        
        let url = apiClient.dailySchedule(date: targetDate)
        
        // Validate URL
        guard URL(string: url) != nil else {
            throw SportradarRemoteDataSourceError.invalidURL(url)
        }
        
        do {
            // Fetch schedule data
            let scheduleData: Data = try await networkService.request(url)
            let decoder = JSONDecoder()
            
            // Try to decode as schedule response
            do {
                let schedule = try decoder.decode(SportradarScheduleDTO.self, from: scheduleData)
                
                guard let games = schedule.games, !games.isEmpty else {
                    // Empty schedule is valid - return empty array
                    let emptyGames: [GameDTO] = []
                    let encoder = JSONEncoder()
                    return try encoder.encode(emptyGames)
                }
                
                // Fetch teams for mapping (needed for GameDTO)
                let teamsData = try await fetchTeams()
                let teamsDecoder = JSONDecoder()
                let teamDTOs = try teamsDecoder.decode([TeamDTO].self, from: teamsData)
                let teamsDict = Dictionary(uniqueKeysWithValues: teamDTOs.map { ($0.id, $0) })
                
                // Map games using mapper
                do {
                    let gameDTOs = try SportradarDTOMapper.mapSchedule(schedule, teams: teamsDict)
                    let encoder = JSONEncoder()
                    return try encoder.encode(gameDTOs)
                } catch {
                    throw SportradarRemoteDataSourceError.mappingError(error, endpoint: "schedule")
                }
            } catch let error as DecodingError {
                throw SportradarRemoteDataSourceError.decodingError(error, endpoint: "schedule")
            }
        } catch let error as SportradarRemoteDataSourceError {
            // Re-throw our custom errors
            throw error
        } catch let error as NetworkError {
            // Map NetworkError to our custom error type
            // For games, we allow fallback to local data, so return empty array
            // But log the error for debugging
            Logger.error("Failed to fetch games: \(error.localizedDescription)")
            let emptyGames: [GameDTO] = []
            let encoder = JSONEncoder()
            return try encoder.encode(emptyGames)
        } catch {
            // Other errors - return empty array to allow fallback
            Logger.error("Unexpected error fetching games: \(error.localizedDescription)")
            let emptyGames: [GameDTO] = []
            let encoder = JSONEncoder()
            return try encoder.encode(emptyGames)
        }
    }
    
    func fetchGames() async throws -> Data {
        return try await fetchGames(date: nil)
    }
    
    func fetchBoxScore(gameId: String) async throws -> Data {
        // Use game summary endpoint (more comprehensive than boxscore)
        let url = apiClient.gameSummary(gameId: gameId)
        
        // Validate URL
        guard URL(string: url) != nil else {
            throw SportradarRemoteDataSourceError.invalidURL(url)
        }
        
        do {
            // Fetch and decode Sportradar response
            let gameSummary: SportradarGameSummaryDTO = try await networkService.request(url)
            
            // Fetch teams for mapping (needed for GameDTO)
            let teamsData = try await fetchTeams()
            let teamsDecoder = JSONDecoder()
            let teamDTOs = try teamsDecoder.decode([TeamDTO].self, from: teamsData)
            let teamsDict = Dictionary(uniqueKeysWithValues: teamDTOs.map { ($0.id, $0) })
            
            // Map to app GameDTO (which includes boxscore)
            let gameDTO: GameDTO
            do {
                gameDTO = try SportradarDTOMapper.mapGameSummary(gameSummary, teams: teamsDict)
            } catch {
                throw SportradarRemoteDataSourceError.mappingError(error, endpoint: "gameSummary")
            }
            
            // Extract boxscore from game
            guard let boxScoreDTO = gameDTO.boxScore else {
                throw SportradarRemoteDataSourceError.boxScoreNotFound(gameId: gameId)
            }
            
            // Encode boxscore to Data
            let encoder = JSONEncoder()
            return try encoder.encode(boxScoreDTO)
        } catch let error as SportradarRemoteDataSourceError {
            // Re-throw our custom errors
            throw error
        } catch let error as NetworkError {
            // Map NetworkError to our custom error type
            throw mapNetworkError(error, endpoint: "gameSummary")
        } catch let error as DecodingError {
            throw SportradarRemoteDataSourceError.decodingError(error, endpoint: "gameSummary")
        } catch {
            throw SportradarRemoteDataSourceError.networkError(error)
        }
    }
    
    func fetchGame(gameId: String) async throws -> Data {
        // Use game summary endpoint to fetch full game details
        let url = apiClient.gameSummary(gameId: gameId)
        
        // Validate URL
        guard URL(string: url) != nil else {
            throw SportradarRemoteDataSourceError.invalidURL(url)
        }
        
        do {
            // Fetch and decode Sportradar response
            let gameSummary: SportradarGameSummaryDTO = try await networkService.request(url)
            
            // Fetch teams for mapping (needed for GameDTO)
            let teamsData = try await fetchTeams()
            let teamsDecoder = JSONDecoder()
            let teamDTOs = try teamsDecoder.decode([TeamDTO].self, from: teamsData)
            let teamsDict = Dictionary(uniqueKeysWithValues: teamDTOs.map { ($0.id, $0) })
            
            // Map to app GameDTO (which includes boxscore and all game details)
            let gameDTO: GameDTO
            do {
                gameDTO = try SportradarDTOMapper.mapGameSummary(gameSummary, teams: teamsDict)
            } catch {
                throw SportradarRemoteDataSourceError.mappingError(error, endpoint: "gameSummary")
            }
            
            // Encode full game to Data
            let encoder = JSONEncoder()
            return try encoder.encode(gameDTO)
        } catch let error as SportradarRemoteDataSourceError {
            // Re-throw our custom errors
            throw error
        } catch let error as NetworkError {
            // Map NetworkError to our custom error type
            throw mapNetworkError(error, endpoint: "gameSummary")
        } catch let error as DecodingError {
            throw SportradarRemoteDataSourceError.decodingError(error, endpoint: "gameSummary")
        } catch {
            throw SportradarRemoteDataSourceError.networkError(error)
        }
    }
    
    // MARK: - Additional Endpoints
    
    /// Fetch player profile by player ID
    /// - Parameter playerId: Unique player identifier
    /// - Returns: PlayerDTO encoded as Data
    func fetchPlayerProfile(playerId: String) async throws -> Data {
        let url = apiClient.playerProfile(playerId: playerId)
        
        guard URL(string: url) != nil else {
            throw SportradarRemoteDataSourceError.invalidURL(url)
        }
        
        do {
            let playerProfile: SportradarPlayerProfileDTO = try await networkService.request(url)
            
            // Fetch teams to get team DTO for the player
            let teamsData = try await fetchTeams()
            let teamsDecoder = JSONDecoder()
            let teamDTOs = try teamsDecoder.decode([TeamDTO].self, from: teamsData)
            
            // Try to find player's team from profile or teams list
            let teamDTO: TeamDTO?
            if let teamRef = playerProfile.team,
               let foundTeam = teamDTOs.first(where: { $0.id == teamRef.id }) {
                teamDTO = foundTeam
            } else {
                // Create minimal team DTO from reference if available
                if let teamRef = playerProfile.team {
                    teamDTO = TeamDTO(
                        id: teamRef.id,
                        name: teamRef.name ?? "Unknown Team",
                        abbreviation: teamRef.alias ?? "UNK",
                        logoURL: nil,
                        city: nil,
                        conference: nil,
                        division: nil,
                        wins: nil,
                        losses: nil,
                        winPercentage: nil
                    )
                } else {
                    teamDTO = nil
                }
            }
            
            let playerDTO = SportradarDTOMapper.mapPlayerProfile(playerProfile, teamDTO: teamDTO)
            let encoder = JSONEncoder()
            return try encoder.encode(playerDTO)
        } catch let error as NetworkError {
            throw mapNetworkError(error, endpoint: "player profile")
        } catch let error as DecodingError {
            throw SportradarRemoteDataSourceError.decodingError(error, endpoint: "player profile")
        } catch {
            throw SportradarRemoteDataSourceError.mappingError(error, endpoint: "player profile")
        }
    }
    
    /// Fetch team profile by team ID
    /// - Parameter teamId: Unique team identifier
    /// - Returns: TeamDTO encoded as Data
    func fetchTeamProfile(teamId: String) async throws -> Data {
        let url = apiClient.teamProfile(teamId: teamId)
        
        guard URL(string: url) != nil else {
            throw SportradarRemoteDataSourceError.invalidURL(url)
        }
        
        do {
            // Team profile likely returns a SportradarTeamDTO (possibly with more fields)
            let teamProfile: SportradarTeamDTO = try await networkService.request(url)
            let teamDTO = SportradarDTOMapper.mapTeam(teamProfile)
            let encoder = JSONEncoder()
            return try encoder.encode(teamDTO)
        } catch let error as NetworkError {
            throw mapNetworkError(error, endpoint: "team profile")
        } catch let error as DecodingError {
            throw SportradarRemoteDataSourceError.decodingError(error, endpoint: "team profile")
        } catch {
            throw SportradarRemoteDataSourceError.mappingError(error, endpoint: "team profile")
        }
    }
    
    /// Fetch team roster by team ID
    /// - Parameter teamId: Unique team identifier
    /// - Returns: Array of PlayerDTO encoded as Data
    func fetchTeamRoster(teamId: String) async throws -> Data {
        let url = apiClient.teamRoster(teamId: teamId)
        
        guard URL(string: url) != nil else {
            throw SportradarRemoteDataSourceError.invalidURL(url)
        }
        
        do {
            // Team roster likely returns an array of players or a roster response
            // For now, we'll try to decode as an array of SportradarPlayerDTO
            // If the API returns a different structure, we'll need to create a DTO for it
            let rosterData: Data = try await networkService.request(url)
            let decoder = JSONDecoder()
            
            // Try to decode as array of players first
            if let players = try? decoder.decode([SportradarPlayerDTO].self, from: rosterData) {
                // Fetch teams for player team references
                let teamsData = try await fetchTeams()
                let teamsDecoder = JSONDecoder()
                let teamDTOs = try teamsDecoder.decode([TeamDTO].self, from: teamsData)
                let teamsDict = Dictionary(uniqueKeysWithValues: teamDTOs.map { ($0.id, $0) })
                
                let playerDTOs = SportradarDTOMapper.mapPlayers(players, teams: teamsDict)
                let encoder = JSONEncoder()
                return try encoder.encode(playerDTOs)
            } else {
                // If not an array, might be a roster response object - for now return empty
                // TODO: Create SportradarTeamRosterDTO if API returns structured response
                let emptyPlayers: [PlayerDTO] = []
                let encoder = JSONEncoder()
                return try encoder.encode(emptyPlayers)
            }
        } catch let error as NetworkError {
            throw mapNetworkError(error, endpoint: "team roster")
        } catch let error as DecodingError {
            throw SportradarRemoteDataSourceError.decodingError(error, endpoint: "team roster")
        } catch {
            throw SportradarRemoteDataSourceError.mappingError(error, endpoint: "team roster")
        }
    }
    
    /// Fetch league leaders
    /// - Parameters:
    ///   - seasonYear: Season year (e.g., "2026"). Defaults to current year.
    ///   - seasonType: Season type (e.g., "REG" for regular season). Defaults to "REG".
    /// - Returns: Array of tuples (category, PlayerDTO) encoded as Data
    /// Note: This returns a custom structure, so we'll encode as a dictionary
    func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
        // Default to current year if not provided
        let year = seasonYear ?? String(Calendar.current.component(.year, from: Date()))
        let url = apiClient.leagueLeaders(seasonYear: year, seasonType: seasonType)
        
        guard URL(string: url) != nil else {
            throw SportradarRemoteDataSourceError.invalidURL(url)
        }
        
        do {
            let leadersResponse: SportradarLeagueLeadersDTO = try await networkService.request(url)
            
            // Fetch teams for player team references
            let teamsData = try await fetchTeams()
            let teamsDecoder = JSONDecoder()
            let teamDTOs = try teamsDecoder.decode([TeamDTO].self, from: teamsData)
            let teamsDict = Dictionary(uniqueKeysWithValues: teamDTOs.map { ($0.id, $0) })
            
            let leaders = SportradarDTOMapper.mapLeagueLeaders(leadersResponse, teams: teamsDict)
            
            // Encode as array of dictionaries with category and player
            struct LeaderEntry: Codable {
                let category: String
                let player: PlayerDTO
            }
            
            let leaderEntries = leaders.map { LeaderEntry(category: $0.category, player: $0.player) }
            let encoder = JSONEncoder()
            return try encoder.encode(leaderEntries)
        } catch let error as NetworkError {
            throw mapNetworkError(error, endpoint: "league leaders")
        } catch let error as DecodingError {
            throw SportradarRemoteDataSourceError.decodingError(error, endpoint: "league leaders")
        } catch {
            throw SportradarRemoteDataSourceError.mappingError(error, endpoint: "league leaders")
        }
    }
    
    /// Fetch standings
    /// - Returns: Array of TeamDTO with updated win/loss records encoded as Data
    func fetchStandings() async throws -> Data {
        let url = apiClient.standings()
        
        guard URL(string: url) != nil else {
            throw SportradarRemoteDataSourceError.invalidURL(url)
        }
        
        do {
            let standingsResponse: SportradarStandingsDTO = try await networkService.request(url)
            let teamDTOs = SportradarDTOMapper.mapStandings(standingsResponse)
            let encoder = JSONEncoder()
            return try encoder.encode(teamDTOs)
        } catch let error as NetworkError {
            throw mapNetworkError(error, endpoint: "standings")
        } catch let error as DecodingError {
            throw SportradarRemoteDataSourceError.decodingError(error, endpoint: "standings")
        } catch {
            throw SportradarRemoteDataSourceError.mappingError(error, endpoint: "standings")
        }
    }
    
    // MARK: - Injury Endpoints
    
    /// Fetch all active player injuries
    /// - Returns: LeagueInjuries encoded as Data
    func fetchInjuries() async throws -> Data {
        let url = apiClient.injuries()
        
        guard URL(string: url) != nil else {
            throw SportradarRemoteDataSourceError.invalidURL(url)
        }
        
        do {
            let injuriesResponse: SportradarInjuriesResponseDTO = try await networkService.request(url)
            let leagueInjuries = try injuriesResponse.toDomain()
            let encoder = JSONEncoder()
            return try encoder.encode(leagueInjuries)
        } catch let error as NetworkError {
            throw mapNetworkError(error, endpoint: "injuries")
        } catch let error as DecodingError {
            throw SportradarRemoteDataSourceError.decodingError(error, endpoint: "injuries")
        } catch let error as SportradarDTOMappingError {
            throw SportradarRemoteDataSourceError.mappingError(error, endpoint: "injuries")
        } catch {
            throw SportradarRemoteDataSourceError.mappingError(error, endpoint: "injuries")
        }
    }
    
    // MARK: - League Hierarchy Endpoint
    
    /// Fetch league hierarchy (conferences and teams)
    /// - Returns: Array of TeamDTO encoded as Data
    func fetchLeagueHierarchy() async throws -> Data {
        let url = apiClient.leagueHierarchy()
        
        guard URL(string: url) != nil else {
            throw SportradarRemoteDataSourceError.invalidURL(url)
        }
        
        do {
            let hierarchyResponse: SportradarLeagueHierarchyDTO = try await networkService.request(url)
            let teamDTOs = hierarchyResponse.toTeamDTOs()
            let encoder = JSONEncoder()
            return try encoder.encode(teamDTOs)
        } catch let error as NetworkError {
            throw mapNetworkError(error, endpoint: "league hierarchy")
        } catch let error as DecodingError {
            throw SportradarRemoteDataSourceError.decodingError(error, endpoint: "league hierarchy")
        } catch {
            throw SportradarRemoteDataSourceError.mappingError(error, endpoint: "league hierarchy")
        }
    }
    
    // MARK: - Error Mapping Helpers
    
    /// Map NetworkError to SportradarRemoteDataSourceError
    private func mapNetworkError(_ error: NetworkError, endpoint: String) -> SportradarRemoteDataSourceError {
        switch error {
        case .invalidURL(let url):
            return .invalidURL(url)
        case .invalidResponse:
            return .invalidResponseFormat(endpoint: endpoint)
        case .httpError(let statusCode, let data):
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            return .httpError(statusCode: statusCode, message: message)
        case .decodingError(let error):
            return .decodingError(error, endpoint: endpoint)
        }
    }
}
