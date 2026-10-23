//
//  FavoriteRepositoryImplTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class FavoriteRepositoryImplTests: XCTestCase {
    var sut: FavoriteRepositoryImpl!
    var mockStorageService: UserDefaultsStorageService!
    var testUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: "TestFavorites")
        testUserDefaults?.removePersistentDomain(forName: "TestFavorites")
        mockStorageService = UserDefaultsStorageService(userDefaults: testUserDefaults!)
        sut = FavoriteRepositoryImpl(storageService: mockStorageService)
    }
    
    override func tearDown() {
        testUserDefaults?.removePersistentDomain(forName: "TestFavorites")
        sut = nil
        mockStorageService = nil
        testUserDefaults = nil
        super.tearDown()
    }
    
    func testAddFavorite_AddsPlayerId_WhenNotAlreadyFavorite() async throws {
        // Given
        let playerId = "player-1"
        
        // When
        try await sut.addFavorite(playerId: playerId)
        let favorites = try await sut.getFavorites()
        
        // Then
        XCTAssertTrue(favorites.contains(playerId))
    }
    
    func testAddFavorite_DoesNotDuplicate_WhenAlreadyFavorite() async throws {
        // Given
        let playerId = "player-1"
        try await sut.addFavorite(playerId: playerId)
        
        // When
        try await sut.addFavorite(playerId: playerId)
        let favorites = try await sut.getFavorites()
        
        // Then
        let count = favorites.filter { $0 == playerId }.count
        XCTAssertEqual(count, 1, "Should not add duplicate favorites")
    }
    
    func testRemoveFavorite_RemovesPlayerId_WhenExists() async throws {
        // Given
        let playerId = "player-1"
        try await sut.addFavorite(playerId: playerId)
        
        // When
        try await sut.removeFavorite(playerId: playerId)
        let favorites = try await sut.getFavorites()
        
        // Then
        XCTAssertFalse(favorites.contains(playerId))
    }
    
    func testRemoveFavorite_DoesNotThrow_WhenNotFavorite() async throws {
        // Given
        let playerId = "player-1"
        
        // When/Then - Should not throw
        try await sut.removeFavorite(playerId: playerId)
    }
    
    func testGetFavorites_ReturnsEmptyArray_WhenNoFavorites() async throws {
        // When
        let favorites = try await sut.getFavorites()
        
        // Then
        XCTAssertTrue(favorites.isEmpty)
    }
    
    func testGetFavorites_ReturnsAllFavorites() async throws {
        // Given
        let playerId1 = "player-1"
        let playerId2 = "player-2"
        try await sut.addFavorite(playerId: playerId1)
        try await sut.addFavorite(playerId: playerId2)
        
        // When
        let favorites = try await sut.getFavorites()
        
        // Then
        XCTAssertEqual(favorites.count, 2)
        XCTAssertTrue(favorites.contains(playerId1))
        XCTAssertTrue(favorites.contains(playerId2))
    }
    
    func testIsFavorite_ReturnsTrue_WhenPlayerIsFavorite() async throws {
        // Given
        let playerId = "player-1"
        try await sut.addFavorite(playerId: playerId)
        
        // When
        let result = try await sut.isFavorite(playerId: playerId)
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testIsFavorite_ReturnsFalse_WhenPlayerIsNotFavorite() async throws {
        // Given
        let playerId = "player-1"
        
        // When
        let result = try await sut.isFavorite(playerId: playerId)
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testMultipleFavorites_PersistCorrectly() async throws {
        // Given
        let playerIds = ["player-1", "player-2", "player-3"]
        
        // When
        for playerId in playerIds {
            try await sut.addFavorite(playerId: playerId)
        }
        
        let favorites = try await sut.getFavorites()
        
        // Then
        XCTAssertEqual(favorites.count, playerIds.count)
        for playerId in playerIds {
            XCTAssertTrue(favorites.contains(playerId))
        }
    }
}
