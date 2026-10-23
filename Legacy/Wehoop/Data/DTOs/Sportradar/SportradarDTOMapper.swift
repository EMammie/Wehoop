//
//  SportradarDTOMapper.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

// MARK: - Sportradar DTO Mapping Errors

/// Custom error type for SportradarDTOMapper operations
enum SportradarDTOMappingError: LocalizedError {
    // Missing Data
    case missingRequiredField(String, context: String? = nil)
    case missingTeam(String, gameId: String? = nil)
    case missingPlayer(String, context: String? = nil)
    
    // Invalid Data
    case invalidDate(String, context: String? = nil)
    case invalidStatus(String, context: String? = nil)
    case invalidFormat(String, context: String? = nil)
    
    // Mapping Failures
    case teamMappingFailed(String, reason: String? = nil)
    case playerMappingFailed(String, reason: String? = nil)
    case gameMappingFailed(String, reason: String? = nil)
    case boxscoreMappingFailed(String, reason: String? = nil)
    
    // Data Inconsistency
    case dataInconsistency(String, details: String? = nil)
    case unexpectedStructure(String, expected: String? = nil)
    
    var errorDescription: String? {
        switch self {
        // Missing Data
        case .missingRequiredField(let field, let context):
            if let context = context {
                return "Missing required field '\(field)' in \(context)"
            }
            return "Missing required field: \(field)"
        case .missingTeam(let teamId, let gameId):
            if let gameId = gameId {
                return "Team '\(teamId)' not found in teams dictionary for game '\(gameId)'"
            }
            return "Team '\(teamId)' not found in teams dictionary"
        case .missingPlayer(let playerId, let context):
            if let context = context {
                return "Player '\(playerId)' not found in \(context)"
            }
            return "Player '\(playerId)' not found"
        
        // Invalid Data
        case .invalidDate(let date, let context):
            if let context = context {
                return "Invalid date format '\(date)' in \(context)"
            }
            return "Invalid date format: \(date)"
        case .invalidStatus(let status, let context):
            if let context = context {
                return "Invalid status '\(status)' in \(context)"
            }
            return "Invalid status: \(status)"
        case .invalidFormat(let format, let context):
            if let context = context {
                return "Invalid format '\(format)' in \(context)"
            }
            return "Invalid format: \(format)"
        
        // Mapping Failures
        case .teamMappingFailed(let teamId, let reason):
            if let reason = reason {
                return "Failed to map team '\(teamId)': \(reason)"
            }
            return "Failed to map team: \(teamId)"
        case .playerMappingFailed(let playerId, let reason):
            if let reason = reason {
                return "Failed to map player '\(playerId)': \(reason)"
            }
            return "Failed to map player: \(playerId)"
        case .gameMappingFailed(let gameId, let reason):
            if let reason = reason {
                return "Failed to map game '\(gameId)': \(reason)"
            }
            return "Failed to map game: \(gameId)"
        case .boxscoreMappingFailed(let gameId, let reason):
            if let reason = reason {
                return "Failed to map boxscore for game '\(gameId)': \(reason)"
            }
            return "Failed to map boxscore for game: \(gameId)"
        
        // Data Inconsistency
        case .dataInconsistency(let message, let details):
            if let details = details {
                return "Data inconsistency: \(message). Details: \(details)"
            }
            return "Data inconsistency: \(message)"
        case .unexpectedStructure(let structure, let expected):
            if let expected = expected {
                return "Unexpected structure '\(structure)'. Expected: \(expected)"
            }
            return "Unexpected structure: \(structure)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .missingTeam, .missingPlayer:
            return "Required reference data is missing from the teams/players dictionary"
        case .invalidDate:
            return "Date string doesn't match expected ISO 8601 format"
        case .invalidStatus:
            return "Status value doesn't match any known game status"
        case .teamMappingFailed, .playerMappingFailed, .gameMappingFailed, .boxscoreMappingFailed:
            return "Data transformation from Sportradar format to app format failed"
        case .dataInconsistency:
            return "Data from Sportradar API contains inconsistent or conflicting values"
        case .unexpectedStructure:
            return "API response structure doesn't match expected format"
        default:
            return nil
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .missingTeam, .missingPlayer:
            return "Ensure all referenced teams/players are fetched before mapping games"
        case .invalidDate:
            return "Check that the date string is in ISO 8601 format (e.g., '2026-01-17T00:30:00+00:00')"
        case .invalidStatus:
            return "Verify the status value matches expected game statuses (scheduled, live, finished, etc.)"
        case .teamMappingFailed, .playerMappingFailed, .gameMappingFailed, .boxscoreMappingFailed:
            return "This may indicate an API response format change. Check Sportradar API documentation"
        case .dataInconsistency:
            return "This may indicate corrupted or incomplete data from the API. Try fetching again"
        case .unexpectedStructure:
            return "Verify the API endpoint is returning the expected response structure"
        default:
            return nil
        }
    }
}

