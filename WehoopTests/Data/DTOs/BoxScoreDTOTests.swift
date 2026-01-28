//
//  BoxScoreDTOTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class BoxScoreDTOTests: XCTestCase {
    
    func testToDomain_ConvertsBoxScoreDTO_ToBoxScore() throws {
        // Given
        let boxScoreDTO = BoxScoreDTOBuilder()
            .withHomeScore(100)
            .withAwayScore(95)
            .withHomeStats { builder in
                builder
                    .withPoints(100)
                    .withRebounds(40)
                    .withAssists(25)
                    .withSteals(8)
                    .withBlocks(5)
                    .withTurnovers(12)
                    .withFieldGoalPercentage(48.5)
                    .withThreePointPercentage(38.2)
                    .withFreeThrowPercentage(82.1)
                    .withFouls(18)
            }
            .withAwayStats { builder in
                builder
                    .withPoints(95)
                    .withRebounds(35)
                    .withAssists(20)
                    .withSteals(6)
                    .withBlocks(3)
                    .withTurnovers(15)
                    .withFieldGoalPercentage(45.2)
                    .withThreePointPercentage(35.8)
                    .withFreeThrowPercentage(78.5)
                    .withFouls(20)
            }
            .withLastUpdated("2025-01-15T21:30:00Z")
            .build()
        
        // When
        let boxScore = try boxScoreDTO.toDomain()
        
        // Then
        XCTAssertEqual(boxScore.homeScore, 100)
        XCTAssertEqual(boxScore.awayScore, 95)
        XCTAssertEqual(boxScore.homeStats.points, 100)
        XCTAssertEqual(boxScore.awayStats.points, 95)
        XCTAssertNotNil(boxScore.lastUpdated)
    }
    
    func testToDomain_HandlesQuarters() throws {
        // Given
        let boxScoreDTO = BoxScoreDTOBuilder()
            .withHomeScore(100)
            .withAwayScore(95)
            .withStandardQuarters()
            .build()
        
        // When
        let boxScore = try boxScoreDTO.toDomain()
        
        // Then
        XCTAssertNotNil(boxScore.quarters)
        XCTAssertEqual(boxScore.quarters?.count, 4)
        XCTAssertEqual(boxScore.quarters?.first?.quarterNumber, 1)
    }
    
    func testToDomain_HandlesCustomQuarters() throws {
        // Given
        let quarters = [
            QuarterScoreDTOBuilder().withQuarterNumber(1).withHomeScore(25).withAwayScore(20).build(),
            QuarterScoreDTOBuilder().withQuarterNumber(2).withHomeScore(25).withAwayScore(25).build(),
            QuarterScoreDTOBuilder().withQuarterNumber(3).withHomeScore(30).withAwayScore(25).build(),
            QuarterScoreDTOBuilder().withQuarterNumber(4).withHomeScore(20).withAwayScore(25).build()
        ]
        
        let boxScoreDTO = BoxScoreDTOBuilder()
            .withHomeScore(100)
            .withAwayScore(95)
            .withQuarters(quarters)
            .build()
        
        // When
        let boxScore = try boxScoreDTO.toDomain()
        
        // Then
        XCTAssertNotNil(boxScore.quarters)
        XCTAssertEqual(boxScore.quarters?.count, 4)
        XCTAssertEqual(boxScore.quarters?.first?.quarterNumber, 1)
        XCTAssertEqual(boxScore.quarters?.last?.quarterNumber, 4)
    }
    
    func testToDomain_HandlesNilLastUpdated() throws {
        // Given
        let boxScoreDTO = BoxScoreDTOBuilder()
            .withHomeScore(100)
            .withAwayScore(95)
            .withLastUpdated(nil)
            .build()
        
        // When
        let boxScore = try boxScoreDTO.toDomain()
        
        // Then
        XCTAssertNil(boxScore.lastUpdated)
    }
    
    func testToDomain_HandlesOptionalStats() throws {
        // Given
        let boxScoreDTO = BoxScoreDTOBuilder()
            .withHomeScore(100)
            .withAwayScore(95)
            .withHomeStats { builder in
                builder
                    .withPoints(100)
                    .withRebounds(40)
                    .withAssists(25)
                    // All optional stats left as nil
            }
            .withAwayStats { builder in
                builder
                    .withPoints(95)
                    .withRebounds(35)
                    .withAssists(20)
                    // All optional stats left as nil
            }
            .build()
        
        // When
        let boxScore = try boxScoreDTO.toDomain()
        
        // Then
        XCTAssertNil(boxScore.homeStats.steals)
        XCTAssertNil(boxScore.homeStats.blocks)
        XCTAssertNil(boxScore.homeStats.turnovers)
        XCTAssertNil(boxScore.awayStats.steals)
        XCTAssertNil(boxScore.awayStats.blocks)
        XCTAssertNil(boxScore.awayStats.turnovers)
    }
    
    func testToDomain_HandlesDateFromDateObject() throws {
        // Given
        let testDate = Date()
        let boxScoreDTO = BoxScoreDTOBuilder()
            .withHomeScore(100)
            .withAwayScore(95)
            .withLastUpdated(testDate)
            .build()
        
        // When
        let boxScore = try boxScoreDTO.toDomain()
        
        // Then
        XCTAssertNotNil(boxScore.lastUpdated)
        if let lastUpdated = boxScore.lastUpdated {
            // Verify dates are approximately equal (within 1 second)
            XCTAssertTrue(abs(lastUpdated.timeIntervalSince(testDate)) < 1.0)
        }
    }
    
    func testToDomain_HandlesDefaultStats() throws {
        // Given - using builder without specifying stats
        let boxScoreDTO = BoxScoreDTOBuilder()
            .withHomeScore(100)
            .withAwayScore(95)
            .build()
        
        // When
        let boxScore = try boxScoreDTO.toDomain()
        
        // Then - should use default stats with points matching scores
        XCTAssertEqual(boxScore.homeStats.points, 100)
        XCTAssertEqual(boxScore.awayStats.points, 95)
    }
}
