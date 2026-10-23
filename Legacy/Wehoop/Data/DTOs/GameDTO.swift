//
//  GameDTO.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Data Transfer Object for Game
struct GameDTO: Codable {
    let id: String
    let homeTeam: TeamDTO
    let awayTeam: TeamDTO
    let date: String // ISO 8601 date string
    let status: String
    let boxScore: BoxScoreDTO?
    let venue: String?
    let league: String?
    let broadcastNetwork: String?
    let timeZone: String?
    
    /// Convert DTO to domain model
    func toDomain() throws -> Game {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let gameDate = dateFormatter.date(from: date) ?? ISO8601DateFormatter().date(from: date) else {
            throw DTOMappingError.invalidDate(date)
        }
        
        guard let gameStatus = GameStatus(rawValue: status.lowercased()) else {
            throw DTOMappingError.invalidStatus(status)
        }
        
        return Game(
            id: id,
            homeTeam: try homeTeam.toDomain(),
            awayTeam: try awayTeam.toDomain(),
            date: gameDate,
            status: gameStatus,
            boxScore: try boxScore?.toDomain(),
            venue: venue,
            league: league,
            broadcastNetwork: broadcastNetwork,
            timeZone: timeZone
        )
    }
}

/// Data Transfer Object for BoxScore
struct BoxScoreDTO: Codable {
    let homeScore: Int
    let awayScore: Int
    let homeStats: TeamStatsDTO
    let awayStats: TeamStatsDTO
    let quarters: [QuarterScoreDTO]?
    let lastUpdated: String? // ISO 8601 date string
    
    func toDomain() throws -> BoxScore {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let lastUpdatedDate = lastUpdated.flatMap { 
            dateFormatter.date(from: $0) ?? ISO8601DateFormatter().date(from: $0)
        }
        
        return BoxScore(
            homeScore: homeScore,
            awayScore: awayScore,
            homeStats: homeStats.toDomain(),
            awayStats: awayStats.toDomain(),
            quarters:  quarters?.map { $0.toDomain() },
            lastUpdated: lastUpdatedDate
        )
    }
}

/// Data Transfer Object for TeamStats
struct TeamStatsDTO: Codable {
    let points: Int
    let rebounds: Int
    let assists: Int
    let steals: Int?
    let blocks: Int?
    let turnovers: Int?
    let fieldGoalPercentage: Double?
    let threePointPercentage: Double?
    let freeThrowPercentage: Double?
    let fouls: Int?
    
    func toDomain() -> TeamStats {
        TeamStats(
            points: points,
            rebounds: rebounds,
            assists: assists,
            steals: steals,
            blocks: blocks,
            turnovers: turnovers,
            fieldGoalPercentage: fieldGoalPercentage,
            threePointPercentage: threePointPercentage,
            freeThrowPercentage: freeThrowPercentage,
            fouls: fouls
        )
    }
}

/// Data Transfer Object for QuarterScore
struct QuarterScoreDTO: Codable {
    let id: String
    let homeScore: Int
    let awayScore: Int
    let quarterNumber: Int
    
    func toDomain() -> QuarterScore {
        QuarterScore(
            id: id,
            homeScore: homeScore,
            awayScore: awayScore,
            quarterNumber: quarterNumber
        )
    }
}

enum DTOMappingError: Error {
    case invalidDate(String)
    case invalidStatus(String)
    case missingRequiredField(String)
}
