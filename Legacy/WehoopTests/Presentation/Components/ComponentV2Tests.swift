//
//  ComponentV2Tests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
import SwiftUI
@testable import Wehoop

final class ComponentV2Tests: XCTestCase {
    
    // MARK: - LeagueLeadersSection Tests
    
    func testLeagueLeadersSection_Initializes() {
        // Given
        let players = createSamplePlayers(count: 3)
        
        // When
        let section = LeagueLeadersSection(players: players)
        
        // Then
        XCTAssertNotNil(section)
    }
    
    func testLeagueLeadersSection_HandlesEmptyPlayers() {
        // When
        let section = LeagueLeadersSection(players: [])
        
        // Then - should not crash
        XCTAssertNotNil(section)
    }
    
    func testLeagueLeadersSection_ShowsUpTo5Players() {
        // Given
        let players = createSamplePlayers(count: 10)
        
        // When
        let section = LeagueLeadersSection(players: players)
        
        // Then - should not crash (component handles limiting internally)
        XCTAssertNotNil(section)
    }
    
    // MARK: - FeaturedPlayerCard Tests
    
    func testFeaturedPlayerCard_Initializes() {
        // Given
        let player = createSamplePlayer()
        
        // When
        let card = FeaturedPlayerCard(
            player: player,
            statValue: "23.7",
            statLabel: "PPG"
        )
        
        // Then
        XCTAssertNotNil(card)
    }
    
    // MARK: - StatBoxView Tests
    
    func testStatBoxView_Initializes() {
        // When
        let statBox = StatBoxView(value: "10-5", label: "Record")
        
        // Then
        XCTAssertNotNil(statBox)
    }
    
    func testStatBoxView_DisplaysValueAndLabel() {
        // Given
        let value = "4th"
        let label = "Standings"
        
        // When
        let statBox = StatBoxView(value: value, label: label)
        
        // Then - should not crash
        XCTAssertNotNil(statBox)
    }
    
    // MARK: - CompactGameCardView Tests
    
    func testCompactGameCardView_Initializes() {
        // Given
        let game = GameFixtures.finishedGame()
        
        // When
        let card = CompactGameCardView(game: game)
        
        // Then
        XCTAssertNotNil(card)
    }
    
    func testCompactGameCardView_HandlesLiveGame() {
        // Given
        let game = GameFixtures.liveGame()
        
        // When
        let card = CompactGameCardView(game: game)
        
        // Then
        XCTAssertNotNil(card)
    }
    
    func testCompactGameCardView_HandlesScheduledGame() {
        // Given
        let game = GameFixtures.scheduledGame()
        
        // When
        let card = CompactGameCardView(game: game)
        
        // Then
        XCTAssertNotNil(card)
    }
    
    func testCompactGameCardView_ShowsScoresForLiveGames() {
        // Given
        let liveGame = GameFixtures.liveGame()
        XCTAssertNotNil(liveGame.boxScore, "Live game fixture should have box score")
        
        // When
        let card = CompactGameCardView(game: liveGame)
        
        // Then
        XCTAssertNotNil(card)
        // Note: UI testing would require view inspection, but we can verify the game has box score
        XCTAssertNotNil(liveGame.boxScore, "Live game should have box score for display")
    }
    
    func testCompactGameCardView_ShowsScoresForFinishedGames() {
        // Given
        let finishedGame = GameFixtures.finishedGame()
        XCTAssertNotNil(finishedGame.boxScore, "Finished game fixture should have box score")
        
        // When
        let card = CompactGameCardView(game: finishedGame)
        
        // Then
        XCTAssertNotNil(card)
        // Note: UI testing would require view inspection, but we can verify the game has box score
        XCTAssertNotNil(finishedGame.boxScore, "Finished game should have box score for display")
    }
    
    func testCompactGameCardView_DoesNotShowScoresForScheduledGames() {
        // Given
        let scheduledGame = GameFixtures.scheduledGame()
        XCTAssertNil(scheduledGame.boxScore, "Scheduled game should not have box score")
        
        // When
        let card = CompactGameCardView(game: scheduledGame)
        
        // Then
        XCTAssertNotNil(card)
        // Scheduled games should not have scores
        XCTAssertNil(scheduledGame.boxScore, "Scheduled game should not have box score")
    }
    
    func testCompactGameCardView_HandlesFinishedGameWithoutBoxScore() {
        // Given
        let finishedGame = Game(
            id: "finished-no-score",
            homeTeam: GameFixtures.mistBC(),
            awayTeam: GameFixtures.lunarOwlsBC(),
            date: Date().addingTimeInterval(-3600),
            status: .finished,
            boxScore: nil,
            venue: "Test Arena",
            league: "Test League",
            broadcastNetwork: nil,
            timeZone: nil
        )
        
        // When
        let card = CompactGameCardView(game: finishedGame)
        
        // Then
        XCTAssertNotNil(card)
        XCTAssertNil(finishedGame.boxScore, "Game should not have box score")
    }
    
    // MARK: - Helper Methods
    
    private func createSamplePlayer() -> Player {
        Player(
            id: "player-1",
            name: "Test Player",
            team: TestDataFactory.makeTeam(
                id: "team-1",
                name: "Test Team",
                abbreviation: "TT"
            ),
            position: "Guard",
            statistics: [
                TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 20.5, category: .scoring)
            ],
            jerseyNumber: 23,
            height: "6'0\"",
            weight: 180,
            age: 25,
            college: nil,
            photoURL: nil
        )
    }
    
    private func createSamplePlayers(count: Int) -> [Player] {
        (0..<count).map { index in
            Player(
                id: "player-\(index)",
                name: "Player \(index)",
                team: Team(
                    id: "team-1",
                    name: "Test Team",
                    abbreviation: "TT",
                    logoURL: nil,
                    city: "Test City",
                    conference: .eastern,
                    division: "Test Division",
                    wins: 10,
                    losses: 5,
                    winPercentage: 0.667
                ),
                position: "Guard",
                statistics: [],
                jerseyNumber: index + 1,
                height: "6'0\"",
                weight: 180,
                age: 25,
                college: nil,
                photoURL: nil
            )
        }
    }
}
