//
//  DTOBuilder.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import Foundation
@testable import Wehoop

// MARK: - TeamDTOBuilder

struct TeamDTOBuilder {
    private var id: String = "team-1"
    private var name: String = "Test Team"
    private var abbreviation: String = "TT"
    private var logoURL: String? = nil
    private var city: String? = nil
    private var conference: String? = nil
    private var division: String? = nil
    private var wins: Int? = nil
    private var losses: Int? = nil
    private var winPercentage: Double? = nil
    
    func withId(_ id: String) -> TeamDTOBuilder {
        var builder = self
        builder.id = id
        return builder
    }
    
    func withName(_ name: String) -> TeamDTOBuilder {
        var builder = self
        builder.name = name
        return builder
    }
    
    func withAbbreviation(_ abbreviation: String) -> TeamDTOBuilder {
        var builder = self
        builder.abbreviation = abbreviation
        return builder
    }
    
    func withLogoURL(_ logoURL: String?) -> TeamDTOBuilder {
        var builder = self
        builder.logoURL = logoURL
        return builder
    }
    
    func withCity(_ city: String?) -> TeamDTOBuilder {
        var builder = self
        builder.city = city
        return builder
    }
    
    func withConference(_ conference: String?) -> TeamDTOBuilder {
        var builder = self
        builder.conference = conference
        return builder
    }
    
    func withDivision(_ division: String?) -> TeamDTOBuilder {
        var builder = self
        builder.division = division
        return builder
    }
    
    func withWins(_ wins: Int?) -> TeamDTOBuilder {
        var builder = self
        builder.wins = wins
        return builder
    }
    
    func withLosses(_ losses: Int?) -> TeamDTOBuilder {
        var builder = self
        builder.losses = losses
        return builder
    }
    
    func withWinPercentage(_ winPercentage: Double?) -> TeamDTOBuilder {
        var builder = self
        builder.winPercentage = winPercentage
        return builder
    }
    
    func build() -> TeamDTO {
        TeamDTO(
            id: id,
            name: name,
            abbreviation: abbreviation,
            logoURL: logoURL,
            city: city,
            conference: conference,
            division: division,
            wins: wins,
            losses: losses,
            winPercentage: winPercentage
        )
    }
}

// MARK: - TeamStatsDTOBuilder

struct TeamStatsDTOBuilder {
    private var points: Int = 100
    private var rebounds: Int = 40
    private var assists: Int = 25
    private var steals: Int? = nil
    private var blocks: Int? = nil
    private var turnovers: Int? = nil
    private var fieldGoalPercentage: Double? = nil
    private var threePointPercentage: Double? = nil
    private var freeThrowPercentage: Double? = nil
    private var fouls: Int? = nil
    
    func withPoints(_ points: Int) -> TeamStatsDTOBuilder {
        var builder = self
        builder.points = points
        return builder
    }
    
    func withRebounds(_ rebounds: Int) -> TeamStatsDTOBuilder {
        var builder = self
        builder.rebounds = rebounds
        return builder
    }
    
    func withAssists(_ assists: Int) -> TeamStatsDTOBuilder {
        var builder = self
        builder.assists = assists
        return builder
    }
    
    func withSteals(_ steals: Int?) -> TeamStatsDTOBuilder {
        var builder = self
        builder.steals = steals
        return builder
    }
    
    func withBlocks(_ blocks: Int?) -> TeamStatsDTOBuilder {
        var builder = self
        builder.blocks = blocks
        return builder
    }
    
    func withTurnovers(_ turnovers: Int?) -> TeamStatsDTOBuilder {
        var builder = self
        builder.turnovers = turnovers
        return builder
    }
    
    func withFieldGoalPercentage(_ percentage: Double?) -> TeamStatsDTOBuilder {
        var builder = self
        builder.fieldGoalPercentage = percentage
        return builder
    }
    
    func withThreePointPercentage(_ percentage: Double?) -> TeamStatsDTOBuilder {
        var builder = self
        builder.threePointPercentage = percentage
        return builder
    }
    
