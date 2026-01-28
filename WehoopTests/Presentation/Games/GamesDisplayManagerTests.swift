//
//  GamesDisplayManagerTests.swift
//  WehoopTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class GamesDisplayManagerTests: XCTestCase {
    
    // MARK: - Categorization Tests
    
    func testOrganize_LiveGames_AreCorrectlyIdentified() {
        // Given
        let liveGame = GameFixtures.liveGame()
        let games = [liveGame, GameFixtures.finishedGame(), GameFixtures.scheduledGame()]
        
        // When
        let result = GamesDisplayManager.organize(games)
        
        // Then
        XCTAssertEqual(result.liveGames.count, 1, "Should identify one live game")
        XCTAssertEqual(result.liveGames.first?.id, liveGame.id, "Live game should match")
        XCTAssertTrue(result.hasLiveGames, "Should have live games")
    }
    
    func testOrganize_UpcomingGames_IncludeScheduledAndFutureDated() {
        // Given
        let scheduledGame = GameFixtures.scheduledGame()
        let postponedGame = GameFixtures.postponedGame()
        let games = [scheduledGame, postponedGame, GameFixtures.finishedGame()]
        
        // When
        let result = GamesDisplayManager.organize(games)
        
        // Then
        XCTAssertEqual(result.upcomingGames.count, 2, "Should identify two upcoming games")
        XCTAssertTrue(result.upcomingGames.contains { $0.id == scheduledGame.id }, "Should include scheduled game")
        XCTAssertTrue(result.upcomingGames.contains { $0.id == postponedGame.id }, "Should include postponed game")
        XCTAssertTrue(result.hasUpcomingGames, "Should have upcoming games")
    }
    
    func testOrganize_FinishedGames_IncludeFinishedStatusAndPastGamesWithScores() {
        // Given
        let finishedGame = GameFixtures.finishedGame()
        let gameWithCloseScore = GameFixtures.gameWithCloseScore()
        let cancelledGame = GameFixtures.cancelledGame()
        let games = [finishedGame, gameWithCloseScore, cancelledGame, GameFixtures.scheduledGame()]
        
        // When
        let result = GamesDisplayManager.organize(games)
        
        // Then
        XCTAssertTrue(result.finishedGames.count >= 2, "Should identify finished games")
        XCTAssertTrue(result.finishedGames.contains { $0.id == finishedGame.id }, "Should include finished game")
        XCTAssertTrue(result.finishedGames.contains { $0.id == gameWithCloseScore.id }, "Should include game with close score")
        XCTAssertTrue(result.hasFinishedGames, "Should have finished games")
    }
    
    func testOrganize_CancelledGames_GoToFinished() {
        // Given
        let cancelledGame = GameFixtures.cancelledGame()
        let games = [cancelledGame, GameFixtures.scheduledGame()]
        
        // When
        let result = GamesDisplayManager.organize(games)
        
        // Then
        XCTAssertTrue(result.finishedGames.contains { $0.id == cancelledGame.id }, "Cancelled games should go to finished")
        XCTAssertFalse(result.upcomingGames.contains { $0.id == cancelledGame.id }, "Cancelled games should not be in upcoming")
    }
    
    func testOrganize_PostponedGames_GoToUpcoming() {
        // Given
        let postponedGame = GameFixtures.postponedGame()
        let games = [postponedGame, GameFixtures.finishedGame()]
        
        // When
        let result = GamesDisplayManager.organize(games)
        
        // Then
        XCTAssertTrue(result.upcomingGames.contains { $0.id == postponedGame.id }, "Postponed games should go to upcoming")
        XCTAssertFalse(result.finishedGames.contains { $0.id == postponedGame.id }, "Postponed games should not be in finished")
    }
    
    // MARK: - Sorting Tests
    
    func testOrganize_AllCategories_SortedByDateDescending() {
        // Given
        let calendar = Calendar.current
        let now = Date()
        let game1 = createGame(id: "game-1", date: now.addingTimeInterval(-3600), status: .finished) // 1 hour ago
        let game2 = createGame(id: "game-2", date: now.addingTimeInterval(-7200), status: .finished) // 2 hours ago
        let game3 = createGame(id: "game-3", date: now.addingTimeInterval(3600), status: .scheduled) // 1 hour from now
        let game4 = createGame(id: "game-4", date: now.addingTimeInterval(7200), status: .scheduled) // 2 hours from now
        let game5 = createGame(id: "game-5", date: now, status: .live)
        let game6 = createGame(id: "game-6", date: now.addingTimeInterval(-1800), status: .live) // 30 min ago
        
        let games = [game1, game2, game3, game4, game5, game6]
        
        // When
        let result = GamesDisplayManager.organize(games)
        
        // Then
        // Check finished games are sorted descending (most recent first)
        XCTAssertEqual(result.finishedGames.count, 2)
        XCTAssertEqual(result.finishedGames[0].id, "game-1", "Most recent finished game should be first")
        XCTAssertEqual(result.finishedGames[1].id, "game-2", "Older finished game should be second")
        
        // Check upcoming games are sorted descending (most recent first)
        XCTAssertEqual(result.upcomingGames.count, 2)
        XCTAssertEqual(result.upcomingGames[0].id, "game-3", "Most recent upcoming game should be first")
        XCTAssertEqual(result.upcomingGames[1].id, "game-4", "Future upcoming game should be second")
        
        // Check live games are sorted descending (most recent first)
        XCTAssertEqual(result.liveGames.count, 2)
        XCTAssertEqual(result.liveGames[0].id, "game-5", "Most recent live game should be first")
        XCTAssertEqual(result.liveGames[1].id, "game-6", "Older live game should be second")
        
        // Check allGames are sorted descending
        XCTAssertEqual(result.allGames.count, 6)
        XCTAssertEqual(result.allGames[0].id, "game-4", "Most future game should be first in allGames")
    }
    
    // MARK: - Edge Cases
    
    func testOrganize_EmptyArray_ReturnsEmptyResult() {
        // Given
        let games: [Game] = []
        
        // When
        let result = GamesDisplayManager.organize(games)
        
        // Then
        XCTAssertTrue(result.liveGames.isEmpty, "Live games should be empty")
        XCTAssertTrue(result.upcomingGames.isEmpty, "Upcoming games should be empty")
        XCTAssertTrue(result.finishedGames.isEmpty, "Finished games should be empty")
        XCTAssertTrue(result.allGames.isEmpty, "All games should be empty")
        XCTAssertTrue(result.isEmpty, "Result should be empty")
        XCTAssertFalse(result.hasLiveGames, "Should not have live games")
        XCTAssertFalse(result.hasUpcomingGames, "Should not have upcoming games")
        XCTAssertFalse(result.hasFinishedGames, "Should not have finished games")
    }
    
    func testOrganize_MixedStatuses_AreCorrectlyCategorized() {
        // Given
        let liveGame = GameFixtures.liveGame()
        let scheduledGame = GameFixtures.scheduledGame()
        let finishedGame = GameFixtures.finishedGame()
        let postponedGame = GameFixtures.postponedGame()
        let cancelledGame = GameFixtures.cancelledGame()
        let games = [liveGame, scheduledGame, finishedGame, postponedGame, cancelledGame]
        
        // When
        let result = GamesDisplayManager.organize(games)
        
        // Then
        XCTAssertEqual(result.liveGames.count, 1, "Should have one live game")
        XCTAssertEqual(result.upcomingGames.count, 2, "Should have two upcoming games (scheduled + postponed)")
        XCTAssertTrue(result.finishedGames.count >= 2, "Should have at least two finished games (finished + cancelled)")
        XCTAssertEqual(result.allGames.count, 5, "Should have all five games")
    }
    
    func testOrganize_PastGameWithScores_GoesToFinished() {
        // Given
        let calendar = Calendar.current
        let pastDate = calendar.date(byAdding: .day, value: -1, to: Date())!
        let pastGameWithScore = createGame(
            id: "past-game",
            date: pastDate,
            status: .scheduled, // Status is scheduled but date is in past
            boxScore: GameFixtures.boxScore()
        )
        let games = [pastGameWithScore]
        
        // When
        let result = GamesDisplayManager.organize(games)
        
        // Then
        XCTAssertTrue(result.finishedGames.contains { $0.id == "past-game" }, "Past game with score should go to finished")
        XCTAssertFalse(result.upcomingGames.contains { $0.id == "past-game" }, "Past game should not be in upcoming")
    }
    
    func testOrganize_FutureGameWithScheduledStatus_GoesToUpcoming() {
        // Given
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        let futureGame = createGame(
            id: "future-game",
            date: futureDate,
            status: .scheduled
        )
        let games = [futureGame]
        
        // When
        let result = GamesDisplayManager.organize(games)
        
        // Then
        XCTAssertTrue(result.upcomingGames.contains { $0.id == "future-game" }, "Future scheduled game should go to upcoming")
        XCTAssertFalse(result.finishedGames.contains { $0.id == "future-game" }, "Future game should not be in finished")
    }
    
    func testOrganize_AllGames_ContainsAllInputGames() {
        // Given
        let games = GameFixtures.sampleGames()
        
        // When
        let result = GamesDisplayManager.organize(games)
        
        // Then
        let totalCategorized = result.liveGames.count + result.upcomingGames.count + result.finishedGames.count
        XCTAssertEqual(totalCategorized, games.count, "All games should be categorized")
        XCTAssertEqual(result.allGames.count, games.count, "All games should be in allGames")
    }
    
    // MARK: - Helper Methods
    
    private func createGame(
        id: String,
        date: Date,
        status: GameStatus,
        boxScore: BoxScore? = nil
    ) -> Game {
        Game(
            id: id,
            homeTeam: GameFixtures.mistBC(),
            awayTeam: GameFixtures.lunarOwlsBC(),
            date: date,
            status: status,
            boxScore: boxScore,
            venue: "Test Arena",
            league: "Test League",
            broadcastNetwork: nil,
            timeZone: nil
        )
    }
}
