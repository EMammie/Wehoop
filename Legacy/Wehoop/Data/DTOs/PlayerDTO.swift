//
//  PlayerDTO.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Data Transfer Object for Player
struct PlayerDTO: Codable {
    let id: String
    let name: String
    let team: TeamDTO
    let position: String
    let statistics: [StatisticDTO]
    let jerseyNumber: Int?
    let height: String?
    let weight: Int?
    let age: Int?
    let college: String?
    let photoURL: String?
    
    /// Convert DTO to domain model
    func toDomain() throws -> Player {
        Player(
            id: id,
            name: name,
            team: try team.toDomain(),
            position: position,
            statistics: try statistics.map { try $0.toDomain() },
            jerseyNumber: jerseyNumber,
            height: height,
            weight: weight,
            age: age,
            college: college,
            photoURL: photoURL
        )
    }
}

/// Data Transfer Object for Statistic
struct StatisticDTO: Codable {
    let id: String
    let name: String
    let value: Double
    let category: String
    let unit: String?
    let season: String?
    let gamesPlayed: Int?
    
    func toDomain() throws -> Statistic {
        guard let statCategory = StatCategory(rawValue: category.lowercased()) else {
            throw DTOMappingError.invalidStatus(category)
        }
        
        let statUnit = unit.flatMap { StatUnit(rawValue: $0.lowercased()) }
        
        return Statistic(
            id: id,
            name: name,
            value: value,
            category: statCategory,
            unit: statUnit,
            season: season,
            gamesPlayed: gamesPlayed
        )
    }
}
