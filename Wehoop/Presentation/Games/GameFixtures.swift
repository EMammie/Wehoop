//
//  GameFixtures.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Fixture class for creating Game-related test data for previews and tests
class GameFixtures {
    
    // MARK: - Teams
    
    static func mistBC() -> Team {
        Team(
            id: "team-1",
            name: "Mist BC",
            abbreviation: "MST",
            logoURL: "https://example.com/logos/mist-bc.png",
            city: "Miami",
            conference: .eastern,
            division: "Southeast",
            wins: 12,
            losses: 3,
            winPercentage: 0.800
        )
    }
    
    static func lunarOwlsBC() -> Team {
        Team(
            id: "team-2",
            name: "Lunar Owls BC",
            abbreviation: "LOW",
            logoURL: "https://example.com/logos/lunar-owls-bc.png",
            city: "Miami",
            conference: .eastern,
            division: "Southeast",
            wins: 11,
            losses: 4,
            winPercentage: 0.733
        )
    }
    
    static func roseBC() -> Team {
        Team(
            id: "team-3",
            name: "Rose BC",
            abbreviation: "ROS",
            logoURL: "https://example.com/logos/rose-bc.png",
            city: "Miami",
            conference: .eastern,
            division: "Southeast",
            wins: 10,
            losses: 5,
            winPercentage: 0.667
        )
    }
    
    static func vinylBC() -> Team {
        Team(
            id: "team-4",
            name: "Vinyl BC",
            abbreviation: "VIN",
            logoURL: "https://example.com/logos/vinyl-bc.png",
            city: "Miami",
            conference: .eastern,
            division: "Southeast",
            wins: 9,
            losses: 6,
            winPercentage: 0.600
        )
    }
    
    static func phantomBC() -> Team {
        Team(
            id: "team-5",
            name: "Phantom BC",
            abbreviation: "PHA",
            logoURL: "https://example.com/logos/phantom-bc.png",
            city: "Miami",
            conference: .eastern,
            division: "Southeast",
            wins: 8,
            losses: 7,
            winPercentage: 0.533
        )
    }
    
    static func lacesBC() -> Team {
        Team(
            id: "team-6",
            name: "Laces BC",
            abbreviation: "LAC",
            logoURL: "https://example.com/logos/laces-bc.png",
            city: "Miami",
            conference: .eastern,
            division: "Southeast",
            wins: 7,
            losses: 8,
            winPercentage: 0.467
        )
    }
    
    static func breeze() -> Team {
        Team(
            id: "team-7",
            name: "Breeze",
            abbreviation: "BRZ",
            logoURL: "https://example.com/logos/breeze.png",
            city: "Miami",
            conference: .eastern,
            division: "Southeast",
            wins: 6,
            losses: 9,
            winPercentage: 0.400
        )
    }
    
    static func hive() -> Team {
        Team(
            id: "team-8",
            name: "Hive",
            abbreviation: "HIV",
            logoURL: "https://example.com/logos/hive.png",
            city: "Miami",
            conference: .eastern,
            division: "Southeast",
            wins: 5,
            losses: 10,
            winPercentage: 0.333
        )
    }
    
    // MARK: - Team Stats
    
