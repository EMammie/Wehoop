//
//  TeamLeadersManager.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Manages team statistical leaders
class TeamLeadersManager {
    private let players: [Player]
    
    init(players: [Player]) {
        self.players = players
    }
    
    /// Get the leader for a specific statistical category
    func leader(for category: StatisticalCategory) -> Player? {
        switch category {
        case .pointsPerGame:
            return players.max(by: { $0.pointsPerGame < $1.pointsPerGame })
        case .reboundsPerGame:
            return players.max(by: { $0.reboundsPerGame < $1.reboundsPerGame })
        case .assistsPerGame:
            return players.max(by: { $0.assistsPerGame < $1.assistsPerGame })
        case .stealsPerGame:
            return players.max(by: { $0.stealsPerGame < $1.stealsPerGame })
        case .blocksPerGame:
            return players.max(by: { $0.blocksPerGame < $1.blocksPerGame })
        case .fieldGoalPercentage:
            return players.max(by: { $0.fieldGoalPercentage < $1.fieldGoalPercentage })
        case .threePointPercentage:
            return players.max(by: { $0.threePointPercentage < $1.threePointPercentage })
        case .freeThrowPercentage:
            return players.max(by: { $0.freeThrowPercentage < $1.freeThrowPercentage })
        }
    }
    
    /// Get leaders for multiple categories
    func leaders(for categories: [StatisticalCategory]) -> [(category: StatisticalCategory, player: Player)] {
        categories.compactMap { category in
            guard let player = leader(for: category) else { return nil }
            return (category, player)
        }
    }
    
    /// Get the default team leaders (PPG, RPG, APG)
    func defaultLeaders() -> [(category: StatisticalCategory, player: Player)] {
        leaders(for: [.pointsPerGame, .reboundsPerGame, .assistsPerGame])
    }
}

/// Enum representing statistical categories for leaders
enum StatisticalCategory: String, CaseIterable {
    case pointsPerGame = "PPG"
    case reboundsPerGame = "RPG"
    case assistsPerGame = "APG"
    case stealsPerGame = "SPG"
    case blocksPerGame = "BPG"
    case fieldGoalPercentage = "FG%"
    case threePointPercentage = "3P%"
    case freeThrowPercentage = "FT%"
    
    /// Display name for the category
    var displayName: String {
        switch self {
        case .pointsPerGame: return "Points Per Game"
        case .reboundsPerGame: return "Rebounds Per Game"
        case .assistsPerGame: return "Assists Per Game"
        case .stealsPerGame: return "Steals Per Game"
        case .blocksPerGame: return "Blocks Per Game"
        case .fieldGoalPercentage: return "Field Goal %"
        case .threePointPercentage: return "3-Point %"
        case .freeThrowPercentage: return "Free Throw %"
        }
    }
    
    /// Short abbreviation for the category
    var abbreviation: String {
        rawValue
    }
    
    /// Get the value for this category from a player
    func value(for player: Player) -> Double {
        switch self {
        case .pointsPerGame: return player.pointsPerGame
        case .reboundsPerGame: return player.reboundsPerGame
        case .assistsPerGame: return player.assistsPerGame
        case .stealsPerGame: return player.stealsPerGame
        case .blocksPerGame: return player.blocksPerGame
        case .fieldGoalPercentage: return player.fieldGoalPercentage
        case .threePointPercentage: return player.threePointPercentage
        case .freeThrowPercentage: return player.freeThrowPercentage
        }
    }
}

// MARK: - Player Extensions for Additional Stats

extension Player {
    /// Steals per game
    var stealsPerGame: Double {
        statistic(named: "Steals")?.value ?? statistic(named: "Steals Per Game")?.value ?? 0.0
    }
    
    /// Blocks per game
    var blocksPerGame: Double {
        statistic(named: "Blocks")?.value ?? statistic(named: "Blocks Per Game")?.value ?? 0.0
    }
    
    /// Field goal percentage
    var fieldGoalPercentage: Double {
        statistic(named: "FG%")?.value ?? statistic(named: "Field Goal Percentage")?.value ?? 0.0
    }
    
    /// Three point percentage
    var threePointPercentage: Double {
        statistic(named: "3P%")?.value ?? statistic(named: "Three Point Percentage")?.value ?? 0.0
    }
    
    /// Free throw percentage
    var freeThrowPercentage: Double {
        statistic(named: "FT%")?.value ?? statistic(named: "Free Throw Percentage")?.value ?? 0.0
    }
}
