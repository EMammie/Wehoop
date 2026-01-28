//
//  PlayersView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// View for displaying players list
struct PlayersView: View {
    @StateObject private var viewModel: PlayersViewModel
    @Environment(\.viewModelFactory) private var factory
    @Environment(\.theme) private var theme
    
    init(viewModel: PlayersViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            // Fallback - should be provided by parent
            _viewModel = StateObject(wrappedValue: PlayersViewModel(playerRepository: PlayerRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService())))
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar pinned at the top
                searchBar
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .background(Color.clear) // Ensure it has a background
                
                // Players list - takes remaining space
                playersListView
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Take remaining space
            }
            .navigationTitle("Players")
            .task {
                if viewModel.players.isEmpty {
                    viewModel.loadPlayers()
                }
            }
        }
    }
    
    @ViewBuilder
    private var playersListView: some View {
        if viewModel.isLoading && viewModel.players.isEmpty {
            LoadingView()
        } else if let error = viewModel.error {
            ErrorView(error: error) {
                viewModel.loadPlayers()
            }
        } else if !viewModel.hasPlayers {
            EmptyStateView(
                title: "No Players",
                message: viewModel.searchText.isEmpty ? "No players found." : "No players match your search.",
                systemImage: "person.3"
            )
        } else {
            CardFeedView(
                items: viewModel.filteredPlayers,
                spacing: 12,
                onRefresh: {
                    viewModel.refreshPlayers()
                },
                emptyStateTitle: "No Players",
                emptyStateMessage: viewModel.searchText.isEmpty ? "No players found." : "No players match your search.",
                emptyStateImage: "person.3"
            ) { player in
                NavigationLink(destination: PlayerProfileView(playerId: player.id, viewModel: factory.makePlayerProfileViewModel(playerId: player.id))) {
                    PlayerCardView(player: player)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.colorScheme.secondary)
            TextField("Search players...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(theme.colorScheme.foreground)
        }
        .padding()
        .background(theme.colorScheme.secondary.opacity(0.2))
        .cornerRadius(10)
        .padding(.vertical, 8)
    }
}

#Preview("Players View - Loaded") {
    let mockRepo = MockPlayerRepository(players: GameFixtures.allPlayers())
    let viewModel = PlayersViewModel(playerRepository: mockRepo)
//    viewModel.players = GameFixtures.allPlayers()
    PlayersView(viewModel: viewModel)

}

#Preview("Players View - Loading") {
    let mockRepo = MockPlayerRepository(players: [])
    let viewModel = PlayersViewModel(playerRepository: mockRepo)
//    viewModel.isLoading = true
    PlayersView(viewModel: viewModel)

}

#Preview("Players View - Empty") {
    let mockRepo = MockPlayerRepository(players: [])
    let viewModel = PlayersViewModel(playerRepository: mockRepo)
    return PlayersView(viewModel: viewModel)
        
}

#Preview("Players View - With Search") {
    let mockRepo = MockPlayerRepository(players: GameFixtures.allPlayers())
    let viewModel = PlayersViewModel(playerRepository: mockRepo)
//    viewModel.players = GameFixtures.allPlayers()
//    viewModel.searchText = "Stewart"
    PlayersView(viewModel: viewModel)

}

// MARK: - Mock Repository for Previews

class MockPlayerRepository: PlayerRepository {
    private let players: [Player]
    
    init(players: [Player]) {
        self.players = players
    }
    
    func getPlayers() async throws -> [Player] {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        return players
    }
    
    func getPlayer(id: String) async throws -> Player {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        guard let player = players.first(where: { $0.id == id }) else {
            throw NSError(domain: "MockRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Player not found"])
        }
        return player
    }
}
