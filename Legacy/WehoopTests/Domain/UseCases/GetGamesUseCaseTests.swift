//
//  GetGamesUseCaseTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class GetGamesUseCaseTests: XCTestCase {
    var sut: GetGamesUseCase!
    var mockRepository: MockGameRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockGameRepository()
        sut = GetGamesUseCase(gameRepository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    func testExecute_ReturnsGames_WhenRepositorySucceeds() async throws {
        // Given
        let expectedGames = [
            TestDataFactory.makeGame(id: "game1"),
            TestDataFactory.makeGame(id: "game2")
        ]
        mockRepository.games = expectedGames
        
        // When
        let result = try await sut.execute()
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "game1")
        XCTAssertEqual(result[1].id, "game2")
        XCTAssertEqual(mockRepository.getGamesCallCount, 1)
    }
    
    func testExecute_ThrowsError_WhenRepositoryFails() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: 500)
        mockRepository.getGamesError = expectedError
        
        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 500)
            XCTAssertEqual(mockRepository.getGamesCallCount, 1)
        }
    }
    
    func testExecute_ReturnsEmptyArray_WhenNoGames() async throws {
        // Given
        mockRepository.games = []
        
        // When
        let result = try await sut.execute()
        
        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(mockRepository.getGamesCallCount, 1)
    }
    
    // MARK: - Date Parameter Tests
    
    func testExecute_WithDate_FiltersGamesByDate() async throws {
        // Given
        let calendar = Calendar.current
        let targetDate = Date()
        let gameOnDate = TestDataFactory.makeGame(id: "game1", date: targetDate)
        let gameOnDifferentDate = TestDataFactory.makeGame(
            id: "game2",
            date: calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
        )
        mockRepository.games = [gameOnDate, gameOnDifferentDate]
        
        // When
        let result = try await sut.execute(date: targetDate)
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, "game1")
        XCTAssertEqual(mockRepository.getGamesCallCount, 1)
    }
    
    func testExecute_WithNilDate_ReturnsAllGames() async throws {
        // Given
        let expectedGames = [
            TestDataFactory.makeGame(id: "game1"),
            TestDataFactory.makeGame(id: "game2")
        ]
        mockRepository.games = expectedGames
        
        // When
        let result = try await sut.execute(date: nil)
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(mockRepository.getGamesCallCount, 1)
    }
    
    func testExecute_WithDate_ThrowsError_WhenRepositoryFails() async {
        // Given
        let targetDate = Date()
        let expectedError = NSError(domain: "TestError", code: 500)
        mockRepository.getGamesError = expectedError
        
        // When/Then
        do {
            _ = try await sut.execute(date: targetDate)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 500)
            XCTAssertEqual(mockRepository.getGamesCallCount, 1)
        }
    }
}
