//
//  GetPlayerProfileUseCaseTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class GetPlayerProfileUseCaseTests: XCTestCase {
    var sut: GetPlayerProfileUseCase!
    var mockRepository: MockPlayerRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockPlayerRepository()
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    func testExecute_ReturnsPlayer_WhenRepositorySucceeds() async throws {
        // Given
        let playerId = "player1"
        let expectedPlayer = TestDataFactory.makePlayer(id: playerId, name: "John Doe")
        mockRepository.players = [expectedPlayer]
        sut = GetPlayerProfileUseCase(playerRepository: mockRepository, playerId: playerId)
        
        // When
        let result = try await sut.execute()
        
        // Then
        XCTAssertEqual(result.id, "player1")
        XCTAssertEqual(result.name, "John Doe")
        XCTAssertEqual(mockRepository.getPlayerCallCount, 1)
    }
    
    func testExecute_ThrowsError_WhenPlayerNotFound() async {
        // Given
        let playerId = "nonexistent"
        mockRepository.players = []
        sut = GetPlayerProfileUseCase(playerRepository: mockRepository, playerId: playerId)
        
        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(mockRepository.getPlayerCallCount, 1)
        }
    }
    
    func testExecute_ThrowsError_WhenRepositoryFails() async {
        // Given
        let playerId = "player1"
        let expectedError = NSError(domain: "TestError", code: 500)
        mockRepository.getPlayerError = expectedError
        sut = GetPlayerProfileUseCase(playerRepository: mockRepository, playerId: playerId)
        
        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 500)
            XCTAssertEqual(mockRepository.getPlayerCallCount, 1)
        }
    }
}
