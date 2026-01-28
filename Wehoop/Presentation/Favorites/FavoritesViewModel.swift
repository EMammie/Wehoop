//
//  FavoritesViewModel.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine

/// ViewModel for FavoritesView
@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var favoritePlayers: [Player] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let manageFavoritesUseCase: ManageFavoritesUseCase
    private let playerRepository: PlayerRepository
    
    init(manageFavoritesUseCase: ManageFavoritesUseCase, playerRepository: PlayerRepository) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        self.playerRepository = playerRepository
    }
    
    func loadFavorites() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let favoriteIds = try await manageFavoritesUseCase.getFavorites()
                
                // Load player details for each favorite ID
                var players: [Player] = []
                for playerId in favoriteIds {
                    do {
                        let player = try await playerRepository.getPlayer(id: playerId)
                        players.append(player)
                    } catch {
                        // Skip players that can't be loaded
                        continue
                    }
                }
                
                self.favoritePlayers = players
                self.isLoading = false
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func removeFavorite(playerId: String) {
        Task {
            do {
                try await manageFavoritesUseCase.removeFavorite(playerId: playerId)
                // Reload favorites to update the list
                await loadFavorites()
            } catch {
                self.error = error
            }
        }
    }
    
    func refreshFavorites() {
        loadFavorites()
    }
    
    var hasFavorites: Bool {
        !favoritePlayers.isEmpty
    }
}
