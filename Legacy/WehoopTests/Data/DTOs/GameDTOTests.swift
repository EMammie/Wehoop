//
//  GameDTOTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class GameDTOTests: XCTestCase {
    
    func testToDomain_ConvertsGameDTO_ToGame() throws {
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
        
        let gameDTO = GameDTO(
            id: "game-1",
            homeTeam: teamDTO,
            awayTeam: teamDTO,
            date: "2025-01-15T19:00:00Z",
            status: "finished",
            boxScore: nil,
            venue: "Test Arena",
            league: "NBA",
            broadcastNetwork: nil,
            timeZone: nil
        )
        
        // When
        let game = try gameDTO.toDomain()
        
        // Then
        XCTAssertEqual(game.id, "game-1")
        XCTAssertEqual(game.homeTeam.name, "Lakers")
        XCTAssertEqual(game.awayTeam.name, "Lakers")
        XCTAssertEqual(game.status, .finished)
        XCTAssertEqual(game.venue, "Test Arena")
        XCTAssertEqual(game.league, "NBA")
        XCTAssertNotNil(game.date)
    }
    
    func testToDomain_HandlesAllGameStatuses() throws {
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
        
        let statuses: [(String, GameStatus)] = [
            ("scheduled", .scheduled),
            ("live", .live),
            ("finished", .finished),
            ("postponed", .postponed),
            ("cancelled", .cancelled)
        ]
        
        for (statusString, expectedStatus) in statuses {
            let gameDTO = GameDTO(
                id: "game-1",
                homeTeam: teamDTO,
                awayTeam: teamDTO,
                date: "2025-01-15T19:00:00Z",
                status: statusString,
                boxScore: nil,
                venue: nil,
                league: nil,
                broadcastNetwork: nil,
                timeZone: nil
            )
            
            let game = try gameDTO.toDomain()
            XCTAssertEqual(game.status, expectedStatus, "Status '\(statusString)' should map to \(expectedStatus)")
        }
    }
    
    func testToDomain_HandlesCaseInsensitiveStatus() throws {
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
        
        let gameDTO = GameDTO(
            id: "game-1",
            homeTeam: teamDTO,
            awayTeam: teamDTO,
            date: "2025-01-15T19:00:00Z",
            status: "FINISHED", // Uppercase
            boxScore: nil,
            venue: nil,
            league: nil,
            broadcastNetwork: nil,
            timeZone: nil
        )
        
        // When
        let game = try gameDTO.toDomain()
        
        // Then
        XCTAssertEqual(game.status, .finished)
    }
    
    func testToDomain_ThrowsError_ForInvalidDate() {
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
        
        let gameDTO = GameDTO(
            id: "game-1",
            homeTeam: teamDTO,
            awayTeam: teamDTO,
            date: "invalid-date",
            status: "finished",
            boxScore: nil,
            venue: nil,
            league: nil,
            broadcastNetwork: nil,
            timeZone: nil
        )
        
        // When/Then
        XCTAssertThrowsError(try gameDTO.toDomain()) { error in
            if case DTOMappingError.invalidDate = error {
                // Expected error
            } else {
                XCTFail("Expected invalidDate error")
            }
        }
    }
    
    func testToDomain_ThrowsError_ForInvalidStatus() {
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
        
        let gameDTO = GameDTO(
            id: "game-1",
            homeTeam: teamDTO,
            awayTeam: teamDTO,
            date: "2025-01-15T19:00:00Z",
            status: "invalid-status",
            boxScore: nil,
            venue: nil,
            league: nil,
            broadcastNetwork: nil,
            timeZone: nil
        )
        
        // When/Then
        XCTAssertThrowsError(try gameDTO.toDomain()) { error in
            if case DTOMappingError.invalidStatus = error {
                // Expected error
            } else {
                XCTFail("Expected invalidStatus error")
            }
        }
    }
    
    func testToDomain_IncludesBoxScore_WhenPresent() throws {
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
        
        let boxScoreDTO = BoxScoreDTO(
            homeScore: 100,
            awayScore: 95,
            homeStats: TeamStatsDTO(
                points: 100,
                rebounds: 40,
                assists: 25,
                steals: nil,
                blocks: nil,
                turnovers: nil,
                fieldGoalPercentage: nil,
                threePointPercentage: nil,
                freeThrowPercentage: nil,
                fouls: nil
            ),
            awayStats: TeamStatsDTO(
                points: 95,
                rebounds: 35,
                assists: 20,
                steals: nil,
                blocks: nil,
                turnovers: nil,
                fieldGoalPercentage: nil,
                threePointPercentage: nil,
                freeThrowPercentage: nil,
                fouls: nil
            ),
            quarters: nil,
            lastUpdated: "2025-01-15T21:30:00Z"
        )
        
        let gameDTO = GameDTO(
            id: "game-1",
            homeTeam: teamDTO,
            awayTeam: teamDTO,
            date: "2025-01-15T19:00:00Z",
            status: "finished",
            boxScore: boxScoreDTO,
            venue: nil,
            league: nil,
            broadcastNetwork: nil,
            timeZone: nil
        )
        
        // When
        let game = try gameDTO.toDomain()
        
        // Then
        XCTAssertNotNil(game.boxScore)
        XCTAssertEqual(game.boxScore?.homeScore, 100)
        XCTAssertEqual(game.boxScore?.awayScore, 95)
    }
}