    static func teamStats(
        points: Int = 62,
        rebounds: Int = 28,
        assists: Int = 14,
        steals: Int? = 6,
        blocks: Int? = 3,
        turnovers: Int? = 8,
        fieldGoalPercentage: Double? = 48.5,
        threePointPercentage: Double? = 38.2,
        freeThrowPercentage: Double? = 82.1,
        fouls: Int? = 12
    ) -> TeamStats {
        TeamStats(
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
    
    // MARK: - Quarter Scores
    
    static func quarterScore(
        id: String,
        homeScore: Int,
        awayScore: Int,
        quarterNumber: Int
    ) -> QuarterScore {
        QuarterScore(
            id: id,
            homeScore: homeScore,
            awayScore: awayScore,
            quarterNumber: quarterNumber
        )
    }
    
    static func standardQuarters() -> [QuarterScore] {
        [
            quarterScore(id: "Q1", homeScore: 16, awayScore: 14, quarterNumber: 1),
            quarterScore(id: "Q2", homeScore: 15, awayScore: 16, quarterNumber: 2),
            quarterScore(id: "Q3", homeScore: 18, awayScore: 15, quarterNumber: 3),
            quarterScore(id: "Q4", homeScore: 13, awayScore: 13, quarterNumber: 4)
        ]
    }
    
    // MARK: - Box Scores
    
    static func boxScore(
        homeScore: Int = 62,
        awayScore: Int = 58,
        homeStats: TeamStats? = nil,
        awayStats: TeamStats? = nil,
        quarters: [QuarterScore]? = nil,
        lastUpdated: Date? = nil
    ) -> BoxScore {
        BoxScore(
            homeScore: homeScore,
            awayScore: awayScore,
            homeStats: homeStats ?? teamStats(points: homeScore),
            awayStats: awayStats ?? teamStats(points: awayScore, rebounds: 26, assists: 12, steals: 4, blocks: 2, turnovers: 10, fieldGoalPercentage: 45.2, threePointPercentage: 35.8, freeThrowPercentage: 78.5, fouls: 14),
            quarters: quarters ?? standardQuarters(),
            lastUpdated: lastUpdated ?? Date()
        )
    }
    
    // MARK: - Games
    
    static func finishedGame() -> Game {
        Game(
            id: "game-1",
            homeTeam: mistBC(),
            awayTeam: lunarOwlsBC(),
            date: Date().addingTimeInterval(-3600), // 1 hour ago
            status: .finished,
            boxScore: boxScore(),
            venue: "Unrivaled Arena",
            league: "Unrivaled",
            broadcastNetwork: nil,
            timeZone: nil
        )
    }
    
    static func liveGame() -> Game {
        Game(
            id: "game-2",
            homeTeam: roseBC(),
            awayTeam: vinylBC(),
            date: Date(),
            status: .live,
            boxScore: boxScore(
                homeScore: 45,
                awayScore: 48,
                homeStats: teamStats(points: 45, rebounds: 22, assists: 10, steals: 3, blocks: 2, turnovers: 6, fieldGoalPercentage: 44.2, threePointPercentage: 36.5, freeThrowPercentage: 80.0, fouls: 8),
                awayStats: teamStats(points: 48, rebounds: 24, assists: 11, steals: 5, blocks: 3, turnovers: 5, fieldGoalPercentage: 50.8, threePointPercentage: 42.1, freeThrowPercentage: 85.7, fouls: 9),
                quarters: [
                    quarterScore(id: "Q1", homeScore: 12, awayScore: 14, quarterNumber: 1),
                    quarterScore(id: "Q2", homeScore: 11, awayScore: 13, quarterNumber: 2),
                    quarterScore(id: "Q3", homeScore: 12, awayScore: 11, quarterNumber: 3),
                    quarterScore(id: "Q4", homeScore: 10, awayScore: 10, quarterNumber: 4)
                ]
            ),
            venue: "Unrivaled Arena",
            league: "Unrivaled",
            broadcastNetwork: nil,
            timeZone: nil
        )
    }
    
    static func scheduledGame() -> Game {
        Game(
            id: "game-3",
            homeTeam: mistBC(),
            awayTeam: roseBC(),
            date: Date().addingTimeInterval(86400), // Tomorrow
            status: .scheduled,
            boxScore: nil,
            venue: "Unrivaled Arena",
            league: "Unrivaled",
            broadcastNetwork: "TNT",
            timeZone: "US/Eastern"
        )
    }
    
    static func postponedGame() -> Game {
        Game(
            id: "game-4",
            homeTeam: lunarOwlsBC(),
            awayTeam: vinylBC(),
            date: Date().addingTimeInterval(172800), // 2 days from now
            status: .postponed,
            boxScore: nil,
            venue: "Unrivaled Arena",
            league: "Unrivaled",
            broadcastNetwork: nil,
            timeZone: nil
        )
    }
    
    static func cancelledGame() -> Game {
        Game(
            id: "game-5",
            homeTeam: roseBC(),
            awayTeam: mistBC(),
            date: Date().addingTimeInterval(259200), // 3 days from now
            status: .cancelled,
            boxScore: nil,
            venue: "Unrivaled Arena",
            league: "Unrivaled",
            broadcastNetwork: nil,
            timeZone: nil
        )
    }
    
    static func gameWithCloseScore() -> Game {
        Game(
            id: "game-6",
            homeTeam: mistBC(),
            awayTeam: lunarOwlsBC(),
            date: Date().addingTimeInterval(-7200), // 2 hours ago
            status: .finished,
            boxScore: boxScore(homeScore: 61, awayScore: 60),
            venue: "Unrivaled Arena",
            league: "Unrivaled",
            broadcastNetwork: nil,
            timeZone: nil
        )
    }
    
    static func gameWithHighScore() -> Game {
        Game(
            id: "game-7",
            homeTeam: roseBC(),
            awayTeam: vinylBC(),
            date: Date().addingTimeInterval(-1800), // 30 minutes ago
            status: .finished,
            boxScore: boxScore(homeScore: 75, awayScore: 68),
            venue: "Unrivaled Arena",
            league: "Unrivaled",
            broadcastNetwork: nil,
            timeZone: nil
        )
    }
    
    // MARK: - Game Collections
    
    static func sampleGames() -> [Game] {
        [
            liveGame(),
            finishedGame(),
            scheduledGame(),
            gameWithCloseScore(),
            gameWithHighScore()
        ]
    }
    
    static func liveGames() -> [Game] {
        [liveGame()]
    }
    
    static func finishedGames() -> [Game] {
        [finishedGame(), gameWithCloseScore(), gameWithHighScore()]
    }
    
    static func scheduledGames() -> [Game] {
        [scheduledGame(), postponedGame()]
    }
    
    // MARK: - Players
    
    static func samplePlayer(
        id: String = "player-1",
        name: String,
        team: Team,
        position: String = "Guard",
        jerseyNumber: Int? = nil,
        age: Int? = nil,
        height: String? = nil,
        weight: Int? = nil,
        college: String? = nil,
        statistics: [Statistic] = []
    ) -> Player {
        Player(
            id: id,
            name: name,
            team: team,
            position: position,
            statistics: statistics,
            jerseyNumber: jerseyNumber,
            height: height,
            weight: weight,
            age: age,
            college: college,
            photoURL: nil
        )
    }
    
    // MARK: - Mist BC Players
    
    static func alyssaTornas() -> Player {
        samplePlayer(
            id: "player-1",
            name: "Alyssa Tornas",
            team: mistBC(),
            position: "Point Guard",
            jerseyNumber: 1,
            age: 25,
            height: "5'8\"",
            weight: 150,
            college: "UConn",
            statistics: [
                Statistic(
                    id: "stat-ppg-1",
                    name: "Points Per Game",
                    value: 18.5,
                    category: .scoring,
                    unit: .points,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-apg-1",
                    name: "Assists Per Game",
                    value: 8.2,
                    category: .assists,
                    unit: .assists,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-rpg-1",
                    name: "Rebounds Per Game",
                    value: 4.3,
                    category: .rebounding,
                    unit: .rebounds,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-spg-1",
                    name: "Steals Per Game",
                    value: 2.1,
                    category: .defense,
                    unit: .steals,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-fg-1",
                    name: "Field Goal Percentage",
                    value: 45.8,
                    category: .shooting,
                    unit: .percentage,
                    season: "2024-25",
                    gamesPlayed: 15
                )
            ]
        )
    }
    
    static func breannaStewart() -> Player {
        samplePlayer(
            id: "player-2",
            name: "Breanna Stewart",
            team: mistBC(),
            position: "Forward",
            jerseyNumber: 30,
            age: 28,
            height: "6'4\"",
            weight: 170,
            college: "UConn",
            statistics: [
                Statistic(
                    id: "stat-ppg-2",
                    name: "Points Per Game",
                    value: 22.3,
                    category: .scoring,
                    unit: .points,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-rpg-2",
                    name: "Rebounds Per Game",
                    value: 9.8,
                    category: .rebounding,
                    unit: .rebounds,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-apg-2",
                    name: "Assists Per Game",
                    value: 3.5,
                    category: .assists,
                    unit: .assists,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-bpg-2",
                    name: "Blocks Per Game",
                    value: 1.8,
                    category: .defense,
                    unit: .blocks,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-fg-2",
                    name: "Field Goal Percentage",
                    value: 52.4,
                    category: .shooting,
                    unit: .percentage,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-3pt-2",
                    name: "Three Point Percentage",
                    value: 38.7,
                    category: .shooting,
                    unit: .percentage,
                    season: "2024-25",
                    gamesPlayed: 15
                )
            ]
        )
    }
    
    static func sabrinaIonescu() -> Player {
        samplePlayer(
            id: "player-4",
            name: "Sabrina Ionescu",
            team: mistBC(),
            position: "Guard",
            jerseyNumber: 20,
            age: 26,
            height: "5'11\"",
            weight: 165,
            college: "Oregon",
            statistics: [
                Statistic(
                    id: "stat-ppg-4",
                    name: "Points Per Game",
                    value: 19.2,
                    category: .scoring,
                    unit: .points,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-apg-4",
                    name: "Assists Per Game",
                    value: 7.8,
                    category: .assists,
                    unit: .assists,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-rpg-4",
                    name: "Rebounds Per Game",
                    value: 5.6,
                    category: .rebounding,
                    unit: .rebounds,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-3pt-4",
                    name: "Three Point Percentage",
                    value: 41.2,
                    category: .shooting,
                    unit: .percentage,
                    season: "2024-25",
                    gamesPlayed: 15
                )
            ]
        )
    }
    
    // MARK: - Rose BC Players
    
    static func rickeaJackson() -> Player {
        samplePlayer(
            id: "player-3",
            name: "Rickea Jackson",
            team: roseBC(),
            position: "Forward",
            jerseyNumber: 23,
            age: 22,
            height: "6'2\"",
            weight: 180,
            college: "Tennessee",
            statistics: [
                Statistic(
                    id: "stat-ppg-3",
                    name: "Points Per Game",
                    value: 23.7,
                    category: .scoring,
                    unit: .points,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-rpg-3",
                    name: "Rebounds Per Game",
                    value: 8.4,
                    category: .rebounding,
                    unit: .rebounds,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-apg-3",
                    name: "Assists Per Game",
                    value: 2.9,
                    category: .assists,
                    unit: .assists,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-fg-3",
                    name: "Field Goal Percentage",
                    value: 48.9,
                    category: .shooting,
                    unit: .percentage,
                    season: "2024-25",
                    gamesPlayed: 15
                )
            ]
        )
    }
    
    static func caitlinClark() -> Player {
        samplePlayer(
            id: "player-5",
            name: "Caitlin Clark",
            team: roseBC(),
            position: "Guard",
            jerseyNumber: 22,
            age: 22,
            height: "6'0\"",
            weight: 155,
            college: "Iowa",
            statistics: [
                Statistic(
                    id: "stat-ppg-5",
                    name: "Points Per Game",
                    value: 25.3,
                    category: .scoring,
                    unit: .points,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-apg-5",
                    name: "Assists Per Game",
                    value: 9.1,
                    category: .assists,
                    unit: .assists,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-rpg-5",
                    name: "Rebounds Per Game",
                    value: 6.2,
                    category: .rebounding,
                    unit: .rebounds,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-3pt-5",
                    name: "Three Point Percentage",
                    value: 39.5,
                    category: .shooting,
                    unit: .percentage,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-spg-5",
                    name: "Steals Per Game",
                    value: 1.9,
                    category: .defense,
                    unit: .steals,
                    season: "2024-25",
                    gamesPlayed: 15
                )
            ]
        )
    }
    
    // MARK: - Lunar Owls BC Players
    
    static func angelReese() -> Player {
        samplePlayer(
            id: "player-6",
            name: "Angel Reese",
            team: lunarOwlsBC(),
            position: "Forward",
            jerseyNumber: 10,
            age: 21,
            height: "6'3\"",
            weight: 190,
            college: "LSU",
            statistics: [
                Statistic(
                    id: "stat-ppg-6",
                    name: "Points Per Game",
                    value: 20.8,
                    category: .scoring,
                    unit: .points,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-rpg-6",
                    name: "Rebounds Per Game",
                    value: 12.4,
                    category: .rebounding,
                    unit: .rebounds,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-bpg-6",
                    name: "Blocks Per Game",
                    value: 1.5,
                    category: .defense,
                    unit: .blocks,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-fg-6",
                    name: "Field Goal Percentage",
                    value: 50.2,
                    category: .shooting,
                    unit: .percentage,
                    season: "2024-25",
                    gamesPlayed: 15
                )
            ]
        )
    }
    
    static func paigeBueckers() -> Player {
        samplePlayer(
            id: "player-7",
            name: "Paige Bueckers",
            team: lunarOwlsBC(),
            position: "Guard",
            jerseyNumber: 5,
            age: 22,
            height: "5'11\"",
            weight: 160,
            college: "UConn",
            statistics: [
                Statistic(
                    id: "stat-ppg-7",
                    name: "Points Per Game",
                    value: 21.4,
                    category: .scoring,
                    unit: .points,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-apg-7",
                    name: "Assists Per Game",
                    value: 6.7,
                    category: .assists,
                    unit: .assists,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-rpg-7",
                    name: "Rebounds Per Game",
                    value: 4.8,
                    category: .rebounding,
                    unit: .rebounds,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-fg-7",
                    name: "Field Goal Percentage",
                    value: 47.3,
                    category: .shooting,
                    unit: .percentage,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-3pt-7",
                    name: "Three Point Percentage",
                    value: 42.1,
                    category: .shooting,
                    unit: .percentage,
                    season: "2024-25",
                    gamesPlayed: 15
                )
            ]
        )
    }
    
    // MARK: - Vinyl BC Players
    
    static func cameronBrink() -> Player {
        samplePlayer(
            id: "player-8",
            name: "Cameron Brink",
            team: vinylBC(),
            position: "Center",
            jerseyNumber: 22,
            age: 23,
            height: "6'4\"",
            weight: 175,
            college: "Stanford",
            statistics: [
                Statistic(
                    id: "stat-ppg-8",
                    name: "Points Per Game",
                    value: 17.6,
                    category: .scoring,
                    unit: .points,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-rpg-8",
                    name: "Rebounds Per Game",
                    value: 10.2,
                    category: .rebounding,
                    unit: .rebounds,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-bpg-8",
                    name: "Blocks Per Game",
                    value: 2.8,
                    category: .defense,
                    unit: .blocks,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-fg-8",
                    name: "Field Goal Percentage",
                    value: 54.7,
                    category: .shooting,
                    unit: .percentage,
                    season: "2024-25",
                    gamesPlayed: 15
                )
            ]
        )
    }
    
    static func haleyJones() -> Player {
        samplePlayer(
            id: "player-9",
            name: "Haley Jones",
            team: vinylBC(),
            position: "Guard",
            jerseyNumber: 11,
            age: 23,
            height: "6'1\"",
            weight: 170,
            college: "Stanford",
            statistics: [
                Statistic(
                    id: "stat-ppg-9",
                    name: "Points Per Game",
                    value: 16.9,
                    category: .scoring,
                    unit: .points,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-apg-9",
                    name: "Assists Per Game",
                    value: 5.4,
                    category: .assists,
                    unit: .assists,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-rpg-9",
                    name: "Rebounds Per Game",
                    value: 7.3,
                    category: .rebounding,
                    unit: .rebounds,
                    season: "2024-25",
                    gamesPlayed: 15
                ),
                Statistic(
                    id: "stat-fg-9",
                    name: "Field Goal Percentage",
                    value: 46.8,
                    category: .shooting,
                    unit: .percentage,
                    season: "2024-25",
                    gamesPlayed: 15
                )
            ]
        )
    }
    
    // MARK: - Player Collections
    
    static func topPlayers() -> [Player] {
        [
            caitlinClark(),
            rickeaJackson(),
            breannaStewart(),
            angelReese(),
            alyssaTornas()
        ]
    }
    
    static func allPlayers() -> [Player] {
        [
            // Mist BC
            alyssaTornas(),
            breannaStewart(),
            sabrinaIonescu(),
            // Rose BC
            rickeaJackson(),
            caitlinClark(),
            // Lunar Owls BC
            angelReese(),
            paigeBueckers(),
            // Vinyl BC
            cameronBrink(),
            haleyJones()
        ]
    }
    
    static func playersByTeam(_ team: Team) -> [Player] {
        allPlayers().filter { $0.team.id == team.id }
    }
}
