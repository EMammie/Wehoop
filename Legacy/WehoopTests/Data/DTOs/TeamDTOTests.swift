//
//  TeamDTOTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class TeamDTOTests: XCTestCase {
    
    func testToDomain_ConvertsTeamDTO_ToTeam() throws {
        // Given
        let teamDTO = TeamDTO(
            id: "team-1",
            name: "Lakers",
            abbreviation: "LAL",
            logoURL: "https://example.com/logo.png",
            city: "Los Angeles",
            conference: "Western",
            division: "Pacific",
            wins: 45,
            losses: 25,
            winPercentage: 0.643
        )
        
        // When
        let team = try teamDTO.toDomain()
        
        // Then
        XCTAssertEqual(team.id, "team-1")
        XCTAssertEqual(team.name, "Lakers")
        XCTAssertEqual(team.abbreviation, "LAL")
        XCTAssertEqual(team.logoURL, "https://example.com/logo.png")
        XCTAssertEqual(team.city, "Los Angeles")
        XCTAssertEqual(team.conference, .western)
        XCTAssertEqual(team.division, "Pacific")
        XCTAssertEqual(team.wins, 45)
        XCTAssertEqual(team.losses, 25)
        XCTAssertEqual(team.winPercentage, 0.643)
    }
    
    func testToDomain_HandlesEasternConference() throws {
        // Given
        let teamDTO = TeamDTO(
            id: "team-1",
            name: "Celtics",
            abbreviation: "BOS",
            logoURL: nil,
            city: "Boston",
            conference: "Eastern",
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        // When
        let team = try teamDTO.toDomain()
        
        // Then
        XCTAssertEqual(team.conference, .eastern)
    }
    
    func testToDomain_HandlesWesternConference() throws {
        // Given
        let teamDTO = TeamDTO(
            id: "team-1",
            name: "Lakers",
            abbreviation: "LAL",
            logoURL: nil,
            city: nil,
            conference: "Western",
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        // When
        let team = try teamDTO.toDomain()
        
        // Then
        XCTAssertEqual(team.conference, .western)
    }
    
    func testToDomain_HandlesNilConference() throws {
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
        
        // When
        let team = try teamDTO.toDomain()
        
        // Then
        XCTAssertNil(team.conference)
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
        
        // When
        let team = try teamDTO.toDomain()
        
        // Then
        XCTAssertNil(team.logoURL)
        XCTAssertNil(team.city)
        XCTAssertNil(team.conference)
        XCTAssertNil(team.division)
        XCTAssertNil(team.wins)
        XCTAssertNil(team.losses)
        XCTAssertNil(team.winPercentage)
    }
    
    func testToDomain_HandlesWinLossRecord() throws {
        // Given
        let teamDTO = TeamDTO(
            id: "team-1",
            name: "Team",
            abbreviation: "T",
            logoURL: nil,
            city: nil,
            conference: "Western",
            division: nil,
            wins: 50,
            losses: 20,
            winPercentage: 0.714
        )
        
        // When
        let team = try teamDTO.toDomain()
        
        // Then
        XCTAssertEqual(team.wins, 50)
        XCTAssertEqual(team.losses, 20)
        XCTAssertEqual(team.winPercentage, 0.714)
        XCTAssertEqual(team.record, "50-20")
    }
}
