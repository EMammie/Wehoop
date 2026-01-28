//
//  PlayerProfileView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI
import Combine

/// View for displaying a player's detailed profile
struct PlayerProfileView: View {
    @StateObject private var viewModel: PlayerProfileViewModel
    @Environment(\.viewModelFactory) private var factory
    @Environment(\.featureFlagService) private var featureFlagService
    
    init(playerId: String, viewModel: PlayerProfileViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            // Fallback - should be provided by parent
            let playerRepo = PlayerRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService())
            _viewModel = StateObject(wrappedValue: PlayerProfileViewModel(playerId: playerId, getPlayerProfileUseCase: GetPlayerProfileUseCase(playerRepository: playerRepo, playerId: playerId)))
        }
    }
    
    var body: some View {
        if featureFlagService.isEnabled(.newPlayerProfileUI) {
            PlayerProfileViewV2(playerId: viewModel.playerId, viewModel: viewModel)
        } else {
            playerProfileViewContent
        }
    }
    
    private var playerProfileViewContent: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    viewModel.loadPlayer()
                }
            } else if let player = viewModel.player {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        headerSection(player: player)
                        
                        // Stats
                        if !player.statistics.isEmpty {
                            statsSection(player: player)
                        }
                    }
                    .padding()
                }
            } else {
                EmptyStateView(
                    title: "Player Not Found",
                    message: "Unable to load player information.",
                    systemImage: "person.fill.questionmark"
                )
            }
        }
        .navigationTitle(viewModel.player?.name ?? "Player")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.loadPlayer()
        }
    }
    
    private func headerSection(player: Player) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(player.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 16) {

                            Text(player.positionAbbreviation)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                      
                        
                        Text(player.team.fullName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let age = player.age {
                        Text("Age: \(age)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func statsSection(player: Player) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
            
            ForEach(player.statistics) { stat in
                HStack {
                    Text(stat.name)
                        .font(.subheadline)
                    Spacer()
                    Text(stat.formattedValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

/// ViewModel for PlayerProfileView
@MainActor
class PlayerProfileViewModel: ObservableObject {
    @Published var player: Player?
    @Published var isLoading = false
    @Published var error: Error?
    
    let playerId: String
    private let getPlayerProfileUseCase: GetPlayerProfileUseCase
    
    init(playerId: String, getPlayerProfileUseCase: GetPlayerProfileUseCase) {
        self.playerId = playerId
        self.getPlayerProfileUseCase = getPlayerProfileUseCase
    }
    
    func loadPlayer() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let loadedPlayer = try await getPlayerProfileUseCase.execute()
                self.player = loadedPlayer
                self.isLoading = false
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
}

#Preview("Player Profile - Loaded") {
    let player = GameFixtures.breannaStewart()
    let mockRepo = MockPlayerRepository(players: [player])
    let useCase = GetPlayerProfileUseCase(playerRepository: mockRepo, playerId: player.id)
    let viewModel = PlayerProfileViewModel(playerId: player.id, getPlayerProfileUseCase: useCase)

    PlayerProfileView(playerId: player.id, viewModel: viewModel)

}

#Preview("Player Profile - Guard") {
    let player = GameFixtures.sabrinaIonescu()
    let mockRepo = MockPlayerRepository(players: [player])
    let useCase = GetPlayerProfileUseCase(playerRepository: mockRepo, playerId: player.id)
    let viewModel = PlayerProfileViewModel(playerId: player.id, getPlayerProfileUseCase: useCase)


        PlayerProfileView(playerId: player.id, viewModel: viewModel)


}

#Preview("Player Profile - Forward") {
    let player = GameFixtures.rickeaJackson()
    let mockRepo = MockPlayerRepository(players: [player])
    let useCase = GetPlayerProfileUseCase(playerRepository: mockRepo, playerId: player.id)
    let viewModel = PlayerProfileViewModel(playerId: player.id, getPlayerProfileUseCase: useCase)

        PlayerProfileView(playerId: player.id, viewModel: viewModel)

}

#Preview("Player Profile - Loading") {
    let player = GameFixtures.caitlinClark()
    let mockRepo = MockPlayerRepository(players: [player])
    let useCase = GetPlayerProfileUseCase(playerRepository: mockRepo, playerId: player.id)
    let viewModel = PlayerProfileViewModel(playerId: player.id, getPlayerProfileUseCase: useCase)
    //viewModel.isLoading = true

        PlayerProfileView(playerId: player.id, viewModel: viewModel)

}

#Preview("Player Profile - Error") {
    let player = GameFixtures.breannaStewart()
    let mockRepo = MockPlayerRepository(players: [])
    let useCase = GetPlayerProfileUseCase(playerRepository: mockRepo, playerId: player.id)
    let viewModel = PlayerProfileViewModel(playerId: player.id, getPlayerProfileUseCase: useCase)
///*    viewModel.error = NSError(domain: "PreviewError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to load player"]*/)

    PlayerProfileView(playerId: player.id, viewModel: viewModel)
  }