    func withFreeThrowPercentage(_ percentage: Double?) -> TeamStatsDTOBuilder {
        var builder = self
        builder.freeThrowPercentage = percentage
        return builder
    }
    
    func withFouls(_ fouls: Int?) -> TeamStatsDTOBuilder {
        var builder = self
        builder.fouls = fouls
        return builder
    }
    
    func build() -> TeamStatsDTO {
        TeamStatsDTO(
            points: points,
            rebounds: rebounds,
            assists: assists,
            steals: steals,
            blocks: blocks,
            turnovers: turnovers,
            fieldGoalPercentage: fieldGoalPercentage,
            threePointPercentage: threePointPercentage,
            freeThrowPercentage: freeThrowPercentage,
            fouls: fouls
        )
    }
}

// MARK: - StatisticDTOBuilder

struct StatisticDTOBuilder {
    private var id: String = "stat-1"
    private var name: String = "Test Stat"
    private var value: Double = 10.0
    private var category: String = "scoring"
    private var unit: String? = nil
    private var season: String? = nil
    private var gamesPlayed: Int? = nil
    
    func withId(_ id: String) -> StatisticDTOBuilder {
        var builder = self
        builder.id = id
        return builder
    }
    
    func withName(_ name: String) -> StatisticDTOBuilder {
        var builder = self
        builder.name = name
        return builder
    }
    
    func withValue(_ value: Double) -> StatisticDTOBuilder {
        var builder = self
        builder.value = value
        return builder
    }
    
    func withCategory(_ category: String) -> StatisticDTOBuilder {
        var builder = self
        builder.category = category
        return builder
    }
    
    func withUnit(_ unit: String?) -> StatisticDTOBuilder {
        var builder = self
        builder.unit = unit
        return builder
    }
    
    func withSeason(_ season: String?) -> StatisticDTOBuilder {
        var builder = self
        builder.season = season
        return builder
    }
    
    func withGamesPlayed(_ gamesPlayed: Int?) -> StatisticDTOBuilder {
        var builder = self
        builder.gamesPlayed = gamesPlayed
        return builder
    }
    
    func build() -> StatisticDTO {
        StatisticDTO(
            id: id,
            name: name,
            value: value,
            category: category,
            unit: unit,
            season: season,
            gamesPlayed: gamesPlayed
        )
    }
}

// MARK: - BoxScoreDTOBuilder

struct BoxScoreDTOBuilder {
    private var homeScore: Int = 100
    private var awayScore: Int = 95
    private var homeStats: TeamStatsDTO? = nil
    private var awayStats: TeamStatsDTO? = nil
    private var quarters: [QuarterScoreDTO]? = nil
    private var lastUpdated: String? = nil
    
    func withHomeScore(_ score: Int) -> BoxScoreDTOBuilder {
        var builder = self
        builder.homeScore = score
        return builder
    }
    
    func withAwayScore(_ score: Int) -> BoxScoreDTOBuilder {
        var builder = self
        builder.awayScore = score
        return builder
    }
    
    func withHomeStats(_ stats: TeamStatsDTO) -> BoxScoreDTOBuilder {
        var builder = self
        builder.homeStats = stats
        return builder
    }
    
    func withHomeStats(_ builder: (TeamStatsDTOBuilder) -> TeamStatsDTOBuilder) -> BoxScoreDTOBuilder {
        var boxScoreBuilder = self
        let statsBuilder = TeamStatsDTOBuilder()
        boxScoreBuilder.homeStats = builder(statsBuilder).build()
        return boxScoreBuilder
    }
    
    func withAwayStats(_ stats: TeamStatsDTO) -> BoxScoreDTOBuilder {
        var builder = self
        builder.awayStats = stats
        return builder
    }
    
    func withAwayStats(_ builder: (TeamStatsDTOBuilder) -> TeamStatsDTOBuilder) -> BoxScoreDTOBuilder {
        var boxScoreBuilder = self
        let statsBuilder = TeamStatsDTOBuilder()
        boxScoreBuilder.awayStats = builder(statsBuilder).build()
        return boxScoreBuilder
    }
    