/// Utility for mapping Sportradar API responses to app DTOs
struct SportradarDTOMapper {
    
    // MARK: - Teams Mapping
    
    /// Map Sportradar teams response to app TeamDTO array
    /// - Parameter sportradarTeamsResponse: Sportradar teams response DTO
    /// - Returns: Array of app TeamDTOs
    static func mapTeams(_ sportradarTeamsResponse: SportradarTeamsResponseDTO) -> [TeamDTO] {
        return sportradarTeamsResponse.teams.map { $0.toTeamDTO() }
    }
    
    /// Map Sportradar teams array to app TeamDTO array
    /// - Parameter sportradarTeams: Array of Sportradar team DTOs
    /// - Returns: Array of app TeamDTOs
    static func mapTeams(_ sportradarTeams: [SportradarTeamDTO]) -> [TeamDTO] {
        return sportradarTeams.map { $0.toTeamDTO() }
    }
    
    /// Map single Sportradar team to app TeamDTO
    /// - Parameter sportradarTeam: Sportradar team DTO
    /// - Returns: App TeamDTO
    static func mapTeam(_ sportradarTeam: SportradarTeamDTO) -> TeamDTO {
        return sportradarTeam.toTeamDTO()
    }
    
    // MARK: - Players Mapping
    
    /// Map Sportradar players response to app PlayerDTO array
    /// - Parameters:
    ///   - sportradarPlayers: Array of Sportradar player DTOs
    ///   - teams: Dictionary of team ID to TeamDTO for player team references
    /// - Returns: Array of app PlayerDTOs
    static func mapPlayers(
        _ sportradarPlayers: [SportradarPlayerDTO],
        teams: [String: TeamDTO]
    ) -> [PlayerDTO] {
        return sportradarPlayers.compactMap { sportradarPlayer in
            // Get team DTO for player
            let teamId = sportradarPlayer.teamId ?? sportradarPlayer.team?.id
            guard let teamId = teamId,
                  let teamDTO = teams[teamId] else {
                // If team not found, create a minimal team DTO
                let teamDTO = TeamDTO(
                    id: teamId ?? "unknown",
                    name: sportradarPlayer.team?.name ?? "Unknown Team",
                    abbreviation: sportradarPlayer.team?.alias ?? "UNK",
                    logoURL: nil,
                    city: nil,
                    conference: nil,
                    division: nil,
                    wins: nil,
                    losses: nil,
                    winPercentage: nil
                )
                return sportradarPlayer.toPlayerDTO(teamDTO: teamDTO)
            }
            
            return sportradarPlayer.toPlayerDTO(teamDTO: teamDTO)
        }
    }
    
    /// Map single Sportradar player to app PlayerDTO
    /// - Parameters:
    ///   - sportradarPlayer: Sportradar player DTO
    ///   - teamDTO: Team DTO for the player
    /// - Returns: App PlayerDTO
    static func mapPlayer(
        _ sportradarPlayer: SportradarPlayerDTO,
        teamDTO: TeamDTO
    ) -> PlayerDTO {
        return sportradarPlayer.toPlayerDTO(teamDTO: teamDTO)
    }
    
