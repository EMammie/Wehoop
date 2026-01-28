//
//  GamesViewModel.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine

/// State enum for GamesView
enum GamesViewState {
    case loading
    case error(Error)
    case empty
    case loaded(games: [Game], liveGames: [Game])
}

/// ViewModel for GamesView
@MainActor
class GamesViewModel: ObservableObject {
    @Published var state: GamesViewState = .empty
    @Published var games: [Game] = []
    @Published var liveGames: [Game] = []
    @Published var connectionMode: ConnectionMode = .disconnected
    @Published var selectedDate: Date = Date()
    
    private let getGamesUseCase: GetGamesUseCase
    private let realTimeUpdateService: RealTimeUpdateService?
    private var cancellables = Set<AnyCancellable>()
    private var isRealTimeActive = false
    
    init(getGamesUseCase: GetGamesUseCase, realTimeUpdateService: RealTimeUpdateService? = nil) {
        self.getGamesUseCase = getGamesUseCase
        self.realTimeUpdateService = realTimeUpdateService
        setupRealTimeUpdates()
        // Don't auto-load - let view handle initial load with date
    }
    
    /// Load games for the specified date
    /// - Parameter date: Date to load games for. If nil, uses selectedDate.
    func loadGames(for date: Date? = nil) {
        // Prevent multiple simultaneous loads
        if case .loading = state {
            return
        }
        
        // Use provided date or selectedDate
        let targetDate = date ?? selectedDate
        
        // Update selectedDate if a new date was provided
        if let date = date {
            selectedDate = date
        }
        
        state = .loading
        
        Task {
            do {
                let loadedGames = try await getGamesUseCase.execute(date: targetDate)
                let displayResult = GamesDisplayManager.organize(loadedGames)
                
                self.games = displayResult.allGames
                self.liveGames = displayResult.liveGames
                
                if displayResult.isEmpty {
                    self.state = .empty
                    stopRealTimeUpdates()
                } else {
                    self.state = .loaded(games: displayResult.allGames, liveGames: displayResult.liveGames)
                    // Start real-time updates if there are live games
                    if displayResult.hasLiveGames {
                        startRealTimeUpdates()
                    } else {
                        stopRealTimeUpdates()
                    }
                }
            } catch {
                self.state = .error(error)
                stopRealTimeUpdates()
            }
        }
    }
    
    func refreshGames() {
        loadGames(for: selectedDate)
    }
    
    var hasGames: Bool {
        !games.isEmpty
    }
    
    var hasLiveGames: Bool {
        !liveGames.isEmpty
    }
    
    /// Fetch full game details by ID
    /// - Parameter gameId: The ID of the game to fetch
    /// - Returns: The game with full details including box score
    func getGame(id gameId: String) async throws -> Game {
        return try await getGamesUseCase.execute(gameId: gameId)
    }
    
    // MARK: - Real-Time Updates
    
    private func setupRealTimeUpdates() {
        guard let realTimeService = realTimeUpdateService else { return }
        
        // Subscribe to connection mode changes
        realTimeService.modePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionMode)
    }
    
    private func startRealTimeUpdates() {
        guard let realTimeService = realTimeUpdateService,
              !isRealTimeActive,
              !liveGames.isEmpty else { return }
        
        isRealTimeActive = true
        
        // Start real-time service (using mock endpoints for now)
        Task {
            await realTimeService.start(
                websocketURL: "wss://api.unrivaled.com/games/live",
                pollingEndpoint: "https://api.unrivaled.com/games/live",
                pollingInterval: 5.0
            )
        }
        
        // Subscribe to real-time updates
        realTimeService.updatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.handleRealTimeUpdate(data: data)
            }
            .store(in: &cancellables)
    }
    
    private func stopRealTimeUpdates() {
        guard let realTimeService = realTimeUpdateService,
              isRealTimeActive else { return }
        
        isRealTimeActive = false
        realTimeService.stop()
    }
    
    private func handleRealTimeUpdate(data: Data) {
        // Parse the update data (assuming it's a Game or BoxScore update)
        // For now, we'll refresh the games list when we receive an update
        // In a real implementation, we'd parse the specific game update and merge it
        
        // Refresh games to get latest scores (use current selectedDate)
        Task {
            do {
                let loadedGames = try await getGamesUseCase.execute(date: selectedDate)
                let displayResult = GamesDisplayManager.organize(loadedGames)
                
                // Only update if we have games loaded
                if case .loaded = state {
                    self.games = displayResult.allGames
                    self.liveGames = displayResult.liveGames
                    self.state = .loaded(games: displayResult.allGames, liveGames: displayResult.liveGames)
                    
                    // Stop real-time if no more live games
                    if !displayResult.hasLiveGames {
                        stopRealTimeUpdates()
                    }
                }
            } catch {
                // Silently fail on real-time update errors to avoid disrupting UI
                // The next manual refresh will recover
            }
        }
    }
}

