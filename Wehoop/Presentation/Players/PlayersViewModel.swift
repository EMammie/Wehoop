//
//  PlayersViewModel.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine

/// ViewModel for PlayersView
@MainActor
class PlayersViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText: String = ""
    
    private let playerRepository: PlayerRepository
    
    init(playerRepository: PlayerRepository) {
        self.playerRepository = playerRepository
    }
    
    func loadPlayers() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let loadedPlayers = try await playerRepository.getPlayers()
                self.players = loadedPlayers.sorted { $0.name < $1.name }
                self.isLoading = false
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func refreshPlayers() {
        loadPlayers()
    }
    
    var filteredPlayers: [Player] {
        if searchText.isEmpty {
            return players
        }
        return players.filter { player in
            player.name.localizedCaseInsensitiveContains(searchText) ||
            player.team.name.localizedCaseInsensitiveContains(searchText) ||
            player.team.abbreviation.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var hasPlayers: Bool {
        !filteredPlayers.isEmpty
    }
}