    /// Map Sportradar player profile to app PlayerDTO
    /// - Parameters:
    ///   - sportradarPlayerProfile: Sportradar player profile DTO
    ///   - teamDTO: Optional team DTO (if not provided, will use team reference from profile)
    /// - Returns: App PlayerDTO
    static func mapPlayerProfile(
        _ sportradarPlayerProfile: SportradarPlayerProfileDTO,
        teamDTO: TeamDTO? = nil
    ) -> PlayerDTO {
        return sportradarPlayerProfile.toPlayerDTO(teamDTO: teamDTO)
    }
    
    // MARK: - Games Mapping
    
    /// Map Sportradar game summary to app GameDTO
    /// - Parameters:
    ///   - sportradarGameSummary: Sportradar game summary DTO
    ///   - teams: Dictionary of team ID to TeamDTO for game team references
    /// - Returns: App GameDTO
    static func mapGameSummary(
        _ sportradarGameSummary: SportradarGameSummaryDTO,
        teams: [String: TeamDTO]
    ) throws -> GameDTO {
        // Get home and away team DTOs
        let homeTeamId = sportradarGameSummary.home?.id
        let awayTeamId = sportradarGameSummary.away?.id
        
        guard let homeTeamId = homeTeamId,
              let awayTeamId = awayTeamId else {
            throw SportradarDTOMappingError.missingRequiredField(
                "Home or away team ID",
                context: "game summary '\(sportradarGameSummary.id)'"
            )
        }
        
        guard let homeTeamDTO = teams[homeTeamId] else {
            throw SportradarDTOMappingError.missingTeam(homeTeamId, gameId: sportradarGameSummary.id)
        }
        
        guard let awayTeamDTO = teams[awayTeamId] else {
            throw SportradarDTOMappingError.missingTeam(awayTeamId, gameId: sportradarGameSummary.id)
        }
        
        do {
            return try sportradarGameSummary.toGameDTO(
                homeTeamDTO: homeTeamDTO,
                awayTeamDTO: awayTeamDTO
            )
        } catch let error as DTOMappingError {
            // Wrap DTOMappingError in SportradarDTOMappingError
            switch error {
            case .invalidDate(let date):
                throw SportradarDTOMappingError.invalidDate(date, context: "game summary '\(sportradarGameSummary.id)'")
            case .invalidStatus(let status):
                throw SportradarDTOMappingError.invalidStatus(status, context: "game summary '\(sportradarGameSummary.id)'")
            case .missingRequiredField(let field):
                throw SportradarDTOMappingError.missingRequiredField(field, context: "game summary '\(sportradarGameSummary.id)'")
            }
        } catch {
            // Wrap other errors
            throw SportradarDTOMappingError.gameMappingFailed(
                sportradarGameSummary.id,
                reason: error.localizedDescription
            )
        }
    }
    
