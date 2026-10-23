//
//  BoxScore.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Domain model for a game's box score
struct BoxScore: Codable, Equatable, Hashable {
    let homeScore: Int
    let awayScore: Int
    let homeStats: TeamStats
    let awayStats: TeamStats
    let quarters: [QuarterScore]?
    let lastUpdated: Date?
    
    /// Computed property to get the point difference
    var pointDifference: Int {
        abs(homeScore - awayScore)
    }
    
    /// Computed property to check if game was close (within 5 points)
    var wasCloseGame: Bool {
        pointDifference <= 5
    }
    
    /// Get the leading team's score
    var leadingScore: Int {
        max(homeScore, awayScore)
    }
    
    /// Get the trailing team's score
    var trailingScore: Int {
        min(homeScore, awayScore)
    }
}

struct TeamStats: Codable, Equatable, Hashable {
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
    
    /// Computed property for formatted field goal percentage
    var formattedFieldGoalPercentage: String {
        guard let fgPercentage = fieldGoalPercentage else {
            return "N/A"
        }
        return String(format: "%.1f%%", fgPercentage)
    }
    
    /// Computed property for formatted three point percentage
    var formattedThreePointPercentage: String {
        guard let threePtPercentage = threePointPercentage else {
            return "N/A"
        }
        return String(format: "%.1f%%", threePtPercentage)
    }
}

struct QuarterScore: Codable, Equatable, Hashable, Identifiable {
    let id: String // e.g., "Q1", "Q2", "OT1"
    let homeScore: Int
    let awayScore: Int
    let quarterNumber: Int
    
    /// Computed property for quarter display name
    var displayName: String {
        if quarterNumber <= 4 {
            return "Q\(quarterNumber)"
        } else {
            return "OT\(quarterNumber - 4)"
        }
    }
}
