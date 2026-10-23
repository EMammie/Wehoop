//
//  GamesViewModelTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
import Combine
@testable import Wehoop

@MainActor
final class GamesViewModelTests: XCTestCase {
    var sut: GamesViewModel!
    var mockUseCase: GetGamesUseCase!
    var mockRepository: MockGameRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
        mockRepository = MockGameRepository()
        mockUseCase = GetGamesUseCase(gameRepository: mockRepository)
        sut = GamesViewModel(getGamesUseCase: mockUseCase)
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockUseCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    func testInitialState_IsLoading() {
        // Then
        if case .loading = sut.state {
            // Expected initial state
        } else {
            XCTFail("Expected initial state to be .loading, got \(sut.state)")
        }
        XCTAssertTrue(sut.games.isEmpty)
        XCTAssertTrue(sut.liveGames.isEmpty)
    }
    
    func testLoadGames_SetsLoadingState() async {
        // Given
        let expectedGames = [TestDataFactory.makeGame(id: "game1")]
        mockRepository.games = expectedGames
        
        // When
        sut.loadGames()
        
        // Immediately check state (should be loading)
        if case .loading = sut.state {
            // Expected
        } else {
            XCTFail("Expected state to be .loading immediately after loadGames(), got \(sut.state)")
        }
        
        // Wait for async operation to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then state should have transitioned from loading
        if case .loading = sut.state {
            XCTFail("State should have transitioned from .loading after load completes")
        }
    }
    
    func testLoadGames_PreventsMultipleSimultaneousLoads() async {
        // Given
        let expectedGames = [TestDataFactory.makeGame(id: "game1")]
        mockRepository.games = expectedGames
        
        // Set initial state to something other than loading so loadGames actually runs
        // First, let one load complete
        sut.loadGames()
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for first load
        
        // Reset call count
        mockRepository.getGamesCallCount = 0
        
        // When - call loadGames multiple times rapidly
        sut.loadGames()
        sut.loadGames() // Should be ignored if already loading
        sut.loadGames() // Should be ignored if already loading
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then - should only have called repository once (not three times)
        XCTAssertEqual(mockRepository.getGamesCallCount, 1, "Should prevent multiple simultaneous loads")
    }
    
    func testLoadGames_UpdatesGames_WhenSuccessful() async {
        // Given
        let expectedGames = [
            TestDataFactory.makeGame(id: "game1"),
            TestDataFactory.makeGame(id: "game2")
        ]
        mockRepository.games = expectedGames
        
        // When
        sut.loadGames()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds


        // Then
        XCTAssertNotNil(sut.games)
        XCTAssertEqual(sut.games.count, 2)
        //XCTAssertEqual(sut.games[0].id, "game1")
        
        // Verify state is .loaded
        if case .loaded(let games, let liveGames) = sut.state {
            XCTAssertEqual(games.count, 2)
            XCTAssertEqual(liveGames.count, 0) // No live games in test data
        } else {
            XCTFail("Expected state to be .loaded, got \(sut.state)")
        }
    }
    