    func withQuarters(_ quarters: [QuarterScoreDTO]?) -> BoxScoreDTOBuilder {
        var builder = self
        builder.quarters = quarters
        return builder
    }
    
    func withQuarters(_ quarters: [QuarterScoreDTO]) -> BoxScoreDTOBuilder {
        var builder = self
        builder.quarters = quarters
        return builder
    }
    
    func withStandardQuarters(
        q1: (home: Int, away: Int) = (25, 20),
        q2: (home: Int, away: Int) = (25, 25),
        q3: (home: Int, away: Int) = (30, 25),
        q4: (home: Int, away: Int) = (20, 25)
    ) -> BoxScoreDTOBuilder {
        var builder = self
        builder.quarters = [
            QuarterScoreDTOBuilder().withQuarterNumber(1).withHomeScore(q1.home).withAwayScore(q1.away).build(),
            QuarterScoreDTOBuilder().withQuarterNumber(2).withHomeScore(q2.home).withAwayScore(q2.away).build(),
            QuarterScoreDTOBuilder().withQuarterNumber(3).withHomeScore(q3.home).withAwayScore(q3.away).build(),
            QuarterScoreDTOBuilder().withQuarterNumber(4).withHomeScore(q4.home).withAwayScore(q4.away).build()
        ]
        return builder
    }
    
    func withLastUpdated(_ lastUpdated: String?) -> BoxScoreDTOBuilder {
        var builder = self
        builder.lastUpdated = lastUpdated
        return builder
    }
    
    func withLastUpdated(_ date: Date) -> BoxScoreDTOBuilder {
        var builder = self
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        builder.lastUpdated = formatter.string(from: date)
        return builder
    }
    
    func build() -> BoxScoreDTO {
        BoxScoreDTO(
            homeScore: homeScore,
            awayScore: awayScore,
            homeStats: homeStats ?? TeamStatsDTOBuilder().withPoints(homeScore).build(),
            awayStats: awayStats ?? TeamStatsDTOBuilder().withPoints(awayScore).build(),
            quarters: quarters,
            lastUpdated: lastUpdated
        )
    }
}

// MARK: - GameDTOBuilder

struct GameDTOBuilder {
    private var id: String = "game-1"
    private var homeTeam: TeamDTO? = nil
    private var awayTeam: TeamDTO? = nil
    private var date: String = "2025-01-15T19:00:00Z"
    private var status: String = "finished"
    private var boxScore: BoxScoreDTO? = nil
    private var venue: String? = nil
    private var league: String? = nil
    private var broadcastNetwork: String? = nil
    private var timeZone: String? = nil
    
    func withId(_ id: String) -> GameDTOBuilder {
        var builder = self
        builder.id = id
        return builder
    }
    
    func withHomeTeam(_ team: TeamDTO) -> GameDTOBuilder {
        var builder = self
        builder.homeTeam = team
        return builder
    }
    
    func withAwayTeam(_ team: TeamDTO) -> GameDTOBuilder {
        var builder = self
        builder.awayTeam = team
        return builder
    }
    
    func withDate(_ date: String) -> GameDTOBuilder {
        var builder = self
        builder.date = date
        return builder
    }
    
    func withStatus(_ status: String) -> GameDTOBuilder {
        var builder = self
        builder.status = status
        return builder
    }
    
    func withBoxScore(_ boxScore: BoxScoreDTO?) -> GameDTOBuilder {
        var builder = self
        builder.boxScore = boxScore
        return builder
    }
    
    func withVenue(_ venue: String?) -> GameDTOBuilder {
        var builder = self
        builder.venue = venue
        return builder
    }
    
    func withLeague(_ league: String?) -> GameDTOBuilder {
        var builder = self
        builder.league = league
        return builder
    }
    
    func withBroadcastNetwork(_ broadcastNetwork: String?) -> GameDTOBuilder {
        var builder = self
        builder.broadcastNetwork = broadcastNetwork
        return builder
    }
    
    func withTimeZone(_ timeZone: String?) -> GameDTOBuilder {
        var builder = self
        builder.timeZone = timeZone
        return builder
    }
    
