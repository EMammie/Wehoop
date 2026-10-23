//
//  MockFavoriteRepository.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import Foundation
@testable import Wehoop

/// Mock implementation of FavoriteRepository for testing
class MockFavoriteRepository: FavoriteRepository {
    var favorites: [String] = []
    var addFavoriteError: Error?
    var removeFavoriteError: Error?
    var getFavoritesError: Error?
    var addFavoriteCallCount = 0
    var removeFavoriteCallCount = 0
    var getFavoritesCallCount = 0
    var isFavoriteCallCount = 0
    
    func addFavorite(playerId: String) async throws {
        addFavoriteCallCount += 1
        if let error = addFavoriteError {
            throw error
        }
        if !favorites.contains(playerId) {
            favorites.append(playerId)
        }
    }
    
    func removeFavorite(playerId: String) async throws {
        removeFavoriteCallCount += 1
        if let error = removeFavoriteError {
            throw error
        }
        favorites.removeAll { $0 == playerId }
    }
    
    func getFavorites() async throws -> [String] {
        getFavoritesCallCount += 1
        if let error = getFavoritesError {
            throw error
        }
        return favorites
    }
    
    func isFavorite(playerId: String) async throws -> Bool {
        isFavoriteCallCount += 1
        return favorites.contains(playerId)
    }
}
