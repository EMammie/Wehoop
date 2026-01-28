//
//  JSONLocalDataSourceTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class JSONLocalDataSourceTests: XCTestCase {
    var sut: JSONLocalDataSource!
    var testBundle: Bundle!
    
    override func setUp() {
        super.setUp()
        // Find the bundle containing MockData resources
        testBundle = Bundle.mockDataBundle
        sut = JSONLocalDataSource(bundle: testBundle)
    }
    
    override func tearDown() {
        sut = nil
        testBundle = nil
        super.tearDown()
    }
    
    func testLoadGames_ReturnsData_WhenFileExists() throws {
        // When
        let result = try sut.loadGames()
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result?.count ?? 0, 0)
    }
    
    func testLoadPlayers_ReturnsData_WhenFileExists() throws {
        // When
        let result = try sut.loadPlayers()
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result?.count ?? 0, 0)
    }
    
    func testLoadTeams_ReturnsData_WhenFileExists() throws {
        // When
        let result = try sut.loadTeams()
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result?.count ?? 0, 0)
    }
    
    func testLoadBoxScore_ReturnsData_WhenGameIdExists() throws {
        // Given
        let gameId = "game-1"
        
        // When
        let result = try sut.loadBoxScore(gameId: gameId)
        
        // Then
        XCTAssertNotNil(result)
        
        // Verify it's valid JSON and doesn't contain gameId field
        if let data = result,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            XCTAssertNil(json["gameId"], "BoxScore data should not contain gameId field")
            XCTAssertNotNil(json["homeScore"])
            XCTAssertNotNil(json["awayScore"])
        }
    }
    
    func testLoadBoxScore_ReturnsNil_WhenGameIdDoesNotExist() throws {
        // Given
        let gameId = "nonexistent-game-id"
        
        // When
        let result = try sut.loadBoxScore(gameId: gameId)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testLoadGames_ReturnsValidJSON() throws {
        // When
        let data = try sut.loadGames()
        
        // Then
        XCTAssertNotNil(data)
        
        // Verify it's valid JSON array
        if let data = data {
            let json = try JSONSerialization.jsonObject(with: data)
            XCTAssertTrue(json is [[String: Any]], "Games data should be a JSON array")
        }
    }
    
    func testLoadPlayers_ReturnsValidJSON() throws {
        // When
        let data = try sut.loadPlayers()
        
        // Then
        XCTAssertNotNil(data)
        
        // Verify it's valid JSON array
        if let data = data {
            let json = try JSONSerialization.jsonObject(with: data)
            XCTAssertTrue(json is [[String: Any]], "Players data should be a JSON array")
        }
    }
    
    func testLoadTeams_ReturnsValidJSON() throws {
        // When
        let data = try sut.loadTeams()
        
        // Then
        XCTAssertNotNil(data)
        
        // Verify it's valid JSON array
        if let data = data {
            let json = try JSONSerialization.jsonObject(with: data)
            XCTAssertTrue(json is [[String: Any]], "Teams data should be a JSON array")
        }
    }
}
