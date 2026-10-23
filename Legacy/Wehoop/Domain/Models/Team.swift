//
//  Team.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Domain model for a team
struct Team: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let abbreviation: String
    let logoURL: String?
    let city: String?
    let conference: Conference?
    let division: String?
    let wins: Int?
    let losses: Int?
    let winPercentage: Double?
    
    /// Computed property for full team name with city
    var fullName: String {
        if let city = city {
            return "\(city) \(name)"
        }
        return name
    }
    
    /// Computed property for win-loss record
    var record: String? {
        guard let wins = wins, let losses = losses else {
            return nil
        }
        return "\(wins)-\(losses)"
    }
    
    /// Computed property for formatted win percentage
    var formattedWinPercentage: String? {
        guard let winPercentage = winPercentage else {
            return nil
        }
        return String(format: "%.3f", winPercentage)
    }
}

enum Conference: String, Codable, CaseIterable {
    case eastern = "Eastern"
    case western = "Western"
    
    var abbreviation: String {
        switch self {
        case .eastern: return "EAST"
        case .western: return "WEST"
        }
    }
}
