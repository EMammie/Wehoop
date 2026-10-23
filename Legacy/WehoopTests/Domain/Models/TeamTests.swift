//
//  TeamTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class TeamTests: XCTestCase {
    func testTeam_Initialization() {
        // When
        let team = Team(
            id: "team1",
            name: "Test Team",
            abbreviation: "TT",
            logoURL: "https://example.com/logo.png",
            city: "Test City",
            conference: .eastern,
            division: "Atlantic",
            wins: 50,
            losses: 32,
            winPercentage: 0.610
        )
        
        // Then
        XCTAssertEqual(team.id, "team1")
        XCTAssertEqual(team.name, "Test Team")
        XCTAssertEqual(team.abbreviation, "TT")
        XCTAssertEqual(team.logoURL, "https://example.com/logo.png")
        XCTAssertEqual(team.city, "Test City")
        XCTAssertEqual(team.conference, .eastern)
        XCTAssertEqual(team.division, "Atlantic")
        XCTAssertEqual(team.wins, 50)
        XCTAssertEqual(team.losses, 32)
        XCTAssertEqual(team.winPercentage, 0.610)
    }
    
    func testTeam_WithNilLogoURL() {
        // When
        let team = TestDataFactory.makeTeam(id: "team1", name: "Test Team")
        
        // Then
        XCTAssertNil(team.logoURL)
    }
    
    func testTeam_ComputedProperties() {
        // Given
        let team = Team(
            id: "team1",
            name: "Lakers",
            abbreviation: "LAL",
            logoURL: nil,
            city: "Los Angeles",
            conference: .western,
            division: nil,
            wins: 50,
            losses: 32,
            winPercentage: 0.610
        )
        
        // Then
        XCTAssertEqual(team.fullName, "Los Angeles Lakers")
        XCTAssertEqual(team.record, "50-32")
        XCTAssertEqual(team.formattedWinPercentage, "0.610")
    }
    
    func testConference_EnumValues() {
        // Then
        XCTAssertEqual(Conference.eastern.rawValue, "Eastern")
        XCTAssertEqual(Conference.western.rawValue, "Western")
        XCTAssertEqual(Conference.eastern.abbreviation, "EAST")
        XCTAssertEqual(Conference.western.abbreviation, "WEST")
    }
}
