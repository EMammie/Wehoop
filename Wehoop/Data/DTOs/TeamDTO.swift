//
//  TeamDTO.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Data Transfer Object for Team
struct TeamDTO: Codable {
    let id: String
    let name: String
    let abbreviation: String
    let logoURL: String?
    let city: String?
    let conference: String?
    let division: String?
    let wins: Int?
    let losses: Int?
    let winPercentage: Double?
    
    /// Convert DTO to domain model
    func toDomain() throws -> Team {
        let teamConference = conference.flatMap { Conference(rawValue: $0) }
        
        return Team(
            id: id,
            name: name,
            abbreviation: abbreviation,
            logoURL: logoURL,
            city: city,
            conference: teamConference,
            division: division,
            wins: wins,
            losses: losses,
            winPercentage: winPercentage
        )
    }
}
