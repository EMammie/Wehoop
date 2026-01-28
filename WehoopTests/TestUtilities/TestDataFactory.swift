//
//  TestDataFactory.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import Foundation
@testable import Wehoop

/// Factory for creating test data
struct TestDataFactory {
    static func makeTeam(
        id: String = "team1",
        name: String = "Test Team",
        abbreviation: String = "TT",
        city: String? = "Test City",
        conference: Conference? = .eastern
    ) -> Team {
        Team(
            id: id,
            name: name,
            abbreviation: abbreviation,
            logoURL: nil,
            city: city,
            conference: conference,
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
    }
    
    static func makePlayer(
        id: String = "player1",
        name: String = "Test Player",
        team: Team? = nil,
        position: String = "PG",
        jerseyNumber: Int? = 1,
        college: String? = nil
    ) -> Player {
        Player(
            id: id,
            name: name,
            team: team ?? makeTeam(),
            position: position,
            statistics: [],
            jerseyNumber: jerseyNumber,
            height: nil,
            weight: nil,
            age: nil,
            college: college,
            photoURL: nil
        )
    }
    
    static func makeGame(
        id: String = "game1",
        homeTeam: Team? = nil,
        awayTeam: Team? = nil,
        status: GameStatus = .scheduled,
        date: Date = Date(),
        venue: String? = nil
    ) -> Game {
        Game(
            id: id,
            homeTeam: homeTeam ?? makeTeam(id: "home", name: "Home Team"),
            awayTeam: awayTeam ?? makeTeam(id: "away", name: "Away Team"),
            date: date,
            status: status,
            boxScore: nil,
            venue: venue,
            league: nil,
            broadcastNetwork: nil,
            timeZone: nil
        )
    }
    
    static func makeBoxScore(
        homeScore: Int = 100,
        awayScore: Int = 95,
        quarters: [QuarterScore]? = nil
    ) -> BoxScore {
        BoxScore(
            homeScore: homeScore,
            awayScore: awayScore,
            homeStats: TeamStats(
                points: homeScore,
                rebounds: 40,
                assists: 25,
                steals: nil,
                blocks: nil,
                turnovers: nil,
                fieldGoalPercentage: nil,
                threePointPercentage: nil,
                freeThrowPercentage: nil,
                fouls: nil
            ),
            awayStats: TeamStats(
                points: awayScore,
                rebounds: 35,
                assists: 20,
                steals: nil,
                blocks: nil,
                turnovers: nil,
                fieldGoalPercentage: nil,
                threePointPercentage: nil,
                freeThrowPercentage: nil,
                fouls: nil
            ),
            quarters: quarters,
            lastUpdated: Date()
        )
    }
    
    static func makeStatistic(
        id: String = "stat1",
        name: String = "Points",
        value: Double = 25.5,
        category: StatCategory = .scoring,
        unit: StatUnit? = .points
    ) -> Statistic {
        Statistic(
            id: id,
            name: name,
            value: value,
            category: category,
            unit: unit,
            season: nil,
            gamesPlayed: nil
        )
    }
    
    static func makeQuarterScore(
        quarterNumber: Int = 1,
        homeScore: Int = 25,
        awayScore: Int = 20
    ) -> QuarterScore {
        QuarterScore(
            id: "Q\(quarterNumber)",
            homeScore: homeScore,
            awayScore: awayScore,
            quarterNumber: quarterNumber
        )
    }
}

