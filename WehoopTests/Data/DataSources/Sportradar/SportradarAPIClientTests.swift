//
//  SportradarAPIClientTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class SportradarAPIClientTests: XCTestCase {
    var apiConfiguration: APIConfiguration!
    var client: SportradarAPIClient!
    
    override func setUp() {
        super.setUp()
        
        // Create a test configuration with known values
        // We'll create it directly since we can't rely on Info.plist in tests
        apiConfiguration = try! APIConfiguration(
            bundle: Bundle.main,
            apiKeyHeaderName: "x-api-key",
            apiVersion: "v8"
        )
        
        // If that fails, we'll skip tests that require it
        guard apiConfiguration != nil else {
            return
        }
        
        client = SportradarAPIClient(
            apiConfiguration: apiConfiguration,
            accessLevel: .trial,
            language: .english
        )
    }
    
    // MARK: - URL Pattern Tests
    
    func testDailyChanges_URLPattern() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        
        // Given
        let date = DateComponents(calendar: .current, year: 2026, month: 1, day: 16).date!
        
        // When
        let url = client.dailyChanges(date: date)
        
        // Then
        XCTAssertTrue(url.contains("trial/v8/en/league/2026/01/16/changes.json"), 
                     "URL should match Sportradar pattern")
        XCTAssertTrue(url.hasPrefix("https://"), "Should use HTTPS")
        print("✅ Daily Changes URL: \(url)")
    }
    
    func testURLPattern_MatchesExample() throws {
        // Given - Example URL: https://api.sportradar.com/unrivaled/trial/v8/en/league/2026/01/16/changes.json
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        
        let date = DateComponents(calendar: .current, year: 2026, month: 1, day: 16).date!
        
        // When
        let url = client.dailyChanges(date: date)
        
        // Then
        let expectedPattern = "trial/v8/en/league/2026/01/16/changes.json"
        XCTAssertTrue(url.contains(expectedPattern), 
                     "URL should contain: \(expectedPattern)")
        // Check that URL contains the pattern (base URL might vary)
        let urlParts = url.components(separatedBy: "/")
        XCTAssertTrue(urlParts.contains("trial"))
        XCTAssertTrue(urlParts.contains("v8"))
        XCTAssertTrue(urlParts.contains("en"))
        XCTAssertTrue(urlParts.contains("league"))
        XCTAssertTrue(urlParts.contains("2026"))
        XCTAssertTrue(urlParts.contains("01"))
        XCTAssertTrue(urlParts.contains("16"))
        XCTAssertTrue(url.contains("changes.json"))
    }
    
    // MARK: - Daily Endpoints Tests
    
    func testDailyInjuries_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let date = Date()
        let url = client.dailyInjuries(date: date)
        XCTAssertTrue(url.contains("injuries.json"))
        XCTAssertTrue(url.contains("trial/v8/en/league"))
    }
    
    func testDailySchedule_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let date = DateComponents(calendar: .current, year: 2026, month: 1, day: 12).date!
        let url = client.dailySchedule(date: date)
        
        // Verify endpoint and resource type
        XCTAssertTrue(url.contains("schedule.json"), "Should contain schedule.json endpoint")
        XCTAssertTrue(url.contains("trial/v8/en/games"), "Should use 'games' resource type, not 'league'")
        XCTAssertTrue(url.contains("2026/01/12"), "Should contain formatted date")
        XCTAssertFalse(url.contains("/league/"), "Should NOT contain 'league' in the path")
        
        // Verify exact URL pattern
        let expectedPattern = "trial/v8/en/games/2026/01/12/schedule.json"
        XCTAssertTrue(url.contains(expectedPattern), 
                     "URL should match pattern: \(expectedPattern)")
        print("✅ Daily Schedule URL: \(url)")
    }
    
    func testDailyTransfers_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let date = Date()
        let url = client.dailyTransfers(date: date)
        XCTAssertTrue(url.contains("transfers.json"))
        XCTAssertTrue(url.contains("trial/v8/en/league"))
    }
    
    // MARK: - Game Endpoints Tests
    
    func testGameBoxscore_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.gameBoxscore(gameId: "test-game-id")
        XCTAssertTrue(url.contains("boxscore.json"))
        XCTAssertTrue(url.contains("test-game-id"))
        XCTAssertTrue(url.contains("trial/v8/en/games"))
    }
    
    func testGameBoxscore_MatchesExampleURL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        
        // Given - Example URL: https://api.sportradar.com/unrivaled/trial/v8/en/games/838316ea-ab7b-4581-a1dd-74229d1970d5/boxscore.json
        let gameId = "838316ea-ab7b-4581-a1dd-74229d1970d5"
        
        // When
        let url = client.gameBoxscore(gameId: gameId)
        
        // Then
        let expectedURL = "https://api.sportradar.com/unrivaled/trial/v8/en/games/\(gameId)/boxscore.json"
        XCTAssertEqual(url, expectedURL, "URL should match exact example format")
        print("✅ Game Boxscore URL: \(url)")
        print("   Expected: \(expectedURL)")
    }
    
    func testGameSummary_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.gameSummary(gameId: "test-game-id")
        XCTAssertTrue(url.contains("summary.json"))
        XCTAssertTrue(url.contains("test-game-id"))
    }
    
    func testGamePlayByPlay_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.gamePlayByPlay(gameId: "test-game-id")
        XCTAssertTrue(url.contains("pbp.json"))
        XCTAssertTrue(url.contains("test-game-id"))
    }
    
    // MARK: - Team Endpoints Tests
    
    func testTeams_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.teams()
        XCTAssertTrue(url.contains("teams.json"))
      XCTAssertTrue(url.contains("v8/en/league/teams"))
    }
    
    func testTeamProfile_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.teamProfile(teamId: "test-team-id")
        XCTAssertTrue(url.contains("profile.json"))
        XCTAssertTrue(url.contains("test-team-id"))
        XCTAssertTrue(url.contains("trial/v8/en/teams"))
    }
    
    func testTeamRoster_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.teamRoster(teamId: "test-team-id")
        XCTAssertTrue(url.contains("roster.json"))
        XCTAssertTrue(url.contains("test-team-id"))
    }
    
    // MARK: - Player Endpoints Tests
    
    func testPlayerProfile_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.playerProfile(playerId: "test-player-id")
        XCTAssertTrue(url.contains("profile.json"))
        XCTAssertTrue(url.contains("test-player-id"))
        XCTAssertTrue(url.contains("trial/v8/en/players"))
    }
    
    // MARK: - League Endpoints Tests
    
    func testLeagueHierarchy_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.leagueHierarchy()
        XCTAssertTrue(url.contains("hierarchy.json"))
        XCTAssertTrue(url.contains("trial/v8/en/league"))
    }
    
    func testLeagueLeaders_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.leagueLeaders(seasonYear: "2026", seasonType: "REG")
        XCTAssertTrue(url.contains("leaders.json"))
        XCTAssertTrue(url.contains("trial/v8/en/seasons/2026/REG"))
    }
    
    func testStandings_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.standings()
        XCTAssertTrue(url.contains("standings.json"))
        XCTAssertTrue(url.contains("trial/v8/en/league"))
    }
    
    func testRankings_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.rankings()
        XCTAssertTrue(url.contains("rankings.json"))
        XCTAssertTrue(url.contains("trial/v8/en/league"))
    }
    
    func testSeasonalStatistics_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.seasonalStatistics(seasonId: "2026")
        XCTAssertTrue(url.contains("statistics.json"))
        XCTAssertTrue(url.contains("2026"))
        XCTAssertTrue(url.contains("trial/v8/en/league"))
    }
    
    func testSeasonalStatistics_WithSeasonType_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.seasonalStatistics(seasonId: "2026", seasonType: "regular")
        XCTAssertTrue(url.contains("statistics.json"))
        XCTAssertTrue(url.contains("2026/regular"))
    }
    
    // MARK: - Season Endpoints Tests
    
    func testSeasons_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.seasons()
        XCTAssertTrue(url.contains("seasons.json"))
        XCTAssertTrue(url.contains("trial/v8/en/league"))
    }
    
    // MARK: - Series Endpoints Tests
    
    func testSeriesSchedule_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.seriesSchedule(seriesId: "test-series-id")
        XCTAssertTrue(url.contains("schedule.json"))
        XCTAssertTrue(url.contains("test-series-id"))
        XCTAssertTrue(url.contains("trial/v8/en/series"))
    }
    
    func testSeriesStatistics_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.seriesStatistics(seriesId: "test-series-id")
        XCTAssertTrue(url.contains("statistics.json"))
        XCTAssertTrue(url.contains("test-series-id"))
    }
    
    // MARK: - Tournament Endpoints Tests
    
    func testTournamentList_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.tournamentList(seasonId: "2026")
        XCTAssertTrue(url.contains("list.json"))
        XCTAssertTrue(url.contains("2026"))
        XCTAssertTrue(url.contains("trial/v8/en/tournaments"))
    }
    
    func testTournamentSchedule_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.tournamentSchedule(tournamentId: "test-tournament-id")
        XCTAssertTrue(url.contains("schedule.json"))
        XCTAssertTrue(url.contains("test-tournament-id"))
    }
    
    func testTournamentSummary_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.tournamentSummary(tournamentId: "test-tournament-id")
        XCTAssertTrue(url.contains("summary.json"))
        XCTAssertTrue(url.contains("test-tournament-id"))
    }
    
    // MARK: - Injury Endpoints Tests
    
    func testInjuries_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.injuries()
        XCTAssertTrue(url.contains("injuries.json"))
        XCTAssertTrue(url.contains("trial/v8/en/league"))
    }
    
    // MARK: - Schedule Endpoints Tests
    
    func testSchedule_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.schedule(seasonId: "2026")
        XCTAssertTrue(url.contains("schedule.json"))
        XCTAssertTrue(url.contains("2026"))
    }
    
    // MARK: - Configuration Tests
    
    func testAccessLevel_Production() throws {
        guard let apiConfiguration = apiConfiguration else {
            throw XCTSkip("APIConfiguration not available")
        }
        let productionClient = SportradarAPIClient(
            apiConfiguration: apiConfiguration,
            accessLevel: .production,
            language: .english
        )
        let url = productionClient.teams()
        XCTAssertTrue(url.contains("production/v8"), "Should use production access level")
    }
    
    func testDateFormatting() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let date = DateComponents(calendar: .current, year: 2026, month: 1, day: 16).date!
        let url = client.dailyChanges(date: date)
        XCTAssertTrue(url.contains("2026/01/16"), "Date should be formatted as YYYY/MM/DD")
    }
}
