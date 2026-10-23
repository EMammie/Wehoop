//
//  PlayerTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class PlayerTests: XCTestCase {
    func testPlayer_Initialization() {
        // Given
        let team = TestDataFactory.makeTeam(id: "team1", name: "Test Team")
        let statistics = [
            TestDataFactory.makeStatistic(name: "Points", value: 25.5),
            TestDataFactory.makeStatistic(name: "Rebounds", value: 10.0)
        ]
        
        // When
        let player = Player(
            id: "player1",
            name: "John Doe",
            team: team,
            position: "PG",
            statistics: statistics,
            jerseyNumber: 23,
            height: "6'8\"",
            weight: 220,
            age: 28,
            college: nil,
            photoURL: nil
        )
        
        // Then
        XCTAssertEqual(player.id, "player1")
        XCTAssertEqual(player.name, "John Doe")
        XCTAssertEqual(player.team.id, "team1")
        XCTAssertEqual(player.position, "PG")
        XCTAssertEqual(player.statistics.count, 2)
        XCTAssertEqual(player.jerseyNumber, 23)
        XCTAssertEqual(player.height, "6'8\"")
        XCTAssertEqual(player.weight, 220)
        XCTAssertEqual(player.age, 28)
    }
    
    func testPlayer_WithEmptyStatistics() {
        // When
        let player = TestDataFactory.makePlayer(id: "player1", name: "Test Player")
        
        // Then
        XCTAssertTrue(player.statistics.isEmpty)
    }
    
    func testPlayer_ComputedProperties() {
        // Given
        let player = TestDataFactory.makePlayer(id: "player1", name: "John Doe", jerseyNumber: 23)
        
        // Then
        XCTAssertEqual(player.displayName, "#23 John Doe")
        XCTAssertEqual(player.positionAbbreviation, "PG")
    }
    
    func testPlayer_StatisticHelpers() {
        // Given
        let statistics = [
            TestDataFactory.makeStatistic(name: "Points", value: 25.5, category: .scoring),
            TestDataFactory.makeStatistic(name: "Assists", value: 8.0, category: .assists)
        ]
        let team = TestDataFactory.makeTeam()
        let player = Player(
            id: "player1",
            name: "Test Player",
            team: team,
            position: "PG",
            statistics: statistics,
            jerseyNumber: nil,
            height: nil,
            weight: nil,
            age: nil,
            college: nil,
            photoURL: nil
        )
        
        // Then
        XCTAssertNotNil(player.statistic(for: .scoring))
        XCTAssertEqual(player.statistic(for: .scoring)?.value, 25.5)
        XCTAssertNotNil(player.statistic(named: "Points"))
        XCTAssertEqual(player.pointsPerGame, 25.5)
        XCTAssertEqual(player.assistsPerGame, 8.0)
    }
}