    /// Map Sportradar games response to app GameDTO array
    /// - Parameters:
    ///   - sportradarGames: Array of Sportradar game DTOs
    ///   - teams: Dictionary of team ID to TeamDTO for game team references
    /// - Returns: Array of app GameDTOs
    static func mapGames(
        _ sportradarGames: [SportradarGameDTO],
        teams: [String: TeamDTO]
    ) throws -> [GameDTO] {
        var mappingErrors: [Error] = []
        
        let mappedGames = sportradarGames.compactMap { sportradarGame -> GameDTO? in
            // Get home and away team DTOs
            // Support both new structure (home/away objects with id) and legacy (homeId/awayId)
            let homeTeamId = sportradarGame.home?.id ?? sportradarGame.homeId
            let awayTeamId = sportradarGame.away?.id ?? sportradarGame.awayId
            
            guard let homeTeamId = homeTeamId,
                  let awayTeamId = awayTeamId else {
                let error = SportradarDTOMappingError.missingRequiredField(
                    "Home or away team ID",
                    context: "game '\(sportradarGame.id)'"
                )
                mappingErrors.append(error)
                return nil
            }
            
            guard let homeTeamDTO = teams[homeTeamId] else {
                let error = SportradarDTOMappingError.missingTeam(homeTeamId, gameId: sportradarGame.id)
                mappingErrors.append(error)
                return nil
            }
            
            guard let awayTeamDTO = teams[awayTeamId] else {
                let error = SportradarDTOMappingError.missingTeam(awayTeamId, gameId: sportradarGame.id)
                mappingErrors.append(error)
                return nil
            }
            
            do {
                return try sportradarGame.toGameDTO(
                    homeTeamDTO: homeTeamDTO,
                    awayTeamDTO: awayTeamDTO
                )
            } catch {
                let mappingError = SportradarDTOMappingError.gameMappingFailed(
                    sportradarGame.id,
                    reason: error.localizedDescription
                )
                mappingErrors.append(mappingError)
                return nil
            }
        }
        
        // If all games failed to map, throw an error
        if mappedGames.isEmpty && !sportradarGames.isEmpty {
            throw SportradarDTOMappingError.gameMappingFailed(
                "all games",
                reason: "\(mappingErrors.count) mapping error(s) occurred"
            )
        }
        
        return mappedGames
    }
    
    /// Map single Sportradar game to app GameDTO
    /// - Parameters:
    ///   - sportradarGame: Sportradar game DTO
    ///   - homeTeamDTO: Home team DTO
    ///   - awayTeamDTO: Away team DTO
    /// - Returns: App GameDTO
    static func mapGame(
        _ sportradarGame: SportradarGameDTO,
        homeTeamDTO: TeamDTO,
        awayTeamDTO: TeamDTO
    ) throws -> GameDTO {
        do {
            return try sportradarGame.toGameDTO(
                homeTeamDTO: homeTeamDTO,
                awayTeamDTO: awayTeamDTO
            )
        } catch let error as DTOMappingError {
            // Wrap DTOMappingError in SportradarDTOMappingError
            switch error {
            case .invalidDate(let date):
                throw SportradarDTOMappingError.invalidDate(date, context: "game '\(sportradarGame.id)'")
            case .invalidStatus(let status):
                throw SportradarDTOMappingError.invalidStatus(status, context: "game '\(sportradarGame.id)'")
            case .missingRequiredField(let field):
                throw SportradarDTOMappingError.missingRequiredField(field, context: "game '\(sportradarGame.id)'")
            }
        } catch {
            // Wrap other errors
            throw SportradarDTOMappingError.gameMappingFailed(
                sportradarGame.id,
                reason: error.localizedDescription
            )
        }
    }
    
    // MARK: - Boxscore Mapping
    
    /// Map Sportradar boxscore response to app BoxScoreDTO
    /// - Parameter sportradarBoxscore: Sportradar boxscore DTO
    /// - Returns: App BoxScoreDTO
    static func mapBoxscore(_ sportradarBoxscore: SportradarBoxscoreDTO) throws -> BoxScoreDTO {
        do {
            return try sportradarBoxscore.toBoxScoreDTO()
        } catch let error as DTOMappingError {
            // Wrap DTOMappingError in SportradarDTOMappingError
            let gameId = sportradarBoxscore.id ?? "unknown"
            switch error {
            case .invalidDate(let date):
                throw SportradarDTOMappingError.invalidDate(date, context: "boxscore for game '\(gameId)'")
            case .invalidStatus(let status):
                throw SportradarDTOMappingError.invalidStatus(status, context: "boxscore for game '\(gameId)'")
            case .missingRequiredField(let field):
                throw SportradarDTOMappingError.missingRequiredField(field, context: "boxscore for game '\(gameId)'")
            }
        } catch {
            // Wrap other errors
            let gameId = sportradarBoxscore.id ?? "unknown"
            throw SportradarDTOMappingError.boxscoreMappingFailed(
                gameId,
                reason: error.localizedDescription
            )
        }
    }
    
