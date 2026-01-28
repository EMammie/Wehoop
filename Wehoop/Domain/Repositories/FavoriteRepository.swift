//
//  FavoriteRepository.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Protocol for favorite repository operations
protocol FavoriteRepository {
    func addFavorite(playerId: String) async throws
    func removeFavorite(playerId: String) async throws
    func getFavorites() async throws -> [String]
    func isFavorite(playerId: String) async throws -> Bool
}
