//
//  ManageFavoritesUseCaseTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class ManageFavoritesUseCaseTests: XCTestCase {
    var sut: ManageFavoritesUseCase!
    var mockRepository: MockFavoriteRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockFavoriteRepository()
        sut = ManageFavoritesUseCase(favoriteRepository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    func testAddFavorite_CallsRepository() async throws {
        // Given
        let playerId = "player1"
        
        // When
        try await sut.addFavorite(playerId: playerId)
        
        // Then
        XCTAssertEqual(mockRepository.addFavoriteCallCount, 1)
        let favorites = try await mockRepository.getFavorites()
        XCTAssertTrue(favorites.contains(playerId))
    }
    
    func testRemoveFavorite_CallsRepository() async throws {
        // Given
        let playerId = "player1"
        mockRepository.favorites = [playerId]
        
        // When
        try await sut.removeFavorite(playerId: playerId)
        
        // Then
        XCTAssertEqual(mockRepository.removeFavoriteCallCount, 1)
        let favorites = try await mockRepository.getFavorites()
        XCTAssertFalse(favorites.contains(playerId))
    }
    
    func testGetFavorites_ReturnsFavorites() async throws {
        // Given
        let expectedFavorites = ["player1", "player2", "player3"]
        mockRepository.favorites = expectedFavorites
        
        // When
        let result = try await sut.getFavorites()
        
        // Then
        XCTAssertEqual(result, expectedFavorites)
        XCTAssertEqual(mockRepository.getFavoritesCallCount, 1)
    }
    
    func testAddFavorite_ThrowsError_WhenRepositoryFails() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: 500)
        mockRepository.addFavoriteError = expectedError
        
        // When/Then
        do {
            try await sut.addFavorite(playerId: "player1")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 500)
        }
    }
}