    // MARK: - League Leaders Mapping
    
    /// Map Sportradar league leaders response to app format
    /// - Parameter sportradarLeaders: Sportradar league leaders DTO
    /// - Parameter teams: Dictionary of team ID to TeamDTO
    /// - Returns: Array of tuples (category, player DTO)
    static func mapLeagueLeaders(
        _ sportradarLeaders: SportradarLeagueLeadersDTO,
        teams: [String: TeamDTO]
    ) -> [(category: String, player: PlayerDTO)] {
        guard let categories = sportradarLeaders.categories else {
            return []
        }
        
        var result: [(category: String, player: PlayerDTO)] = []
        
        // Iterate through each category
        for category in categories {
            guard let categoryName = category.name,
                  let ranks = category.ranks else {
                continue
            }
            
            // Iterate through each rank in the category
            for rankEntry in ranks {
                guard let playerData = rankEntry.player else {
                    continue
                }
                
                // Get team from teams array (use first team)
                guard let teamRef = rankEntry.teams?.first,
                      let teamId = teamRef.id,
                      let teamDTO = teams[teamId] else {
                    // Skip if no valid team reference
                    continue
                }
                
                // Skip if player ID is missing (required for PlayerDTO)
                guard let playerId = playerData.id else {
                    continue
                }
                
                // Map the leader player to a full PlayerDTO
                // Create a minimal SportradarPlayerDTO from the leader player data
                let fullPlayerDTO = SportradarPlayerDTO(
                    id: playerId,
                    fullName: playerData.fullName,
                    firstName: playerData.firstName,
                    lastName: playerData.lastName,
                    position: playerData.position,
                    jerseyNumber: playerData.jerseyNumber,
                    height: nil,
                    weight: nil,
                    age: nil,
                    birthDate: nil,
                    birthPlace: nil,
                    college: nil,
                    photo: nil,
                    team: nil,
                    teamId: teamId,
                    statistics: nil,
                    averages: nil
                )
                
                    var mappedPlayer = fullPlayerDTO.toPlayerDTO(teamDTO: teamDTO)
                    
                    // Extract stat value from rankEntry (prefer average for per-game stats)
                    let statValue: Double
                    let statUnit: StatUnit?
                    let statName: String
                    
                    // Map category name to StatCategory
                    let statCategory = mapCategoryNameToStatCategory(categoryName)
                    
                    // Get value from average (per-game) or score (fallback)
                    if let average = rankEntry.average {
                        // Extract value from average based on category name
                        statValue = extractStatValueFromAverage(average, categoryName: categoryName)
                    } else if let score = rankEntry.score {
                        // Fallback to score if average not available
                        statValue = score
                    } else {
                        statValue = 0.0
                    }
                    
                    // Determine unit and name based on category
                    (statUnit, statName) = getStatUnitAndName(for: statCategory, categoryName: categoryName)
                    
                    // Create StatisticDTO for the leader stat
                    let leaderStat = StatisticDTO(
                        id: "\(playerId)_\(categoryName)_leader",
                        name: statName,
                        value: statValue,
                        category: statCategory.rawValue,
                        unit: statUnit?.rawValue,
                        season: nil,
                        gamesPlayed: rankEntry.total?.gamesPlayed
                    )
                    
                    // Add the statistic to the player's statistics array
                    mappedPlayer = PlayerDTO(
                        id: mappedPlayer.id,
                        name: mappedPlayer.name,
                        team: mappedPlayer.team,
                        position: mappedPlayer.position,
                        statistics: mappedPlayer.statistics + [leaderStat],
                        jerseyNumber: mappedPlayer.jerseyNumber,
                        height: mappedPlayer.height,
                        weight: mappedPlayer.weight,
                        age: mappedPlayer.age,
                        college: mappedPlayer.college,
                        photoURL: mappedPlayer.photoURL
                    )
                    
                    result.append((category: categoryName, player: mappedPlayer))

            }
        }
        
        return result
    }
    
