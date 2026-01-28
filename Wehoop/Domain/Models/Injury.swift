//
//  Injury.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Domain model for a player injury
struct Injury: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let comment: String?
    let description: String
    let status: InjuryStatus
    let startDate: Date?
    let updateDate: Date?
    
    /// Computed property to check if injury is currently active
    var isActive: Bool {
        status != .resolved
    }
    
    /// Computed property for formatted start date
    var formattedStartDate: String? {
        guard let date = startDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Computed property for formatted update date
    var formattedUpdateDate: String? {
        guard let date = updateDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

/// Injury status enumeration
enum InjuryStatus: String, Codable, CaseIterable {
    case dayToDay = "Day To Day"
    case out = "Out"
    case outForSeason = "Out For Season"
    case questionable = "Questionable"
    case probable = "Probable"
    case resolved = "Resolved"
    
    /// Display name for the status
    var displayName: String {
        rawValue
    }
    
    /// Severity level (1 = least severe, 5 = most severe)
    var severity: Int {
        switch self {
        case .probable: return 1
        case .questionable: return 2
        case .dayToDay: return 3
        case .out: return 4
        case .outForSeason: return 5
        case .resolved: return 0
        }
    }
}

/// Domain model for a player with injuries
struct PlayerWithInjuries: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let fullName: String
    let firstName: String?
    let lastName: String?
    let position: String
    let primaryPosition: String?
    let jerseyNumber: String?
    let injuries: [Injury]
    
    /// Computed property to check if player has active injuries
    var hasActiveInjuries: Bool {
        injuries.contains { $0.isActive }
    }
    
    /// Get the most severe active injury
    var mostSevereInjury: Injury? {
        injuries
            .filter { $0.isActive }
            .max { $0.status.severity < $1.status.severity }
    }
}

/// Domain model for team injuries
struct TeamInjuries: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let franchiseId: String?
    let players: [PlayerWithInjuries]
    
    /// Computed property to get count of players with active injuries
    var activeInjuryCount: Int {
        players.filter { $0.hasActiveInjuries }.count
    }
}

/// Domain model for league injuries response
struct LeagueInjuries: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let alias: String?
    let teams: [TeamInjuries]
    
    /// Computed property to get total count of players with active injuries
    var totalActiveInjuries: Int {
        teams.reduce(0) { $0 + $1.activeInjuryCount }
    }
    
    /// Get all players with active injuries across all teams
    var allPlayersWithInjuries: [PlayerWithInjuries] {
        teams.flatMap { $0.players }.filter { $0.hasActiveInjuries }
    }
}
