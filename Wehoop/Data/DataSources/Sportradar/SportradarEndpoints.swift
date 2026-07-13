//
//  SportradarEndpoints.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Sportradar API endpoint definitions and path components
enum SportradarEndpoints {
    /// Access level for API (trial or production)
    enum AccessLevel: String {
        case trial = "trial"
        case production = "production"
    }
    
    /// Language code for API responses
    enum Language: String {
        case english = "en"
        // Add other languages as needed
    }
    
    /// Resource types in the API
    enum ResourceType: String {
        case league = "league"
        case teams = "teams"
        case players = "players"
        case games = "games"
    }

    /// Endpoint file names, mapped via `endpointPath` because several
    /// endpoints share the same file name (e.g. profile.json)
    enum Endpoint {
        case dailySchedule
        case gameSummary
        case teams
        case teamProfile
        case playerProfile
        case teamRoster
        case leagueHierarchy
        case leagueLeaders
        case standings
        case injuries

        var endpointPath: String {
            switch self {
            case .dailySchedule:
                return "schedule.json"
            case .gameSummary:
                return "summary.json"
            case .teams:
                return "teams.json"
            case .teamProfile, .playerProfile:
                return "profile.json"
            case .teamRoster:
                return "roster.json"
            case .leagueHierarchy:
                return "hierarchy.json"
            case .leagueLeaders:
                return "leaders.json"
            case .standings:
                return "standings.json"
            case .injuries:
                return "injuries.json"
            }
        }
    }
}
