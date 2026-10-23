//
//  FavoriteRepositoryImpl.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Implementation of FavoriteRepository
class FavoriteRepositoryImpl: FavoriteRepository {
    private let storageService: StorageService
    private let favoritesKey = "favorite_player_ids"
    
    init(storageService: StorageService) {
        self.storageService = storageService
    }
    
    func addFavorite(playerId: String) async throws {
        var favorites = try await getFavorites()
        
        // Only add if not already a favorite
        if !favorites.contains(playerId) {
            favorites.append(playerId)
            try storageService.save(favorites, forKey: favoritesKey)
        }
    }
    
    func removeFavorite(playerId: String) async throws {
        var favorites = try await getFavorites()
        favorites.removeAll { $0 == playerId }
        try storageService.save(favorites, forKey: favoritesKey)
    }
    
    func getFavorites() async throws -> [String] {
        if let favorites: [String] = try storageService.load([String].self, forKey: favoritesKey) {
            return favorites
        }
        return []
    }
    
    func isFavorite(playerId: String) async throws -> Bool {
        let favorites = try await getFavorites()
        return favorites.contains(playerId)
    }
}
