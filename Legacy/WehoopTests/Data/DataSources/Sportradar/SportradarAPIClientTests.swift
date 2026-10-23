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
    
    
    
    // MARK: - Daily Endpoints Tests
    
    
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
    
    
    // MARK: - Game Endpoints Tests
    
    
    
    func testGameSummary_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.gameSummary(gameId: "test-game-id")
        XCTAssertTrue(url.contains("summary.json"))
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
    
    
    
    
    
    
    
    
    
    
    // MARK: - Injury Endpoints Tests
    
    func testInjuries_URL() throws {
        guard let client = client else {
            throw XCTSkip("APIConfiguration not available")
        }
        let url = client.injuries()
        XCTAssertTrue(url.contains("injuries.json"))
        XCTAssertTrue(url.contains("trial/v8/en/league"))
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
        let url = client.dailySchedule(date: date)
        XCTAssertTrue(url.contains("2026/01/16"), "Date should be formatted as YYYY/MM/DD")
    }
}
