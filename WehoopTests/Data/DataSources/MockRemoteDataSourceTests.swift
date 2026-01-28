//
//  MockRemoteDataSourceTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class MockRemoteDataSourceTests: XCTestCase {
    var sut: MockRemoteDataSource!
    var testBundle: Bundle!
    
    override func setUp() {
        super.setUp()
        // Find the bundle containing MockData resources
        testBundle = Bundle.mockDataBundle
        // Use minimal delay for tests, pass the bundle explicitly
        sut = MockRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
    }
    
    override func tearDown() {
        sut = nil
        testBundle = nil
        super.tearDown()
    }
    
    func testFetchGames_ReturnsData_WhenFileExists() async throws {
        // Debug: Print bundle diagnostics if test fails
        // Uncomment the line below to see detailed bundle information
        // BundleDiagnostics.printBundleInfo()
        
        // When
        let result = try await sut.fetchGames()
        
        // Then
        XCTAssertGreaterThan(result.count, 0, "Games data should not be empty. Bundle used: \(testBundle.bundlePath)")
        
        // Verify it's valid JSON
        let json = try JSONSerialization.jsonObject(with: result)
        XCTAssertTrue(json is [[String: Any]], "Games data should be a JSON array")
    }
    
    func testFetchPlayers_ReturnsData_WhenFileExists() async throws {
        // When
        let result = try await sut.fetchPlayers()
        
        // Then
        XCTAssertGreaterThan(result.count, 0)
        
        // Verify it's valid JSON
        let json = try JSONSerialization.jsonObject(with: result)
        XCTAssertTrue(json is [[String: Any]], "Players data should be a JSON array")
    }
    
    func testFetchTeams_ReturnsData_WhenFileExists() async throws {
        // When
        let result = try await sut.fetchTeams()
        
        // Then
        XCTAssertGreaterThan(result.count, 0)
        
        // Verify it's valid JSON
        let json = try JSONSerialization.jsonObject(with: result)
        XCTAssertTrue(json is [[String: Any]], "Teams data should be a JSON array")
    }
    
    func testFetchBoxScore_ReturnsData_WhenGameIdExists() async throws {
        // Given
        let gameId = "game-1"
        
        // When
        let result = try await sut.fetchBoxScore(gameId: gameId)
        
        // Then
        XCTAssertGreaterThan(result.count, 0)
        
        // Verify it's valid JSON and doesn't contain gameId field
        let json = try JSONSerialization.jsonObject(with: result) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertNil(json?["gameId"], "BoxScore data should not contain gameId field")
        XCTAssertNotNil(json?["homeScore"])
        XCTAssertNotNil(json?["awayScore"])
    }
    
    func testFetchBoxScore_ThrowsError_WhenGameIdDoesNotExist() async {
        // Given
        let gameId = "nonexistent-game-id"
        
        // When/Then
        do {
            _ = try await sut.fetchBoxScore(gameId: gameId)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("BoxScore not found"))
        }
    }
    
    func testFetchGames_SimulatesNetworkDelay() async throws {
        // Given
        let startTime = Date()
        let delay: TimeInterval = 0.1
        let dataSource = MockRemoteDataSource(bundle: testBundle, simulatedDelay: delay)
        
        // When
        _ = try await dataSource.fetchGames()
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        // Then
      XCTAssertGreaterThanOrEqualWithAccuracy(elapsedTime, delay, accuracy: 0.05)
    }
    
    func testFetchGames_ThrowsError_WhenFileDoesNotExist() async {
        // Given
        let invalidBundle = Bundle()
        let dataSource = MockRemoteDataSource(bundle: invalidBundle, simulatedDelay: 0.01)
        
        // When/Then
        do {
            _ = try await dataSource.fetchGames()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("not found"))
        }
    }
}
