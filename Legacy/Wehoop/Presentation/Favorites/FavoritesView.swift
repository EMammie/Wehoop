//
//  FavoritesView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// View for displaying favorite players
struct FavoritesView: View {
    @StateObject private var viewModel: FavoritesViewModel
    @Environment(\.viewModelFactory) private var factory
    
    init(viewModel: FavoritesViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            // Fallback - should be provided by parent
            let playerRepo = PlayerRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService())
            _viewModel = StateObject(wrappedValue: FavoritesViewModel(manageFavoritesUseCase: ManageFavoritesUseCase(favoriteRepository: FavoriteRepositoryImpl(storageService: UserDefaultsStorageService())), playerRepository: playerRepo))
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.favoritePlayers.isEmpty {
                    LoadingView()
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        viewModel.loadFavorites()
                    }
                } else if !viewModel.hasFavorites {
                    EmptyStateView(
                        title: "No Favorites",
                        message: "Add players to your favorites to see them here.",
                        systemImage: "star"
                    )
                } else {
                    CardFeedView(
                        items: viewModel.favoritePlayers,
                        spacing: 12,
                        onRefresh: {
                            viewModel.refreshFavorites()
                        },
                        emptyStateTitle: "No Favorites",
                        emptyStateMessage: "Add players to your favorites to see them here.",
                        emptyStateImage: "star"
                    ) { player in
                        NavigationLink(destination: PlayerProfileView(playerId: player.id, viewModel: factory.makePlayerProfileViewModel(playerId: player.id))) {
                            FavoritePlayerCardView(
                                player: player,
                                onRemove: {
                                    viewModel.removeFavorite(playerId: player.id)
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Favorites")
            .task {
                if viewModel.favoritePlayers.isEmpty {
                    viewModel.loadFavorites()
                }
            }
        }
    }
}
