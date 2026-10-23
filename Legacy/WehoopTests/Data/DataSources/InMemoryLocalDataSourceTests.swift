//
//  InMemoryLocalDataSourceTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class InMemoryLocalDataSourceTests: XCTestCase {
    var sut: InMemoryLocalDataSource!
    
    override func setUp() {
        super.setUp()
        sut = InMemoryLocalDataSource()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Save and Load Games Tests
    
    func testSaveGames_StoresData() throws {
        // Given
        let testData = "test games data".data(using: .utf8)!
        
        // When
        try sut.saveGames(testData)
        
        // Then
        let loadedData = try sut.loadGames()
        XCTAssertEqual(loadedData, testData)
    }
    
    func testLoadGames_ReturnsNil_WhenNoDataSaved() throws {
        // When
        let result = try sut.loadGames()
        
        // Then
        XCTAssertNil(result)
    }
    
    func testSaveGames_OverwritesPreviousData() throws {
        // Given
        let firstData = "first games data".data(using: .utf8)!
        let secondData = "second games data".data(using: .utf8)!
        
        // When
        try sut.saveGames(firstData)
        try sut.saveGames(secondData)
        
        // Then
        let loadedData = try sut.loadGames()
        XCTAssertEqual(loadedData, secondData)
        XCTAssertNotEqual(loadedData, firstData)
    }
    
    // MARK: - Save and Load Players Tests
    
    func testSavePlayers_StoresData() throws {
        // Given
        let testData = "test players data".data(using: .utf8)!
        
        // When
        try sut.savePlayers(testData)
        
        // Then
        let loadedData = try sut.loadPlayers()
        XCTAssertEqual(loadedData, testData)
    }
    
    func testLoadPlayers_ReturnsNil_WhenNoDataSaved() throws {
        // When
        let result = try sut.loadPlayers()
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - Save and Load Teams Tests
    
    func testSaveTeams_StoresData() throws {
        // Given
        let testData = "test teams data".data(using: .utf8)!
        
        // When
        try sut.saveTeams(testData)
        
        // Then
        let loadedData = try sut.loadTeams()
        XCTAssertEqual(loadedData, testData)
    }
    
    func testLoadTeams_ReturnsNil_WhenNoDataSaved() throws {
        // When
        let result = try sut.loadTeams()
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - Save and Load Box Score Tests
    
    func testSaveBoxScore_StoresData() throws {
        // Given
        let gameId = "game-123"
        let testData = "test box score data".data(using: .utf8)!
        
        // When
        try sut.saveBoxScore(testData, gameId: gameId)
        
        // Then
        let loadedData = try sut.loadBoxScore(gameId: gameId)
        XCTAssertEqual(loadedData, testData)
    }
    
    func testLoadBoxScore_ReturnsNil_WhenNoDataSaved() throws {
        // When
        let result = try sut.loadBoxScore(gameId: "nonexistent-game")
        
        // Then
        XCTAssertNil(result)
    }
    
    func testSaveBoxScore_StoresMultipleBoxScores() throws {
        // Given
        let gameId1 = "game-1"
        let gameId2 = "game-2"
        let data1 = "box score 1".data(using: .utf8)!
        let data2 = "box score 2".data(using: .utf8)!
        
        // When
        try sut.saveBoxScore(data1, gameId: gameId1)
        try sut.saveBoxScore(data2, gameId: gameId2)
        
        // Then
        let loaded1 = try sut.loadBoxScore(gameId: gameId1)
        let loaded2 = try sut.loadBoxScore(gameId: gameId2)
        XCTAssertEqual(loaded1, data1)
        XCTAssertEqual(loaded2, data2)
    }
    
    func testSaveBoxScore_OverwritesPreviousData() throws {
        // Given
        let gameId = "game-123"
        let firstData = "first box score".data(using: .utf8)!
        let secondData = "second box score".data(using: .utf8)!
        
        // When
        try sut.saveBoxScore(firstData, gameId: gameId)
        try sut.saveBoxScore(secondData, gameId: gameId)
        
        // Then
        let loadedData = try sut.loadBoxScore(gameId: gameId)
        XCTAssertEqual(loadedData, secondData)
        XCTAssertNotEqual(loadedData, firstData)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess_IsThreadSafe() throws {
        // Given
        let expectation = expectation(description: "Concurrent access completed")
        expectation.expectedFulfillmentCount = 100
        
        // When - perform concurrent saves and loads
        DispatchQueue.concurrentPerform(iterations: 50) { index in
            let data = "data-\(index)".data(using: .utf8)!
            try? sut.saveGames(data)
            _ = try? sut.loadGames()
            expectation.fulfill()
        }
        
        DispatchQueue.concurrentPerform(iterations: 50) { index in
            let gameId = "game-\(index)"
            let data = "boxscore-\(index)".data(using: .utf8)!
            try? sut.saveBoxScore(data, gameId: gameId)
            _ = try? sut.loadBoxScore(gameId: gameId)
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        // If we get here without crashing, thread safety is working
    }
}
