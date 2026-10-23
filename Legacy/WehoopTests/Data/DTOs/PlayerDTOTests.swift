//
//  PlayerDTOTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class PlayerDTOTests: XCTestCase {
    
    func testToDomain_ConvertsPlayerDTO_ToPlayer() throws {
        // Given
        let teamDTO = TeamDTO(
            id: "team-1",
            name: "Lakers",
            abbreviation: "LAL",
            logoURL: nil,
            city: "Los Angeles",
            conference: "Western",
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        let statisticDTO = StatisticDTO(
            id: "stat-1",
            name: "Points Per Game",
            value: 25.5,
            category: "scoring",
            unit: "points",
            season: "2024-25",
            gamesPlayed: 65
        )
        
        let playerDTO = PlayerDTO(
            id: "player-1",
            name: "Test Player",
            team: teamDTO,
            position: "Point Guard",
            statistics: [statisticDTO],
            jerseyNumber: 23,
            height: "6'9\"",
            weight: 250,
            age: 30,
            college: nil,
            photoURL: "https://example.com/photo.jpg"
        )
        
        // When
        let player = try playerDTO.toDomain()
        
        // Then
        XCTAssertEqual(player.id, "player-1")
        XCTAssertEqual(player.name, "Test Player")
        XCTAssertEqual(player.team.id, "team-1")
        XCTAssertEqual(player.position, "Point Guard")
        XCTAssertEqual(player.statistics.count, 1)
        XCTAssertEqual(player.jerseyNumber, 23)
        XCTAssertEqual(player.height, "6'9\"")
        XCTAssertEqual(player.weight, 250)
        XCTAssertEqual(player.age, 30)
        XCTAssertEqual(player.photoURL, "https://example.com/photo.jpg")
    }
    
    func testToDomain_HandlesAllStatCategories() throws {
        // Given
        let teamDTO = TeamDTO(
            id: "team-1",
            name: "Team",
            abbreviation: "T",
            logoURL: nil,
            city: nil,
            conference: nil,
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        let categories: [(String, StatCategory)] = [
            ("scoring", .scoring),
            ("rebounding", .rebounding),
            ("assists", .assists),
            ("defense", .defense),
            ("efficiency", .efficiency),
            ("shooting", .shooting),
            ("turnovers", .turnovers)
        ]
        
        for (categoryString, expectedCategory) in categories {
            let statisticDTO = StatisticDTO(
                id: "stat-1",
                name: "Test Stat",
                value: 10.0,
                category: categoryString,
                unit: nil,
                season: nil,
                gamesPlayed: nil
            )
            
            let playerDTO = PlayerDTO(
                id: "player-1",
                name: "Test Player",
                team: teamDTO,
                position: "PG",
                statistics: [statisticDTO],
                jerseyNumber: nil,
                height: nil,
                weight: nil,
                age: nil,
                college: nil,
                photoURL: nil
            )
            
            let player = try playerDTO.toDomain()
            let statistic = player.statistics.first
            XCTAssertEqual(statistic?.category, expectedCategory, "Category '\(categoryString)' should map to \(expectedCategory)")
        }
    }
    
    func testToDomain_HandlesCaseInsensitiveCategory() throws {
        // Given
        let teamDTO = TeamDTO(
            id: "team-1",
            name: "Team",
            abbreviation: "T",
            logoURL: nil,
            city: nil,
            conference: nil,
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        let statisticDTO = StatisticDTO(
            id: "stat-1",
            name: "Test Stat",
            value: 10.0,
            category: "SCORING", // Uppercase
            unit: nil,
            season: nil,
            gamesPlayed: nil
        )
        
        let playerDTO = PlayerDTO(
            id: "player-1",
            name: "Test Player",
            team: teamDTO,
            position: "PG",
            statistics: [statisticDTO],
            jerseyNumber: nil,
            height: nil,
            weight: nil,
            age: nil,
            college: nil,
            photoURL: nil
        )
        
        // When
        let player = try playerDTO.toDomain()
        
        // Then
        XCTAssertEqual(player.statistics.first?.category, .scoring)
    }
    
    func testToDomain_ThrowsError_ForInvalidCategory() {
        // Given
        let teamDTO = TeamDTO(
            id: "team-1",
            name: "Team",
            abbreviation: "T",
            logoURL: nil,
            city: nil,
            conference: nil,
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        let statisticDTO = StatisticDTO(
            id: "stat-1",
            name: "Test Stat",
            value: 10.0,
            category: "invalid-category",
            unit: nil,
            season: nil,
            gamesPlayed: nil
        )
        
        let playerDTO = PlayerDTO(
            id: "player-1",
            name: "Test Player",
            team: teamDTO,
            position: "PG",
            statistics: [statisticDTO],
            jerseyNumber: nil,
            height: nil,
            weight: nil,
            age: nil,
            college: nil,
            photoURL: nil
        )
        
        // When/Then
        XCTAssertThrowsError(try playerDTO.toDomain()) { error in
            if case DTOMappingError.invalidStatus = error {
                // Expected error (reusing invalidStatus for category)
            } else {
                XCTFail("Expected invalidStatus error for invalid category")
            }
        }
    }
    
    func testToDomain_HandlesOptionalFields() throws {
        // Given
        let teamDTO = TeamDTO(
            id: "team-1",
            name: "Team",
            abbreviation: "T",
            logoURL: nil,
            city: nil,
            conference: nil,
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        let playerDTO = PlayerDTO(
            id: "player-1",
            name: "Test Player",
            team: teamDTO,
            position: "PG",
            statistics: [],
            jerseyNumber: nil,
            height: nil,
            weight: nil,
            age: nil,
            college: nil,
            photoURL: nil
        )
        
        // When
        let player = try playerDTO.toDomain()
        
        // Then
        XCTAssertNil(player.jerseyNumber)
        XCTAssertNil(player.height)
        XCTAssertNil(player.weight)
        XCTAssertNil(player.age)
        XCTAssertNil(player.photoURL)
    }
    
    func testToDomain_HandlesMultipleStatistics() throws {
        // Given
        let teamDTO = TeamDTO(
            id: "team-1",
            name: "Team",
            abbreviation: "T",
            logoURL: nil,
            city: nil,
            conference: nil,
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        let statistics = [
            StatisticDTO(id: "stat-1", name: "Points", value: 25.5, category: "scoring", unit: "points", season: nil, gamesPlayed: nil),
            StatisticDTO(id: "stat-2", name: "Rebounds", value: 8.2, category: "rebounding", unit: "rebounds", season: nil, gamesPlayed: nil),
            StatisticDTO(id: "stat-3", name: "Assists", value: 7.8, category: "assists", unit: "assists", season: nil, gamesPlayed: nil)
        ]
        
        let playerDTO = PlayerDTO(
            id: "player-1",
            name: "Test Player",
            team: teamDTO,
            position: "PG",
            statistics: statistics,
            jerseyNumber: nil,
            height: nil,
            weight: nil,
            age: nil,
            college: nil,
            photoURL: nil
        )
        
        // When
        let player = try playerDTO.toDomain()
        
        // Then
        XCTAssertEqual(player.statistics.count, 3)
    }
}
