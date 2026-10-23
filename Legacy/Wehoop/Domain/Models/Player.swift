//
//  Player.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Domain model for a player
struct Player: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let team: Team
    let position: String
    let statistics: [Statistic]
    let jerseyNumber: Int?
    let height: String?
    let weight: Int?
    let age: Int?
    let college: String?
    let photoURL: String?
    
    /// Computed property to get full name with jersey number
    var displayName: String {
        if let number = jerseyNumber {
            return "#\(number) \(name)"
        }
        return name
    }
    
    /// Computed property to get primary position abbreviation
    var positionAbbreviation: String {
        switch position.lowercased() {
        case "point guard", "pg": return "PG"
        case "shooting guard", "sg": return "SG"
        case "small forward", "sf": return "SF"
        case "power forward", "pf": return "PF"
        case "center", "c": return "C"
        default: return position.uppercased()
        }
    }
    
    /// Get statistic by category
    func statistic(for category: StatCategory) -> Statistic? {
        statistics.first { $0.category == category }
    }
    
    /// Get statistic by name
    func statistic(named name: String) -> Statistic? {
        statistics.first { $0.name.lowercased() == name.lowercased() }
    }
    
    /// Get points per game
    var pointsPerGame: Double {
        statistic(for: .scoring)?.value ?? 0.0
    }
    
    /// Get rebounds per game
    var reboundsPerGame: Double {
        statistic(named: "Rebounds")?.value ?? statistic(named: "Rebounds Per Game")?.value ?? 0.0
    }
    
    /// Get assists per game
    var assistsPerGame: Double {
        statistic(for: .assists)?.value ?? statistic(named: "Assists Per Game")?.value ?? 0.0
    }
}
