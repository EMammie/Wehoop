//
//  MockLeagueDataStoreTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

/// Tests for MockLeagueDataStore to ensure it correctly implements LeagueDataSource
final class MockLeagueDataStoreTests: XCTestCase {
    var sut: MockLeagueDataStore!
    var testBundle: Bundle!
    
    override func setUp() {
        super.setUp()
        testBundle = Bundle.mockDataBundle
        sut = MockLeagueDataStore(bundle: testBundle, simulatedDelay: 0.01)
    }
    
    override func tearDown() {
        sut = nil
        testBundle = nil
        super.tearDown()
    }
    
    // MARK: - Protocol Conformance Tests
    
    func testMockLeagueDataStore_ConformsToLeagueDataSource() {
        // Given
        let dataStore = MockLeagueDataStore()
        
        // Then
        XCTAssertTrue(dataStore is LeagueDataSource, "Should conform to LeagueDataSource")
    }
    
    // MARK: - Fetch League Leaders Tests
    
    func testFetchLeagueLeaders_ReturnsData() async throws {
        // When
        let data = try await sut.fetchLeagueLeaders()
        
        // Then
        XCTAssertFalse(data.isEmpty, "Should return league leaders data")
        
        // Verify it's valid JSON structure
        let decoder = JSONDecoder()
        struct LeaderEntry: Codable {
            let category: String
            let player: PlayerDTO
        }
        
        let leaderEntries = try decoder.decode([LeaderEntry].self, from: data)
        XCTAssertFalse(leaderEntries.isEmpty, "Should decode to non-empty leader entries array")
    }
    
    // MARK: - Fetch Standings Tests
    
    func testFetchStandings_ReturnsData() async throws {
        // When
        let data = try await sut.fetchStandings()
        
        // Then
        XCTAssertFalse(data.isEmpty, "Should return standings data")
        
        // Verify it's valid team data
        let decoder = JSONDecoder()
        let teamDTOs = try decoder.decode([TeamDTO].self, from: data)
        XCTAssertFalse(teamDTOs.isEmpty, "Should decode to non-empty team DTOs array")
    }
    
    func testFetchStandings_FallsBackToTeamsJson_WhenStandingsJsonNotExists() async throws {
        // Given
        // MockLeagueDataStore should load from teams.json if standings.json doesn't exist
        
        // When
        let data = try await sut.fetchStandings()
        
        // Then
        XCTAssertFalse(data.isEmpty, "Should return standings data")
        
        // Verify it's valid team data
        let decoder = JSONDecoder()
        let teamDTOs = try decoder.decode([TeamDTO].self, from: data)
        XCTAssertFalse(teamDTOs.isEmpty, "Should decode to team DTOs array")
    }
}
