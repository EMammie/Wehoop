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
        case tournaments = "tournaments"
        case series = "series"
    }
    
    /// Endpoint paths
    enum Endpoint: String {
        // Daily endpoints
        case dailyChanges = "changes.json"
        case dailyInjuries = "daily_injuries.json"
        case dailySchedule , tournamentSchedule, seriesSchedule = "schedule.json"
        case dailyTransfers = "transfers.json"
        
        // Game endpoints
        case gameBoxscore = "boxscore.json"
        case gameSummary, tournamentSummary = "summary.json"
        case gamePlayByPlay = "pbp.json"
        
        // Team endpoints
        case teams = "teams.json"
        case teamProfile, playerProfile = "profile.json"
        case teamRoster = "roster.json"
        
        // Player endpoints
       // case playerProfile = "profile.json"

        // League endpoints
        case leagueHierarchy = "hierarchy.json"
        case leagueLeaders = "leaders.json"
        case standings = "standings.json"
        case rankings = "rankings.json"
        case seasonalStatistics, seriesStatistics = "statistics.json"
        //case seriesStatistics = "statistics.json"

        // Season endpoints
        case seasons = "seasons.json"
        
        // Tournament endpoints
        case tournamentList = "list.json"
//        case tournamentSchedule = "schedule.json"
//        case tournamentSummary = "summary.json"
        
        // Series endpoints
//        case seriesSchedule = "schedule.json"
        
        // Injury endpoints
        case injuries = "injuries.json"
    }
  
}

extension SportradarEndpoints.Endpoint {
  var endpointPath : String {
    switch self {
    case .dailyChanges:
      return"changes.json"
    case .dailyInjuries:
      return "daily_injuries.json"
    case .dailySchedule , .tournamentSchedule, .seriesSchedule:
      return "schedule.json"
    case .dailyTransfers:
      return "transfers.json"

    // Game endpoints
    case .gameBoxscore:
      return "boxscore.json"
    case .gameSummary, .tournamentSummary:
      return "summary.json"
    case .gamePlayByPlay:
      return "pbp.json"

    // Team endpoints
    case .teams:
      return "teams.json"
    case .teamProfile, .playerProfile:
      return "profile.json"
    case .teamRoster:
      return "roster.json"

    // Player endpoints
   // case playerProfile = "profile.json"

    // League endpoints
    case .leagueHierarchy:
      return "hierarchy.json"
    case .leagueLeaders:
      return "leaders.json"
    case .standings:
      return "standings.json"
    case .rankings:
      return "rankings.json"
    case .seasonalStatistics, .seriesStatistics:
      return "statistics.json"
    //case seriesStatistics = "statistics.json"

    // Season endpoints
    case .seasons :
      return "seasons.json"

    // Tournament endpoints
    case .tournamentList:
      return "list.json"
//        case tournamentSchedule = "schedule.json"
//        case tournamentSummary = "summary.json"

    // Series endpoints
//        case seriesSchedule = "schedule.json"

    // Injury endpoints
    case .injuries :
      return "injuries.json"
    }
  }
}
