//
//  Statistic.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Domain model for a statistic
struct Statistic: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let value: Double
    let category: StatCategory
    let unit: StatUnit?
    let season: String?
    let gamesPlayed: Int?
    
    /// Computed property for formatted value with unit
    var formattedValue: String {
        let formattedNumber: String
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            formattedNumber = String(format: "%.0f", value)
        } else {
            formattedNumber = String(format: "%.1f", value)
        }
        
        if let unit = unit {
            return "\(formattedNumber) \(unit.symbol)"
        }
        return formattedNumber
    }
    
    /// Computed property for per-game average if games played is available
    var perGameAverage: Double? {
        guard let games = gamesPlayed, games > 0 else {
            return nil
        }
        return value / Double(games)
    }
}

enum StatCategory: String, Codable, CaseIterable {
    case scoring
    case rebounding
    case assists
    case defense
    case efficiency
    case shooting
    case turnovers
    
    /// Display name for the category
    var displayName: String {
        switch self {
        case .scoring: return "Scoring"
        case .rebounding: return "Rebounding"
        case .assists: return "Assists"
        case .defense: return "Defense"
        case .efficiency: return "Efficiency"
        case .shooting: return "Shooting"
        case .turnovers: return "Turnovers"
        }
    }
}

enum StatUnit: String, Codable {
    case points
    case rebounds
    case assists
    case steals
    case blocks
    case percentage
    case minutes
    case games
    
    var symbol: String {
        switch self {
        case .points: return "PTS"
        case .rebounds: return "REB"
        case .assists: return "AST"
        case .steals: return "STL"
        case .blocks: return "BLK"
        case .percentage: return "%"
        case .minutes: return "MIN"
        case .games: return "GP"
        }
    }
}

// MARK: - StatCategory API Mapping

extension StatCategory {
    /// Maps domain StatCategory to API category string used by Sportradar
    var apiCategoryString: String {
        switch self {
        case .scoring: return "points"
        case .rebounding: return "rebounds"
        case .assists: return "assists"
        case .defense: return "steals" // API may use "steals" for defense category
        case .efficiency: return "efficiency"
        case .shooting: return "field_goal_percentage"
        case .turnovers: return "turnovers"
        }
    }
    
    /// Creates StatCategory from API category string
    static func from(apiCategoryString: String) -> StatCategory? {
        let normalized = apiCategoryString.lowercased()
        switch normalized {
        case "points", "point": return .scoring
        case "rebounds", "rebound": return .rebounding
        case "assists", "assist": return .assists
        case "steals", "steal": return .defense
        case "efficiency": return .efficiency
        case "field_goal_percentage", "field_goal_pct", "fg_percentage", "fg_pct": return .shooting
        case "turnovers", "turnover": return .turnovers
        default: return nil
        }
    }
}
