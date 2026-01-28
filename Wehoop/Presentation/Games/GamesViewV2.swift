//
//  GamesViewV2.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// GamesView variant matching mockup design
struct GamesViewV2: View {
    @StateObject private var viewModel: GamesViewModel
    @Environment(\.theme) private var theme
    @Environment(\.viewModelFactory) private var factory
    
    // For league leaders section
    @State private var topPlayers: [Player] = []
    @State private var isLoadingLeaders = false
    
    // For box score navigation
    @State private var selectedGame: Game?
    @State private var showBoxScore = false
    @State private var isLoadingGameDetails = false
    @State private var gameDetailError: Error?
    @State private var hasAttemptedBoxScoreFetch = false

    init(viewModel: GamesViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: GamesViewModel(getGamesUseCase: GetGamesUseCase(gameRepository: GameRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService()))))
        }
    }
    
    var body: some View {
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
                await loadTopPlayers()
            }
            .sheet(isPresented: $showBoxScore) {
                if isLoadingGameDetails {
                    NavigationView {
                        LoadingView()
                            .navigationTitle("Loading Game Details")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Cancel") {
                                        showBoxScore = false
                                        isLoadingGameDetails = false
                                        selectedGame = nil
                                        gameDetailError = nil
                                        hasAttemptedBoxScoreFetch = false
                                    }
                                }
                            }
                    }
                } else if let error = gameDetailError {
                    NavigationView {
                        ErrorView(error: error) {
                            // Retry loading game details
                            if let gameId = selectedGame?.id {
                                Task {
                                    await loadGameDetails(gameId: gameId)
                                }
                            }
                        }
                        .navigationTitle("Error")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showBoxScore = false
                                    selectedGame = nil
                                    gameDetailError = nil
                                    hasAttemptedBoxScoreFetch = false
                                }
                            }
                        }
                    }
                } else if let game = selectedGame {
                    if let boxScore = game.boxScore {
                        BoxScoreView(game: game, boxScore: boxScore)
                    } else {
                        // Attempt to fetch box score data if we haven't already tried
                        // Only attempt for finished or live games (scheduled games won't have box scores)
                        if !hasAttemptedBoxScoreFetch && !isLoadingGameDetails && (game.isFinished || game.isLive) {
                            // Trigger async fetch

                            // Show loading while fetching
                            NavigationView {
                                LoadingView()
                                    .navigationTitle("Loading Box Score")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .toolbar {
                                        ToolbarItem(placement: .navigationBarTrailing) {
                                            Button("Cancel") {
                                                showBoxScore = false
                                                isLoadingGameDetails = false
                                                selectedGame = nil
                                                gameDetailError = nil
                                                hasAttemptedBoxScoreFetch = false
                                            }
                                        }
                                    }
                            }.task {
                              await loadGameDetails(gameId: game.id)
                            }
                        } else {
                            // Show "No Box Score Available" for scheduled games or after attempted fetch
                            NavigationView {
                                VStack(spacing: 20) {
                                    Image(systemName: "sportscourt")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary)
                                    
                                    Text("No Box Score Available")
                                        .font(.headline)
                                    
                                    Text(game.status == .scheduled 
                                         ? "This game is scheduled and hasn't started yet."
                                         : "Box score data is not available for this game.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    // Show game info even without box score
                                    VStack(spacing: 12) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(game.awayTeam.abbreviation)
                                                    .font(.headline)
                                                Text(game.awayTeam.name)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                        
                                        Divider()
                                        
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(game.homeTeam.abbreviation)
                                                    .font(.headline)
                                                Text(game.homeTeam.name)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                    
                                    // Add retry button for finished/live games
                                    if game.isFinished || game.isLive {
                                        Button(action: {
                                            // Reset state to trigger loading view
                                            // Ensure we preserve the selected game for context
                                            Task { @MainActor in
                                                hasAttemptedBoxScoreFetch = false
                                                gameDetailError = nil
                                                isLoadingGameDetails = true
                                                // Ensure selectedGame is set for context
                                                if selectedGame == nil {
                                                    selectedGame = game
                                                }
                                                await loadGameDetails(gameId: game.id)
                                            }
                                        }) {
                                            Text("Retry Loading Box Score")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.top)
                                    }
                                }
                                .padding()
                                .navigationTitle("Game Details")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button("Done") {
                                            showBoxScore = false
                                            selectedGame = nil
                                            hasAttemptedBoxScoreFetch = false
                                        }
                                    }
                                }
                            }
                        }
                    }
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
            
            ScrollView {
                VStack(spacing: 20) {
                    // Games section with live games prioritized
                    VStack(alignment: .leading, spacing: 12) {
                        // Live games section (if any)
                        if displayResult.hasLiveGames {
                            // Optional: Section header for live games
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                    Text("Live Now")
                                        .font(theme.typography.headline)
                                        .foregroundColor(theme.colorScheme.foreground)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            ForEach(displayResult.liveGames.prefix(3)) { game in
                                Button(action: {
                                    Task {
                                        await loadGameDetails(gameId: game.id)
                                    }
                                }) {
                                    CompactGameCardView(game: game)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                        
                        // Upcoming and finished games section
                        let combinedOtherGames = displayResult.upcomingGames + displayResult.finishedGames
                        let remainingSlots = max(0, 3 - displayResult.liveGames.count)
                        
                        if remainingSlots > 0 && !combinedOtherGames.isEmpty {
                            // Optional: Section header for other games (only if we have live games above)
                            if displayResult.hasLiveGames {
                                HStack {
                                    Text("Upcoming & Recent")
                                        .font(theme.typography.headline)
                                        .foregroundColor(theme.colorScheme.foreground)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)
                            }
                            
                            ForEach(combinedOtherGames.prefix(remainingSlots)) { game in
                                Button(action: {
                                    Task {
                                        await loadGameDetails(gameId: game.id)
                                    }
                                }) {
                                    CompactGameCardView(game: game)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                    
                    // League Leaders section
                    if !topPlayers.isEmpty {
                        LeagueLeadersSection(players: topPlayers)
                    }
                }
            }
            .refreshable {
                viewModel.refreshGames()
                await loadTopPlayers()
            }
        }
    }
    
    private func loadTopPlayers() async {
        isLoadingLeaders = true
        defer { isLoadingLeaders = false }
        
        do {
            let container: DependencyContainer = factory.container
            let leagueLeadersRepository: LeagueLeadersRepository = container.resolve()
            let useCase = GetStatLeadersUseCase(leagueLeadersRepository: leagueLeadersRepository)
            let leaders = try await useCase.execute(category: .scoring, limit: 5)
            topPlayers = leaders
        } catch {
            // Silently fail - league leaders is optional
            topPlayers = []
        }
    }
    
    private func loadGameDetails(gameId: String) async {
        isLoadingGameDetails = true
        gameDetailError = nil
        showBoxScore = true
        hasAttemptedBoxScoreFetch = false
        
        defer {
            isLoadingGameDetails = false
        }
        
        do {
            let fullGame = try await viewModel.getGame(id: gameId)
            await MainActor.run {
                // Force view update by clearing first, then setting new value
                selectedGame = nil
                selectedGame = fullGame
                gameDetailError = nil
                hasAttemptedBoxScoreFetch = true
            }
        } catch {
            await MainActor.run {
                gameDetailError = error
                hasAttemptedBoxScoreFetch = true
                // Keep the original game if available for context
                if selectedGame == nil {
                    // Try to find the game in the current list
                    if case .loaded(let games, let liveGames) = viewModel.state {
                        selectedGame = (games + liveGames).first { $0.id == gameId }
                    }
                }
            }
        }
    }
    
    private func getEmptyStateMessage() -> (title: String, message: String) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        
        if month >= 7 && month <= 9 {
            return ("Offseason", "The season has ended. Check back for the next season schedule.")
        } else if month == 9 || month == 10 {
            return ("Preseason", "The season is starting soon. Games will appear here when scheduled.")
        } else {
            return ("No Games", "There are no games scheduled at this time.")
        }
    }
}

#Preview("Loading State") {
    let viewModel = PreviewGamesViewModel(state: .loading)
    return GamesViewV2(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.dependencyContainer, configureDependencyContainer())
        .environment(\.teamThemeProvider, TeamThemeProvider())
}

#Preview("Loaded State with Live Games") {
    let viewModel = PreviewGamesViewModel(state: .loaded)
    return GamesViewV2(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.dependencyContainer, configureDependencyContainer())
        .environment(\.teamThemeProvider, TeamThemeProvider())
}

#Preview("Loaded State without Live Games") {
    let viewModel = PreviewGamesViewModel(state: .loadedNoLive)
    return GamesViewV2(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.dependencyContainer, configureDependencyContainer())
        .environment(\.teamThemeProvider, TeamThemeProvider())
}

#Preview("Error State") {
    let viewModel = PreviewGamesViewModel(state: .error)
    return GamesViewV2(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.dependencyContainer, configureDependencyContainer())
        .environment(\.teamThemeProvider, TeamThemeProvider())
}

#Preview("Empty State") {
    let viewModel = PreviewGamesViewModel(state: .empty)
    return GamesViewV2(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.dependencyContainer, configureDependencyContainer())
        .environment(\.teamThemeProvider, TeamThemeProvider())
}