    func build() -> GameDTO {
        let defaultTeam = TeamDTOBuilder().build()
        return GameDTO(
            id: id,
            homeTeam: homeTeam ?? defaultTeam,
            awayTeam: awayTeam ?? defaultTeam,
            date: date,
            status: status,
            boxScore: boxScore,
            venue: venue,
            league: league,
            broadcastNetwork: broadcastNetwork,
            timeZone: timeZone
        )
    }
}

// MARK: - PlayerDTOBuilder

struct PlayerDTOBuilder {
    private var id: String = "player-1"
    private var name: String = "Test Player"
    private var team: TeamDTO? = nil
    private var position: String = "PG"
    private var statistics: [StatisticDTO] = []
    private var jerseyNumber: Int? = nil
    private var height: String? = nil
    private var weight: Int? = nil
    private var age: Int? = nil
    private var college: String? = nil
    private var photoURL: String? = nil
    
    func withId(_ id: String) -> PlayerDTOBuilder {
        var builder = self
        builder.id = id
        return builder
    }
    
    func withName(_ name: String) -> PlayerDTOBuilder {
        var builder = self
        builder.name = name
        return builder
    }
    
    func withTeam(_ team: TeamDTO) -> PlayerDTOBuilder {
        var builder = self
        builder.team = team
        return builder
    }
    
    func withPosition(_ position: String) -> PlayerDTOBuilder {
        var builder = self
        builder.position = position
        return builder
    }
    
    func withStatistics(_ statistics: [StatisticDTO]) -> PlayerDTOBuilder {
        var builder = self
        builder.statistics = statistics
        return builder
    }
    
    func withJerseyNumber(_ jerseyNumber: Int?) -> PlayerDTOBuilder {
        var builder = self
        builder.jerseyNumber = jerseyNumber
        return builder
    }
    
    func withHeight(_ height: String?) -> PlayerDTOBuilder {
        var builder = self
        builder.height = height
        return builder
    }
    
    func withWeight(_ weight: Int?) -> PlayerDTOBuilder {
        var builder = self
        builder.weight = weight
        return builder
    }
    
    func withAge(_ age: Int?) -> PlayerDTOBuilder {
        var builder = self
        builder.age = age
        return builder
    }
    
    func withCollege(_ college: String?) -> PlayerDTOBuilder {
        var builder = self
        builder.college = college
        return builder
    }
    
    func withPhotoURL(_ photoURL: String?) -> PlayerDTOBuilder {
        var builder = self
        builder.photoURL = photoURL
        return builder
    }
    
    func build() -> PlayerDTO {
        PlayerDTO(
            id: id,
            name: name,
            team: team ?? TeamDTOBuilder().build(),
            position: position,
            statistics: statistics,
            jerseyNumber: jerseyNumber,
            height: height,
            weight: weight,
            age: age,
            college: college,
            photoURL: photoURL
        )
    }
}

// MARK: - QuarterScoreDTOBuilder

struct QuarterScoreDTOBuilder {
    private var id: String = "Q1"
    private var homeScore: Int = 25
    private var awayScore: Int = 20
    private var quarterNumber: Int = 1
    
    func withId(_ id: String) -> QuarterScoreDTOBuilder {
        var builder = self
        builder.id = id
        return builder
    }
    
    func withHomeScore(_ score: Int) -> QuarterScoreDTOBuilder {
        var builder = self
        builder.homeScore = score
        return builder
    }
    
    func withAwayScore(_ score: Int) -> QuarterScoreDTOBuilder {
        var builder = self
        builder.awayScore = score
        return builder
    }
    
    func withQuarterNumber(_ number: Int) -> QuarterScoreDTOBuilder {
        var builder = self
        builder.quarterNumber = number
        builder.id = "Q\(number)"
        return builder
    }
    
    func build() -> QuarterScoreDTO {
        QuarterScoreDTO(
            id: id,
            homeScore: homeScore,
            awayScore: awayScore,
            quarterNumber: quarterNumber
        )
    }
}
