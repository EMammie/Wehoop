//
//  GameTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class GameTests: XCTestCase {
    func testGame_Initialization() {
        // Given
        let homeTeam = TestDataFactory.makeTeam(id: "home", name: "Home Team")
        let awayTeam = TestDataFactory.makeTeam(id: "away", name: "Away Team")
        let date = Date()
        
        // When
        let game = Game(
            id: "game1",
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            date: date,
            status: .scheduled,
            boxScore: nil,
            venue: "Test Arena",
            league: nil,
            broadcastNetwork: nil,
            timeZone: nil
        )
        
        // Then
        XCTAssertEqual(game.id, "game1")
        XCTAssertEqual(game.homeTeam.id, "home")
        XCTAssertEqual(game.awayTeam.id, "away")
        XCTAssertEqual(game.status, .scheduled)
        XCTAssertNil(game.boxScore)
        XCTAssertEqual(game.venue, "Test Arena")
    }
    
    func testGame_WithBoxScore() {
        // Given
        let boxScore = TestDataFactory.makeBoxScore(homeScore: 100, awayScore: 95)
        let game = TestDataFactory.makeGame(id: "game1")
        
        // When
        let gameWithScore = Game(
            id: game.id,
            homeTeam: game.homeTeam,
            awayTeam: game.awayTeam,
            date: game.date,
            status: .finished,
            boxScore: boxScore,
            venue: game.venue,
            league: game.league,
            broadcastNetwork: game.broadcastNetwork,
            timeZone: game.timeZone
        )
        
        // Then
        XCTAssertNotNil(gameWithScore.boxScore)
        XCTAssertEqual(gameWithScore.boxScore?.homeScore, 100)
        XCTAssertEqual(gameWithScore.boxScore?.awayScore, 95)
        XCTAssertEqual(gameWithScore.status, .finished)
    }
    
    func testGame_ComputedProperties() {
        // Given
        let boxScore = TestDataFactory.makeBoxScore(homeScore: 100, awayScore: 95)
        let game = TestDataFactory.makeGame(id: "game1", status: .finished)
        let gameWithScore = Game(
            id: game.id,
            homeTeam: game.homeTeam,
            awayTeam: game.awayTeam,
            date: game.date,
            status: .finished,
            boxScore: boxScore,
            venue: game.venue,
            league: game.league,
            broadcastNetwork: game.broadcastNetwork,
            timeZone: game.timeZone
        )
        
        // Then
        XCTAssertTrue(gameWithScore.isFinished)
        XCTAssertFalse(gameWithScore.isLive)
        XCTAssertEqual(gameWithScore.scoreDisplay, "100 - 95")
        XCTAssertNotNil(gameWithScore.winningTeam)
        XCTAssertNotNil(gameWithScore.losingTeam)
    }
    
    func testGameStatus_EnumValues() {
        // Then
        XCTAssertEqual(GameStatus.scheduled.rawValue, "scheduled")
        XCTAssertEqual(GameStatus.live.rawValue, "live")
        XCTAssertEqual(GameStatus.finished.rawValue, "finished")
        XCTAssertEqual(GameStatus.postponed.rawValue, "postponed")
        XCTAssertEqual(GameStatus.cancelled.rawValue, "cancelled")
    }
    
    func testGameStatus_DisplayNames() {
        // Then
        XCTAssertEqual(GameStatus.scheduled.displayName, "Scheduled")
        XCTAssertEqual(GameStatus.live.displayName, "Live")
        XCTAssertEqual(GameStatus.finished.displayName, "Final")
        XCTAssertEqual(GameStatus.postponed.displayName, "Postponed")
        XCTAssertEqual(GameStatus.cancelled.displayName, "Cancelled")
    }
}
