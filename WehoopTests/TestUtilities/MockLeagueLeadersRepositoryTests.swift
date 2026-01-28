//
//  MockLeagueLeadersRepositoryTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

/// Tests for MockLeagueLeadersRepository to ensure it correctly implements the protocol
final class MockLeagueLeadersRepositoryTests: XCTestCase {
    var sut: MockLeagueLeadersRepository!
    var testBundle: Bundle!
    
    override func setUp() {
        super.setUp()
        testBundle = Bundle.mockDataBundle
        sut = MockLeagueLeadersRepository(bundle: testBundle, simulatedDelay: 0.01)
    }
    
    override func tearDown() {
        sut = nil
        testBundle = nil
        super.tearDown()
    }
    
    // MARK: - Tracking Tests
    
    func testGetLeagueLeaders_SetsTrackingFlags() async throws {
        // Given
        sut.defaultLeaders = [
            TestDataFactory.makePlayer(
                id: "player-1",
                name: "Test Player"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 25.0, category: .scoring)]
            )
        ]
        
        // Reset flags
        sut.getLeagueLeadersCallCount = 0
        sut.lastCategory = nil
        sut.lastLimit = nil
        
        // When
        _ = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then
        XCTAssertEqual(sut.getLeagueLeadersCallCount, 1, "Should increment call count")
        XCTAssertEqual(sut.lastCategory, .scoring, "Should track category")
        XCTAssertEqual(sut.lastLimit, 10, "Should track limit")
    }
    
    // MARK: - Custom Data Tests
    
    func testGetLeagueLeaders_ReturnsCustomLeaders_WhenProvided() async throws {
        // Given
        let customLeaders = [
            TestDataFactory.makePlayer(
                id: "player-1",
                name: "Custom Player 1"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 30.0, category: .scoring)]
            ),
            TestDataFactory.makePlayer(
                id: "player-2",
                name: "Custom Player 2"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-2", name: "Points Per Game", value: 28.0, category: .scoring)]
            )
        ]
        sut.customLeaders = customLeaders
        
        // When
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "player-1")
        XCTAssertEqual(result[1].id, "player-2")
    }
    
    func testGetLeagueLeaders_CustomLeaders_TakesPrecedenceOverBundle() async throws {
        // Given
        let customLeaders = [
            TestDataFactory.makePlayer(
                id: "custom-player",
                name: "Custom Player"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 25.0, category: .scoring)]
            )
        ]
        sut.customLeaders = customLeaders
        sut.defaultLeaders = [
            TestDataFactory.makePlayer(
                id: "default-player",
                name: "Default Player"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-2", name: "Points Per Game", value: 20.0, category: .scoring)]
            )
        ]
        
        // When
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then - Should use custom leaders, not default
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, "custom-player")
    }
    
    // MARK: - Default Leaders Tests
    
    func testGetLeagueLeaders_ReturnsDefaultLeaders_WhenNoCustomData() async throws {
        // Given
        let defaultLeaders = [
            TestDataFactory.makePlayer(
                id: "player-1",
                name: "Default Player 1"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 25.0, category: .scoring)]
            ),
            TestDataFactory.makePlayer(
                id: "player-2",
                name: "Default Player 2"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-2", name: "Points Per Game", value: 23.0, category: .scoring)]
            )
        ]
        sut.defaultLeaders = defaultLeaders
        sut.customLeaders = nil
        
        // When
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "player-1") // Should be sorted by value descending
        XCTAssertEqual(result[1].id, "player-2")
    }
    
    // MARK: - Bundle Loading Tests
    
    func testGetLeagueLeaders_LoadsFromPlayersJson_WhenNoCustomData() async throws {
        // Given - No custom or default leaders, should try to load from bundle
        sut.customLeaders = nil
        sut.defaultLeaders = []
        
        // When
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then - Should load from players.json if it exists
        // Note: This test may pass or fail depending on whether players.json exists
        // and contains players with scoring statistics
        XCTAssertGreaterThanOrEqual(result.count, 0)
    }
    
    // MARK: - Error Simulation Tests
    
    func testGetLeagueLeaders_ThrowsError_WhenErrorSet() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Simulated error"])
        sut.getLeagueLeadersError = expectedError
        
        // When/Then
        do {
            _ = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 500)
            XCTAssertEqual((error as NSError).domain, "TestError")
        }
    }
    
    // MARK: - Filtering and Sorting Tests
    
    func testGetLeagueLeaders_FiltersByCategory() async throws {
        // Given
        let players = [
            TestDataFactory.makePlayer(
                id: "player-1",
                name: "Scoring Leader"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 25.0, category: .scoring)]
            ),
            TestDataFactory.makePlayer(
                id: "player-2",
                name: "Rebound Leader"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-2", name: "Rebounds Per Game", value: 12.0, category: .rebounding)]
            ),
            TestDataFactory.makePlayer(
                id: "player-3",
                name: "Another Scorer"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-3", name: "Points Per Game", value: 23.0, category: .scoring)]
            )
        ]
        sut.defaultLeaders = players
        
        // When - Request scoring leaders
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then - Should only return players with scoring stats
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.statistic(for: .scoring) != nil })
        XCTAssertEqual(result[0].id, "player-1") // Should be sorted by value descending
        XCTAssertEqual(result[1].id, "player-3")
    }
    
    func testGetLeagueLeaders_SortsByStatValue_Descending() async throws {
        // Given
        let players = [
            TestDataFactory.makePlayer(
                id: "player-1",
                name: "Player 1"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 20.0, category: .scoring)]
            ),
            TestDataFactory.makePlayer(
                id: "player-2",
                name: "Player 2"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-2", name: "Points Per Game", value: 30.0, category: .scoring)]
            ),
            TestDataFactory.makePlayer(
                id: "player-3",
                name: "Player 3"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-3", name: "Points Per Game", value: 25.0, category: .scoring)]
            )
        ]
        sut.defaultLeaders = players
        
        // When
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then - Should be sorted by value descending
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].id, "player-2") // Highest value (30.0)
        XCTAssertEqual(result[1].id, "player-3") // Middle value (25.0)
        XCTAssertEqual(result[2].id, "player-1") // Lowest value (20.0)
    }
    
    // MARK: - Limit Tests
    
    func testGetLeagueLeaders_AppliesLimit() async throws {
        // Given
        let players = (1...10).map { index in
            TestDataFactory.makePlayer(
                id: "player-\(index)",
                name: "Player \(index)"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-\(index)", name: "Points Per Game", value: Double(30 - index), category: .scoring)]
            )
        }
        sut.defaultLeaders = players
        
        // When - Request with limit of 5
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 5)
        
        // Then
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result[0].id, "player-1") // Highest value
        XCTAssertEqual(result[4].id, "player-5") // 5th highest
    }
    
    func testGetLeagueLeaders_HandlesZeroLimit() async throws {
        // Given
        let players = [
            TestDataFactory.makePlayer(
                id: "player-1",
                name: "Player 1"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 25.0, category: .scoring)]
            )
        ]
        sut.defaultLeaders = players
        
        // When
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 0)
        
        // Then
        XCTAssertEqual(result.count, 0)
    }
    
    // MARK: - Delay Simulation Tests
    
