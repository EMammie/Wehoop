//
//  Game.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Domain model for a game
struct Game: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let homeTeam: Team
    let awayTeam: Team
    let date: Date
    let status: GameStatus
    let boxScore: BoxScore?
    let venue: String?
    let league: String?
    let broadcastNetwork: String?
    let timeZone: String?
    
    /// Computed property to check if game is currently live
    var isLive: Bool {
        status == .live
    }
    
    /// Computed property to check if game has finished
    var isFinished: Bool {
        status == .finished
    }
    
    /// Computed property to get the winning team
    var winningTeam: Team? {
        guard let boxScore = boxScore, status == .finished else {
            return nil
        }
        return boxScore.homeScore > boxScore.awayScore ? homeTeam : awayTeam
    }
    
    /// Computed property to get the losing team
    var losingTeam: Team? {
        guard let boxScore = boxScore, status == .finished else {
            return nil
        }
        return boxScore.homeScore < boxScore.awayScore ? homeTeam : awayTeam
    }
    
    /// Computed property to format the score display
    var scoreDisplay: String {
        guard let boxScore = boxScore else {
            return "TBD"
        }
        return "\(boxScore.homeScore) - \(boxScore.awayScore)"
    }
}

enum GameStatus: String, Codable, CaseIterable {
    case scheduled
    case live
    case finished
    case postponed
    case cancelled
    
    /// Display name for the status
    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .live: return "Live"
        case .finished: return "Final"
        case .postponed: return "Postponed"
        case .cancelled: return "Cancelled"
        }
    }
}
