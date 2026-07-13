//
//  GamesViewV2.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// State for the box score sheet presentation
private enum BoxScoreSheetState {
    case hidden
    case loading(gameId: String)
    case error(gameId: String, error: Error)
    case noBoxScore(game: Game)
    case loaded(game: Game, boxScore: BoxScore)
}

/// GamesView variant matching mockup design
struct GamesViewV2: View {
    @StateObject private var viewModel: GamesViewModel
    @Environment(\.theme) private var theme
    @Environment(\.viewModelFactory) private var factory
    
    // For league leaders section
    @State private var topPlayers: [Player] = []
    @State private var isLoadingLeaders = false
    
    // Box score sheet driven by state enum
    @State private var boxScoreSheetState: BoxScoreSheetState = .hidden

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
            .sheet(isPresented: sheetBinding) {
                boxScoreSheetContent
            }
        }
    }
    
    private var sheetBinding: Binding<Bool> {
        Binding(
            get: { if case .hidden = boxScoreSheetState { return false } else { return true } },
            set: { if !$0 { boxScoreSheetState = .hidden } }
        )
    }
    
    @ViewBuilder
    private var boxScoreSheetContent: some View {
        switch boxScoreSheetState {
        case .hidden:
            EmptyView()
        case .loading:
            NavigationView {
                LoadingView()
                    .navigationTitle("Loading Game Details")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { toolbarCancel }
            }
        case .error(_, let error):
            NavigationView {
                ErrorView(error: error) {
                    if case .error(let gameId, _) = boxScoreSheetState {
                        Task { await loadGameDetails(gameId: gameId) }
                    }
                }
                .navigationTitle("Error")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarDone }
            }
        case .noBoxScore(let game):
            noBoxScoreSheetView(game: game)
        case .loaded(let game, let boxScore):
            BoxScoreView(game: game, boxScore: boxScore)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarCancel: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Cancel") { boxScoreSheetState = .hidden }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarDone: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") { boxScoreSheetState = .hidden }
        }
    }
    
    private func noBoxScoreSheetView(game: Game) -> some View {
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
                
                if game.isFinished || game.isLive {
                    Button(action: {
                        Task { @MainActor in
                            boxScoreSheetState = .loading(gameId: game.id)
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
            .toolbar { toolbarDone }
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
        boxScoreSheetState = .loading(gameId: gameId)
        
        do {
            let fullGame = try await viewModel.getGame(id: gameId)
            await MainActor.run {
                if let boxScore = fullGame.boxScore {
                    boxScoreSheetState = .loaded(game: fullGame, boxScore: boxScore)
                } else {
                    boxScoreSheetState = .noBoxScore(game: fullGame)
                }
            }
        } catch {
            await MainActor.run {
                boxScoreSheetState = .error(gameId: gameId, error: error)
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

#if DEBUG
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
#endif