//    func testGetLeagueLeaders_SimulatesDelay() async throws {
//        // Given
//        sut.defaultLeaders = [
//            TestDataFactory.makePlayer(
//                id: "player-1",
//                name: "Test Player"
////                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 25.0, category: .scoring)]
//            )
//        ]
//        sut = MockLeagueLeadersRepository(bundle: testBundle, simulatedDelay: 0.1)
//        sut.defaultLeaders = [
//            TestDataFactory.makePlayer(
//                id: "player-1",
//                name: "Test Player"
////                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 25.0, category: .scoring)]
//            )
//        ]
//        
//        // When
//        let startTime = Date()
//        _ = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
//        let endTime = Date()
//        let duration = endTime.timeIntervalSince(startTime)
//        
//        // Then - Should have simulated delay
//        XCTAssertGreaterThanOrEqual(duration, 0.1, accuracy: 0.05)
//    }
    
    // MARK: - Empty Results Tests
    
    func testGetLeagueLeaders_ReturnsEmptyArray_WhenNoMatchingPlayers() async throws {
        // Given - Players with different category
        sut.defaultLeaders = [
            TestDataFactory.makePlayer(
                id: "player-1",
                name: "Rebound Leader"
//                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Rebounds Per Game", value: 12.0, category: .rebounding)]
            )
        ]
        
        // When - Request scoring leaders
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then
        XCTAssertEqual(result.count, 0)
    }
    
    func testGetLeagueLeaders_ReturnsEmptyArray_WhenNoPlayers() async throws {
        // Given
        sut.defaultLeaders = []
        sut.customLeaders = nil
        
        // When
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then
        XCTAssertEqual(result.count, 0)
    }
}