    // MARK: - League Leaders Helper Functions
    
    /// Map API category name to StatCategory
    private static func mapCategoryNameToStatCategory(_ categoryName: String) -> StatCategory {
        let normalized = categoryName.lowercased()
        
        // Scoring-related categories
        if normalized.contains("point") && !normalized.contains("percentage") && !normalized.contains("pct") {
            return .scoring
        }
        
        // Rebounding
        if normalized.contains("rebound") {
            return .rebounding
        }
        
        // Assists
        if normalized.contains("assist") {
            return .assists
        }
        
        // Defense (steals or blocks)
        if normalized.contains("steal") {
            return .defense
        }
        if normalized.contains("block") && !normalized.contains("blocked_att") {
            return .defense
        }
        
        // Efficiency
        if normalized.contains("efficiency") {
            return .efficiency
        }
        
        // Shooting (percentages)
        if normalized.contains("percentage") || normalized.contains("pct") || normalized.contains("_pct") {
            return .shooting
        }
        
        // Turnovers
        if normalized.contains("turnover") {
            return .turnovers
        }
        
        // Default to scoring
        return .scoring
    }
    
    /// Extract stat value from average based on category name
    private static func extractStatValueFromAverage(_ average: SportradarLeagueLeadersDTO.SportradarLeaderAverageDTO, categoryName: String) -> Double {
        let normalized = categoryName.lowercased()
        
        // Points
        if normalized == "points" || normalized == "point" {
            return average.points ?? 0.0
        }
        
        // Rebounds
        if normalized.contains("rebound") {
            return average.rebounds ?? 0.0
        }
        
        // Assists
        if normalized.contains("assist") {
            return average.assists ?? 0.0
        }
        
        // Steals
        if normalized.contains("steal") {
            return average.steals ?? 0.0
        }
        
        // Blocks
        if normalized.contains("block") && !normalized.contains("blocked_att") {
            return average.blocks ?? 0.0
        }
        
        // Turnovers
        if normalized.contains("turnover") {
            return average.turnovers ?? 0.0
        }
        
        // Efficiency
        if normalized.contains("efficiency") {
            return average.efficiency ?? 0.0
        }
        
        // Field goal percentage
        if normalized.contains("field_goal") && (normalized.contains("pct") || normalized.contains("percentage")) {
            if let made = average.fieldGoalsMade, let att = average.fieldGoalsAtt, att > 0 {
                return (made / att) * 100.0
            }
            return 0.0
        }
        
        // Three point percentage
        if normalized.contains("three_point") && (normalized.contains("pct") || normalized.contains("percentage")) {
            if let made = average.threePointsMade, let att = average.threePointsAtt, att > 0 {
                return (made / att) * 100.0
            }
            return 0.0
        }
        
        // Free throw percentage
        if normalized.contains("free_throw") && (normalized.contains("pct") || normalized.contains("percentage")) {
            if let made = average.freeThrowsMade, let att = average.freeThrowsAtt, att > 0 {
                return (made / att) * 100.0
            }
            return 0.0
        }
        
        // Two point percentage
        if normalized.contains("two_point") && (normalized.contains("pct") || normalized.contains("percentage")) {
            if let made = average.twoPointsMade, let att = average.twoPointsAtt, att > 0 {
                return (made / att) * 100.0
            }
            return 0.0
        }
        
        // For made/attempted stats, return the made value (per game average)
        if normalized.contains("_made") {
            if normalized.contains("field_goal") {
                return average.fieldGoalsMade ?? 0.0
            } else if normalized.contains("three_point") {
                return average.threePointsMade ?? 0.0
            } else if normalized.contains("free_throw") {
                return average.freeThrowsMade ?? 0.0
            } else if normalized.contains("two_point") {
                return average.twoPointsMade ?? 0.0
            }
        }
        
        // For attempted stats, return the attempted value (per game average)
        if normalized.contains("_att") && !normalized.contains("blocked_att") {
            if normalized.contains("field_goal") {
                return average.fieldGoalsAtt ?? 0.0
            } else if normalized.contains("three_point") {
                return average.threePointsAtt ?? 0.0
            } else if normalized.contains("free_throw") {
                return average.freeThrowsAtt ?? 0.0
            } else if normalized.contains("two_point") {
                return average.twoPointsAtt ?? 0.0
            }
        }
        
        // Minutes
        if normalized.contains("minute") {
            return average.minutes ?? 0.0
        }
        
        // Default: try to get points
        return average.points ?? 0.0
    }
    