    func testLoadGames_SetsError_WhenFails() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: 500)
        mockRepository.getGamesError = expectedError
        
        // When
        sut.loadGames()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        if case .error(let error) = sut.state {
            XCTAssertEqual((error as NSError).code, 500)
        } else {
            XCTFail("Expected state to be .error, got \(sut.state)")
        }
        XCTAssertTrue(sut.games.isEmpty)
        XCTAssertTrue(sut.liveGames.isEmpty)
    }
    
    func testLoadGames_SetsEmptyState_WhenNoGames() async {
        // Given
        mockRepository.games = []
        
        // When
        sut.loadGames()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        if case .empty = sut.state {
            // Expected empty state
        } else {
            XCTFail("Expected state to be .empty, got \(sut.state)")
        }
        XCTAssertTrue(sut.games.isEmpty)
        XCTAssertTrue(sut.liveGames.isEmpty)
    }
    
    func testLoadGames_FiltersLiveGames() async {
        // Given
        let liveGame = TestDataFactory.makeGame(id: "live-game", status: .live)
        let finishedGame = TestDataFactory.makeGame(id: "finished-game", status: .finished)
        mockRepository.games = [liveGame, finishedGame]
        
        // When
        sut.loadGames()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(sut.games.count, 2)
        XCTAssertEqual(sut.liveGames.count, 1)
        XCTAssertEqual(sut.liveGames.first?.id, "live-game")
        
        if case .loaded(let games, let liveGames) = sut.state {
            XCTAssertEqual(games.count, 2)
            XCTAssertEqual(liveGames.count, 1)
        } else {
            XCTFail("Expected state to be .loaded, got \(sut.state)")
        }
    }
    
    func testRefreshGames_CallsLoadGames() async {
        // Given
        let expectedGames = [TestDataFactory.makeGame(id: "game1")]
        mockRepository.games = expectedGames
        
        // When
        sut.refreshGames()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(sut.games.count, 1)
        if case .loaded = sut.state {
            // Expected loaded state
        } else {
            XCTFail("Expected state to be .loaded after refresh, got \(sut.state)")
        }
    }
    
    func testHasGames_ReturnsTrue_WhenGamesExist() async {
        // Given
        mockRepository.games = [TestDataFactory.makeGame(id: "game1")]
        
        // When
        sut.loadGames()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(sut.hasGames)
    }
    
    func testHasLiveGames_ReturnsTrue_WhenLiveGamesExist() async {
        // Given
        let liveGame = TestDataFactory.makeGame(id: "live-game", status: .live)
        mockRepository.games = [liveGame]
        
        // When
        sut.loadGames()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(sut.hasLiveGames)
    }
    
    // MARK: - Date Parameter Tests
    
    func testSelectedDate_DefaultsToToday() {
        // Then
        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDate(sut.selectedDate, inSameDayAs: Date()), 
                     "selectedDate should default to today")
    }
    
    func testLoadGames_WithDate_UpdatesSelectedDate() async {
        // Given
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: 5, to: Date()) ?? Date()
        mockRepository.games = [TestDataFactory.makeGame(id: "game1")]
        
        // When
        sut.loadGames(for: targetDate)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(calendar.isDate(sut.selectedDate, inSameDayAs: targetDate),
                     "selectedDate should be updated to target date")
    }
    
    func testLoadGames_WithDate_PassesDateToUseCase() async {
        // Given
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let gameOnDate = TestDataFactory.makeGame(id: "game1", date: targetDate)
        let gameOnDifferentDate = TestDataFactory.makeGame(
            id: "game2",
            date: calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
        )
        mockRepository.games = [gameOnDate, gameOnDifferentDate]
        
        // When
        sut.loadGames(for: targetDate)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - Repository should have been called with the date
        XCTAssertGreaterThan(mockRepository.getGamesCallCount, 0)
        // Games should be filtered by date
        XCTAssertEqual(sut.games.count, 1, "Should only return games on target date")
        XCTAssertEqual(sut.games.first?.id, "game1")
    }
    
    func testLoadGames_WithoutDate_UsesSelectedDate() async {
        // Given
        let calendar = Calendar.current
        let initialDate = calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        sut.selectedDate = initialDate
        
        let gameOnDate = TestDataFactory.makeGame(id: "game1", date: initialDate)
        mockRepository.games = [gameOnDate]
        
        // When - Call loadGames without date parameter
        sut.loadGames()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - Should use selectedDate
        XCTAssertTrue(calendar.isDate(sut.selectedDate, inSameDayAs: initialDate))
        XCTAssertEqual(sut.games.count, 1)
    }
    
    func testRefreshGames_UsesSelectedDate() async {
        // Given
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        sut.selectedDate = targetDate
        mockRepository.games = [TestDataFactory.makeGame(id: "game1", date: targetDate)]
        
        // When
        sut.refreshGames()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - Should use selectedDate when refreshing
        XCTAssertTrue(calendar.isDate(sut.selectedDate, inSameDayAs: targetDate))
        XCTAssertEqual(sut.games.count, 1)
    }
}
