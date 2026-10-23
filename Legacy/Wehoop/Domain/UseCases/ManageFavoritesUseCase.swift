//
//  ManageFavoritesUseCase.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Use case for managing favorite players
class ManageFavoritesUseCase {
    private let favoriteRepository: FavoriteRepository
    
    init(favoriteRepository: FavoriteRepository) {
        self.favoriteRepository = favoriteRepository
    }
    
    func addFavorite(playerId: String) async throws {
        try await favoriteRepository.addFavorite(playerId: playerId)
    }
    
    func removeFavorite(playerId: String) async throws {
        try await favoriteRepository.removeFavorite(playerId: playerId)
    }
    
    func getFavorites() async throws -> [String] {
        return try await favoriteRepository.getFavorites()
    }
}