    /// Get stat unit and display name for a category
    private static func getStatUnitAndName(for category: StatCategory, categoryName: String) -> (StatUnit?, String) {
        let normalized = categoryName.lowercased()
        
        switch category {
        case .scoring:
            return (.points, "Points Per Game")
        case .rebounding:
            return (.rebounds, "Rebounds Per Game")
        case .assists:
            return (.assists, "Assists Per Game")
        case .defense:
            // Check if category name indicates steals or blocks
            if normalized.contains("steal") {
                return (.steals, "Steals Per Game")
            } else if normalized.contains("block") {
                return (.blocks, "Blocks Per Game")
            }
            return (.steals, "Steals Per Game") // Default to steals
        case .efficiency:
            return (nil, "Efficiency")
        case .shooting:
            // Determine specific shooting stat name
            if normalized.contains("field_goal") {
                return (.percentage, "Field Goal %")
            } else if normalized.contains("three_point") {
                return (.percentage, "3PT %")
            } else if normalized.contains("free_throw") {
                return (.percentage, "FT %")
            } else if normalized.contains("two_point") {
                return (.percentage, "2PT %")
            }
            return (.percentage, "Field Goal %")
        case .turnovers:
            return (nil, "Turnovers Per Game")
        }
    }
    
    // MARK: - Standings Mapping
    
    /// Map Sportradar standings response to app TeamDTO array with updated records
    /// - Parameter sportradarStandings: Sportradar standings DTO
    /// - Returns: Array of TeamDTOs with updated win/loss records
    static func mapStandings(_ sportradarStandings: SportradarStandingsDTO) -> [TeamDTO] {
        guard let teamStandings = sportradarStandings.teams else {
            return []
        }
        
        return teamStandings.compactMap { standing in
            guard let team = standing.team else {
                return nil
            }
            
            // Use standing data if available, otherwise use team data
            return TeamDTO(
                id: team.id,
                name: team.name,
                abbreviation: team.alias ?? team.name.prefix(3).uppercased(),
                logoURL: team.logo,
                city: team.market,
                conference: standing.conference ?? team.conference,
                division: standing.division ?? team.division,
                wins: standing.wins ?? team.wins,
                losses: standing.losses ?? team.losses,
                winPercentage: standing.winPercentage ?? team.winPercentage
            )
        }
    }
    
    // MARK: - Schedule Mapping
    
    /// Map Sportradar schedule response to app GameDTO array
    /// - Parameters:
    ///   - sportradarSchedule: Sportradar schedule DTO
    ///   - teams: Dictionary of team ID to TeamDTO
    /// - Returns: Array of app GameDTOs
    static func mapSchedule(
        _ sportradarSchedule: SportradarScheduleDTO,
        teams: [String: TeamDTO]
    ) throws -> [GameDTO] {
        guard let games = sportradarSchedule.games else {
            return []
        }
        
        return try mapGames(games, teams: teams)
    }
    
    // MARK: - Daily Changes Mapping
    
    /// Map Sportradar daily changes response to change identifiers
    /// - Parameter sportradarChanges: Sportradar daily changes DTO
    /// - Returns: Tuple with arrays of changed IDs
    static func mapDailyChanges(_ sportradarChanges: SportradarDailyChangesDTO) -> (
        teams: [String],
        players: [String],
        games: [String]
    ) {
        return (
            teams: sportradarChanges.teams ?? [],
            players: sportradarChanges.players ?? [],
            games: sportradarChanges.games ?? []
        )
    }
}
