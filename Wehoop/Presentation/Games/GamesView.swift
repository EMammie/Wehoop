//
//  GamesView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// View for displaying games feed
struct GamesView: View {
    @StateObject private var viewModel: GamesViewModel
    @Environment(\.featureFlagService) private var featureFlagService
    
    init(viewModel: GamesViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            // Fallback - should be provided by parent
            _viewModel = StateObject(wrappedValue: GamesViewModel(getGamesUseCase: GetGamesUseCase(gameRepository: GameRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService()))))
        }
    }
    
    var body: some View {
        if featureFlagService.isEnabled(.newGamesUI) {
            GamesViewV2(viewModel: viewModel)
        } else {
            gamesViewContent
        }
    }
    
    private var gamesViewContent: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Date Picker pinned at the top
                DatePickerView(
                    selectedDate: $viewModel.selectedDate,
                    onDateSelected: { date in
                        viewModel.loadGames(for: date)
                    }
                )
                .padding(.horizontal)
                .padding(.top, 8)
                .background(Color.clear) // Ensure it has a background
                
                // Content area - takes remaining space
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Take remaining space
            }
            .navigationTitle("Games")
            .task {
                // Load games on initial appearance if state is empty
                if case .empty = viewModel.state {
                    viewModel.loadGames(for: viewModel.selectedDate)
                }
            }
        }
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .loading:
            LoadingView()
            
        case .error(let error):
            ErrorView(error: error) {
                viewModel.loadGames(for: viewModel.selectedDate)
            }
            
        case .empty:
            let (title, message) = getEmptyStateMessage()
            EmptyStateView(
                title: title,
                message: message,
                systemImage: "sportscourt"
            )
            
        case .loaded(let games, let liveGames):
            let displayResult = GamesDisplayManager.organize(games)
            
            if displayResult.hasLiveGames {
                // Use sectioned feed for live games + all games
                SectionedCardFeedView(
                    sections: [
                        FeedSection(
                            items: displayResult.liveGames,
                            header: { LiveGamesHeader() },
                            cardContent: { game in
                                GameCardView(game: game)
                            }
                        ),
                        FeedSection(
                            items: displayResult.allGames,
                            header: {
                                LiveGamesHeader()
                            },
                            cardContent: { game in
                                GameCardView(game: game)
                            }
                        )
                    ],
                    spacing: 16,
                    onRefresh: {
                        viewModel.refreshGames()
                    }
                )
            } else {
                // Use simple feed for all games
                CardFeedView(
                    items: displayResult.allGames,
                    spacing: 16,
                    onRefresh: {
                        viewModel.refreshGames()
                    },
                    emptyStateTitle: "No Games",
                    emptyStateMessage: "There are no games scheduled at this time.",
                    emptyStateImage: "sportscourt"
                ) { game in
                    GameCardView(game: game)
                }
            }
        }
    }
    
    // MARK: - Edge Case Handling
    private func getEmptyStateMessage() -> (title: String, message: String) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        
        // Rough estimate: NBA season is typically October - June
        // Offseason: July - September
        if month >= 7 && month <= 9 {
            return ("Offseason", "The season has ended. Check back for the next season schedule.")
        }
        // Preseason: September - October
        else if month == 9 || month == 10 {
            return ("Preseason", "The season is starting soon. Games will appear here when scheduled.")
        }
        // Regular season but no games
        else {
            return ("No Games", "There are no games scheduled at this time.")
        }
    }
}

#Preview("Loading State") {
    let viewModel = PreviewGamesViewModel(state: .loading)
    return GamesView(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
}

#Preview("Loaded State with Live Games") {
    let viewModel = PreviewGamesViewModel(state: .loaded)
    return GamesView(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
}

#Preview("Loaded State without Live Games") {
    let viewModel = PreviewGamesViewModel(state: .loadedNoLive)
    return GamesView(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
}

#Preview("Error State") {
    let viewModel = PreviewGamesViewModel(state: .error)
    return GamesView(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
}

#Preview("Empty State") {
    let viewModel = PreviewGamesViewModel(state: .empty)
    return GamesView(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
}

// MARK: - Preview ViewModel

 class PreviewGamesViewModel: GamesViewModel {
    enum PreviewState {
        case loading
        case loaded
        case loadedNoLive
        case error
        case empty
    }
    
    init(state: PreviewState) {
        // Create a mock use case
        let mockRepository = MockGameRepository(state: state)
        let useCase = GetGamesUseCase(gameRepository: mockRepository)
        super.init(getGamesUseCase: useCase)
        
        // Set initial state based on preview state
        switch state {
        case .loading:
            self.state = .loading
        case .loaded:
            let games = GameFixtures.sampleGames()
            let liveGames = GameFixtures.liveGames()
            self.games = games
            self.liveGames = liveGames
            self.state = .loaded(games: games, liveGames: liveGames)
        case .loadedNoLive:
            let games = GameFixtures.finishedGames() + GameFixtures.scheduledGames()
            self.games = games
            self.liveGames = []
            self.state = .loaded(games: games, liveGames: [])
        case .error:
            self.state = .error(NSError(domain: "PreviewError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to load games"]))
        case .empty:
            self.state = .empty
        }
    }
}

// MARK: - Mock Repository for Previews

 class MockGameRepository: GameRepository {
    enum MockState {
        case loading
        case loaded
        case loadedNoLive
        case error
        case empty
    }
    
    private let state: MockState
    
  init(state: PreviewGamesViewModel.PreviewState) {
    var repoState : MockState?
      switch state {
      case .loading:
        repoState = .loading
      case .loaded:
        repoState = .loaded
      case .loadedNoLive:
        repoState = .loadedNoLive
      case .error:
        repoState = .error
      case .empty:
        repoState = .empty
      }
    self.state = repoState!
    }
    
    func getGames(date: Date?) async throws -> [Game] {
        // Simulate network delay for previews
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        var games: [Game]
        switch state {
        case .loading, .empty:
            games = []
        case .loaded:
            games = GameFixtures.sampleGames()
        case .loadedNoLive:
            games = GameFixtures.finishedGames() + GameFixtures.scheduledGames()
        case .error:
            throw NSError(domain: "PreviewError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to load games"])
        }
        
        // Filter by date if provided
        if let date = date {
            let calendar = Calendar.current
            games = games.filter { calendar.isDate($0.date, inSameDayAs: date) }
        }
        
        return games
    }
    
    func getGames() async throws -> [Game] {
        return try await getGames(date: nil)
    }
    
    func getGame(id: String) async throws -> Game {
        let games = try await getGames()
        guard let game = games.first(where: { $0.id == id }) else {
            throw NSError(domain: "MockRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Game not found"])
        }
        return game
    }
    
}
