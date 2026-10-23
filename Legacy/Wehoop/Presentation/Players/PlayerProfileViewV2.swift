//
//  PlayerProfileViewV2.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// PlayerProfileView variant matching mockup design
struct PlayerProfileViewV2: View {
    @StateObject private var viewModel: PlayerProfileViewModel
    @Environment(\.theme) private var theme
    @Environment(\.teamThemeProvider) private var teamThemeProvider
    @Environment(\.viewModelFactory) private var factory
    @State private var isFavorite = false
    
    init(playerId: String, viewModel: PlayerProfileViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            let playerRepo = PlayerRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService())
            _viewModel = StateObject(wrappedValue: PlayerProfileViewModel(playerId: playerId, getPlayerProfileUseCase: GetPlayerProfileUseCase(playerRepository: playerRepo, playerId: playerId)))
        }
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    viewModel.loadPlayer()
                }
            } else if let player = viewModel.player {
                let teamTheme = teamThemeProvider.theme(for: player.team)
                
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [
                            teamTheme.colorScheme.primary.opacity(0.3),
                            teamTheme.colorScheme.secondary.opacity(0.2),
                            theme.colorScheme.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Large profile card with image
                            profileImageSection(player: player, teamTheme: teamTheme)
                            
                            // Player name and team
                            VStack(spacing: 8) {
                                Text(player.displayName)
                                    .font(theme.typography.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.colorScheme.foreground)
                                
                                Text(player.team.name)
                                    .font(theme.typography.headline)
                                    .foregroundColor(theme.colorScheme.secondary)
                            }
                            
                            // Details table
                            detailsTable(player: player)
                            
                            // Season stats
                            seasonStatsSection(player: player)
                        }
                        .padding()
                    }
                }
            } else {
                EmptyStateView(
                    title: "Player Not Found",
                    message: "Unable to load player information.",
                    systemImage: "person.circle"
                )
            }
        }
        .task {
            viewModel.loadPlayer()
            await checkFavoriteStatus()
        }
    }
    
    private func profileImageSection(player: Player, teamTheme: Theme) -> some View {
        ZStack(alignment: .topTrailing) {
            // Profile image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(teamTheme.colorScheme.primary.opacity(0.2))
                    .frame(height: 300)
                
                VStack {
                    // Large initial or placeholder
                    ZStack {
                        Circle()
                            .fill(teamTheme.colorScheme.primary.opacity(0.3))
                            .frame(width: 120, height: 120)
                        
                        Text(player.name.prefix(1))
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(teamTheme.colorScheme.primary)
                    }
                    
                    Text(player.name)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colorScheme.foreground)
                        .padding(.top, 8)
                }
            }
            
            // Favorite heart icon
            Button(action: {
                toggleFavorite()
            }) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundColor(isFavorite ? .red : .white)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(16)
        }
    }
    
    private func detailsTable(player: Player) -> some View {
        VStack(spacing: 12) {
            detailRow(label: "Team", value: player.team.abbreviation)
            
            if let jerseyNumber = player.jerseyNumber {
                detailRow(label: "Number", value: "\(jerseyNumber)")
            }
            
            if let age = player.age {
                detailRow(label: "Age", value: "\(age)")
            }
            
            if let college = player.college {
                detailRow(label: "College", value: college)
            }
        }
        .padding()
        .background(theme.colorScheme.background)
        .cornerRadius(12)
        .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colorScheme.secondary)
            Spacer()
            Text(value)
                .font(theme.typography.body)
                .foregroundColor(theme.colorScheme.foreground)
        }
    }
    
    private func seasonStatsSection(player: Player) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Season Stats")
                .font(theme.typography.headline)
                .foregroundColor(theme.colorScheme.foreground)
            
            HStack(spacing: 20) {
                statBox(
                    value: player.statistic(for: .scoring)?.formattedValue ?? "0.0",
                    label: "PPG"
                )
                
                statBox(
                    value: String(format: "%.1f", player.reboundsPerGame),
                    label: "RPG"
                )
                
                statBox(
                    value: String(format: "%.1f", player.assistsPerGame),
                    label: "APG"
                )
            }
        }
        .padding()
        .background(theme.colorScheme.background)
        .cornerRadius(12)
        .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(theme.typography.title)
                .fontWeight(.bold)
                .foregroundColor(theme.colorScheme.primary)
            
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colorScheme.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func checkFavoriteStatus() async {
        guard let player = viewModel.player else { return }
        
        do {
            let manageFavoritesUseCase: ManageFavoritesUseCase = factory.container.resolve()
            let favorites = try await manageFavoritesUseCase.getFavorites()
            isFavorite = favorites.contains(player.id)
        } catch {
            isFavorite = false
        }
    }
    
    private func toggleFavorite() {
        guard let player = viewModel.player else { return }
        
        Task {
            do {
                let manageFavoritesUseCase: ManageFavoritesUseCase = factory.container.resolve()
                if isFavorite {
                    try await manageFavoritesUseCase.removeFavorite(playerId: player.id)
                } else {
                    try await manageFavoritesUseCase.addFavorite(playerId: player.id)
                }
                isFavorite.toggle()
            } catch {
                // Handle error silently for now
            }
        }
    }
}

#Preview {
    let playerRepo = PlayerRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService())
    let viewModel = PlayerProfileViewModel(playerId: "player-1", getPlayerProfileUseCase: GetPlayerProfileUseCase(playerRepository: playerRepo, playerId: "player-1"))
    return PlayerProfileViewV2(playerId: "player-1", viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.teamThemeProvider, TeamThemeProvider())
        .environment(\.dependencyContainer, configureDependencyContainer())
}
