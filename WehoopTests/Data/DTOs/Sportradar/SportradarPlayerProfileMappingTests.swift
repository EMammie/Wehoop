//
//  SportradarPlayerProfileMappingTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class SportradarPlayerProfileMappingTests: XCTestCase {
    // MARK: - Sportradar Player Profile JSON Example
    // This is the actual Sportradar API player profile response structure
    // Note: This is a simplified version focusing on key fields for testing
    let sportradarPlayerProfileJSON = """
    {
      "id": "fd8d4b11-3d70-450a-b65c-016bec29cc9d",
      "status": "ACT",
      "full_name": "Napheesa Collier",
      "first_name": "Napheesa",
      "last_name": "Collier",
      "abbr_name": "N.Collier",
      "height": 73,
      "weight": 180,
      "position": "F",
      "primary_position": "NA",
      "jersey_number": "24",
      "college": "UConn",
      "high_school": "Incarnate Word Academy (MO)",
      "birth_place": "Jefferson City, MO, USA",
      "birthdate": "1996-09-23",
      "updated": "2025-11-13T22:12:21+00:00",
      "league": {
        "id": "844ee10a-00c8-4dc1-9c17-52598de2ef47",
        "name": "Unrivaled",
        "alias": "UNRIVALED"
      },
      "team": {
        "id": "67c22115-2385-458f-8632-a67a025fef55",
        "name": "Lunar Owls",
        "alias": "LNR"
      },
      "references": [
        {
          "source_id": "8e281d64-a268-445f-9569-bc812d2730d5",
          "scope": "basketball",
          "id_type": "sport_profile"
        }
      ],
      "seasons": [
        {
          "id": "c86ab7c9-5408-44e6-af06-c22636262927",
          "year": 2025,
          "type": "REG",
          "teams": [
            {
              "id": "67c22115-2385-458f-8632-a67a025fef55",
              "name": "Lunar Owls",
              "alias": "LNR",
              "total": {
                "games_played": 14,
                "games_started": 14,
                "minutes": 297,
                "field_goals_made": 146,
                "field_goals_att": 239,
                "field_goals_pct": 0.611,
                "two_points_made": 129,
                "two_points_att": 185,
                "two_points_pct": 0.697,
                "three_points_made": 17,
                "three_points_att": 54,
                "three_points_pct": 0.315,
                "blocked_att": 2,
                "free_throws_made": 32,
                "free_throws_att": 40,
                "free_throws_pct": 0.8,
                "offensive_rebounds": 23,
                "defensive_rebounds": 127,
                "rebounds": 150,
                "assists": 39,
                "turnovers": 22,
                "assists_turnover_ratio": 1.77,
                "steals": 28,
                "blocks": 20,
                "personal_fouls": 48,
                "tech_fouls": 0,
                "points": 360,
                "flagrant_fouls": 0,
                "ejections": 0,
                "foulouts": 1,
                "tech_fouls_non_unsportsmanlike": 0,
                "true_shooting_att": 256.6,
                "true_shooting_pct": 0.701,
                "efficiency": 474,
                "field_goals_at_rim_made": 43,
                "field_goals_at_rim_att": 49,
                "field_goals_at_rim_pct": 0.878,
                "field_goals_at_midrange_made": 14,
                "field_goals_at_midrange_att": 28,
                "field_goals_at_midrange_pct": 0.5,
                "usage_pct": 19.61,
                "awarded_points": 0,
                "coach_ejections": 0,
                "coach_tech_fouls": 0,
                "double_doubles": 8,
                "effective_fg_pct": 0.646,
                "fast_break_att": 0,
                "fast_break_made": 0,
                "fast_break_pct": 0,
                "fast_break_pts": 0,
                "fouls_drawn": 44,
                "free_throw_points": 51,
                "minus": 0,
                "offensive_fouls": 10,
                "plus": 0,
                "points_in_paint": 222,
                "points_in_paint_att": 151,
                "points_in_paint_made": 111,
                "points_in_paint_pct": 0.735,
                "points_off_turnovers": 54,
                "second_chance_att": 0,
                "second_chance_made": 0,
                "second_chance_pct": 0,
                "second_chance_pts": 37,
                "triple_doubles": 0,
                "winning_baskets": 2
              },
              "average": {
                "minutes": 21.2,
                "points": 25.7,
                "off_rebounds": 1.64,
                "def_rebounds": 9.07,
                "rebounds": 10.71,
                "assists": 2.8,
                "steals": 2,
                "blocks": 1.43,
                "turnovers": 1.57,
                "personal_fouls": 3.43,
                "flagrant_fouls": 0,
                "blocked_att": 0.14,
                "field_goals_made": 10.43,
                "field_goals_att": 17.07,
                "three_points_made": 1.21,
                "three_points_att": 3.86,
                "free_throws_made": 2.29,
                "free_throws_att": 2.86,
                "two_points_made": 9.21,
                "two_points_att": 13.21,
                "efficiency": 33.86,
                "true_shooting_att": 18.33,
                "fast_break_att": 0,
                "fast_break_made": 0,
                "fast_break_pts": 0,
                "fouls_drawn": 3.14,
                "offensive_fouls": 0.71,
                "points_in_paint": 15.86,
                "points_in_paint_att": 10.79,
                "points_in_paint_made": 7.93,
                "points_off_turnovers": 3.86,
                "second_chance_att": 0,
                "second_chance_made": 0,
                "second_chance_pts": 2.64
              }
            }
          ]
        }
      ]
    }
    """
    
    // MARK: - Decoding Tests
    
    func testDecodeSportradarPlayerProfile() throws {
        // Given
        let jsonData = sportradarPlayerProfileJSON.data(using: .utf8)!
        
        // When
        let playerProfile = try JSONDecoder().decode(SportradarPlayerProfileDTO.self, from: jsonData)
        
        // Then
        XCTAssertEqual(playerProfile.id, "fd8d4b11-3d70-450a-b65c-016bec29cc9d")
        XCTAssertEqual(playerProfile.status, "ACT")
        XCTAssertEqual(playerProfile.fullName, "Napheesa Collier")
        XCTAssertEqual(playerProfile.firstName, "Napheesa")
        XCTAssertEqual(playerProfile.lastName, "Collier")
        XCTAssertEqual(playerProfile.abbrName, "N.Collier")
        XCTAssertEqual(playerProfile.height, 73)
        XCTAssertEqual(playerProfile.weight, 180)
        XCTAssertEqual(playerProfile.position, "F")
        XCTAssertEqual(playerProfile.primaryPosition, "NA")
        XCTAssertEqual(playerProfile.jerseyNumber, "24")
        XCTAssertEqual(playerProfile.college, "UConn")
        XCTAssertEqual(playerProfile.highSchool, "Incarnate Word Academy (MO)")
        XCTAssertEqual(playerProfile.birthPlace, "Jefferson City, MO, USA")
        XCTAssertEqual(playerProfile.birthdate, "1996-09-23")
        XCTAssertNotNil(playerProfile.league)
        XCTAssertNotNil(playerProfile.team)
        XCTAssertNotNil(playerProfile.seasons)
    }
    
    func testDecodeTeamReference() throws {
        // Given
        let jsonData = sportradarPlayerProfileJSON.data(using: .utf8)!
        let playerProfile = try JSONDecoder().decode(SportradarPlayerProfileDTO.self, from: jsonData)
        
        // When
        let team = playerProfile.team
        
        // Then
        XCTAssertNotNil(team)
        XCTAssertEqual(team?.id, "67c22115-2385-458f-8632-a67a025fef55")
        XCTAssertEqual(team?.name, "Lunar Owls")
        XCTAssertEqual(team?.alias, "LNR")
    }
    
    func testDecodeSeasons() throws {
        // Given
        let jsonData = sportradarPlayerProfileJSON.data(using: .utf8)!
        let playerProfile = try JSONDecoder().decode(SportradarPlayerProfileDTO.self, from: jsonData)
        
        // When
        let seasons = playerProfile.seasons
        
        // Then
        XCTAssertNotNil(seasons)
        XCTAssertEqual(seasons?.count, 1)
        
        if let season = seasons?.first {
            XCTAssertEqual(season.year, 2025)
            XCTAssertEqual(season.type, "REG")
            XCTAssertNotNil(season.teams)
            XCTAssertEqual(season.teams?.count, 1)
        }
    }
    
    func testDecodeSeasonStatistics() throws {
        // Given
        let jsonData = sportradarPlayerProfileJSON.data(using: .utf8)!
        let playerProfile = try JSONDecoder().decode(SportradarPlayerProfileDTO.self, from: jsonData)
        
        // When
        let season = playerProfile.seasons?.first
        let team = season?.teams?.first
        let total = team?.total
        let average = team?.average
        
        // Then
        XCTAssertNotNil(total)
        XCTAssertNotNil(average)
        XCTAssertEqual(total?.gamesPlayed, 14)
        XCTAssertEqual(total?.points, 360)
        XCTAssertEqual(total?.rebounds, 150)
        XCTAssertEqual(total?.assists, 39)
        XCTAssertEqual(total?.steals, 28)
        XCTAssertEqual(total?.blocks, 20)

      if let total = total { // TODO: - Clean up Model objects optionality
        XCTAssertEqual(total.fieldGoalsPct, 0.611, accuracy: 0.001)
        XCTAssertEqual(total.threePointsPct, 0.315, accuracy: 0.001)
      }
        // Verify averages
      if let average = average {
        XCTAssertEqual(average.points, 25.7, accuracy: 0.1)
        XCTAssertEqual(average.rebounds, 10.71, accuracy: 0.1)
        XCTAssertEqual(average.assists, 2.8, accuracy: 0.1)
        XCTAssertEqual(average.steals, 2, accuracy: 0.1)
        XCTAssertEqual(average.blocks, 1.43, accuracy: 0.1)
      }
    }
    
    // MARK: - Mapping Tests
    
    func testMapPlayerProfileToPlayerDTO() throws {
        // Given
        let jsonData = sportradarPlayerProfileJSON.data(using: .utf8)!
        let playerProfile = try JSONDecoder().decode(SportradarPlayerProfileDTO.self, from: jsonData)
        
        let teamDTO = TeamDTO(
            id: "67c22115-2385-458f-8632-a67a025fef55",
            name: "Lunar Owls",
            abbreviation: "LNR",
            logoURL: nil,
            city: nil,
            conference: nil,
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        // When
        let playerDTO = playerProfile.toPlayerDTO(teamDTO: teamDTO)
        
        // Then
        XCTAssertEqual(playerDTO.id, "fd8d4b11-3d70-450a-b65c-016bec29cc9d")
        XCTAssertEqual(playerDTO.name, "Napheesa Collier")
        XCTAssertEqual(playerDTO.position, "F")
        XCTAssertEqual(playerDTO.jerseyNumber, 24)
        XCTAssertEqual(playerDTO.height, "6'1\"") // 73 inches = 6'1"
        XCTAssertEqual(playerDTO.weight, 180)
        XCTAssertEqual(playerDTO.college, "UConn")
        XCTAssertEqual(playerDTO.team.id, "67c22115-2385-458f-8632-a67a025fef55")
        
        // Verify statistics are mapped
        XCTAssertGreaterThan(playerDTO.statistics.count, 0, "Should have statistics from season")
    }
    
    func testMapPlayerProfileWithoutTeamDTO() throws {
        // Given
        let jsonData = sportradarPlayerProfileJSON.data(using: .utf8)!
        let playerProfile = try JSONDecoder().decode(SportradarPlayerProfileDTO.self, from: jsonData)
        
        // When - No teamDTO provided, should use team reference from profile
        let playerDTO = playerProfile.toPlayerDTO()
        
        // Then
        XCTAssertEqual(playerDTO.id, "fd8d4b11-3d70-450a-b65c-016bec29cc9d")
        XCTAssertEqual(playerDTO.name, "Napheesa Collier")
        XCTAssertEqual(playerDTO.team.id, "67c22115-2385-458f-8632-a67a025fef55")
        XCTAssertEqual(playerDTO.team.name, "Lunar Owls")
        XCTAssertEqual(playerDTO.team.abbreviation, "LNR")
    }
    
    func testMapStatisticsFromSeasons() throws {
        // Given
        let jsonData = sportradarPlayerProfileJSON.data(using: .utf8)!
        let playerProfile = try JSONDecoder().decode(SportradarPlayerProfileDTO.self, from: jsonData)
        
        // When
        let playerDTO = playerProfile.toPlayerDTO()
        
        // Then - Should have statistics from most recent regular season
        XCTAssertGreaterThan(playerDTO.statistics.count, 0)
        
        // Verify key statistics are present
        let pointsStat = playerDTO.statistics.first { $0.name == "Points Per Game" }
        let reboundsStat = playerDTO.statistics.first { $0.name == "Rebounds Per Game" }
        let assistsStat = playerDTO.statistics.first { $0.name == "Assists Per Game" }
        
        XCTAssertNotNil(pointsStat, "Should have points per game")
        XCTAssertNotNil(reboundsStat, "Should have rebounds per game")
        XCTAssertNotNil(assistsStat, "Should have assists per game")
        
        // Verify values match averages from season
        // TO - DO : 
        guard let pointsStat = pointsStat, let reboundsStat = reboundsStat, let assistsStat = assistsStat else {  return }
        XCTAssertEqual(pointsStat.value, 25.7, accuracy: 0.1)
        XCTAssertEqual(reboundsStat.value, 10.71, accuracy: 0.1)
        XCTAssertEqual(assistsStat.value, 2.8, accuracy: 0.1)
        
        // Verify season info
        XCTAssertEqual(pointsStat.season, "2025 REG")
        XCTAssertEqual(pointsStat.gamesPlayed, 14)
    }
    
    func testMapHeightConversion() throws {
        // Given
        let jsonData = sportradarPlayerProfileJSON.data(using: .utf8)!
        let playerProfile = try JSONDecoder().decode(SportradarPlayerProfileDTO.self, from: jsonData)
        
        // When
        let playerDTO = playerProfile.toPlayerDTO()
        
        // Then - 73 inches should convert to 6'1"
        XCTAssertEqual(playerDTO.height, "6'1\"")
    }
    
    func testCalculateAge() throws {
        // Given
        let jsonData = sportradarPlayerProfileJSON.data(using: .utf8)!
        let playerProfile = try JSONDecoder().decode(SportradarPlayerProfileDTO.self, from: jsonData)
        
        // When
        let playerDTO = playerProfile.toPlayerDTO()
        
        // Then - Birthdate is 1996-09-23, should calculate age correctly
        // Note: Age calculation depends on current date, so we just verify it's not nil
        XCTAssertNotNil(playerDTO.age, "Should calculate age from birthdate")
        if let age = playerDTO.age {
            // Should be around 28-29 years old in 2025
            XCTAssertGreaterThanOrEqual(age, 28)
            XCTAssertLessThanOrEqual(age, 29)
        }
    }
    
    func testMapperUtility() throws {
        // Given
        let jsonData = sportradarPlayerProfileJSON.data(using: .utf8)!
        let playerProfile = try JSONDecoder().decode(SportradarPlayerProfileDTO.self, from: jsonData)
        
        let teamDTO = TeamDTO(
            id: "67c22115-2385-458f-8632-a67a025fef55",
            name: "Lunar Owls",
            abbreviation: "LNR",
            logoURL: nil,
            city: nil,
            conference: nil,
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        // When
        let playerDTO = SportradarDTOMapper.mapPlayerProfile(playerProfile, teamDTO: teamDTO)
        
        // Then
        XCTAssertEqual(playerDTO.id, "fd8d4b11-3d70-450a-b65c-016bec29cc9d")
        XCTAssertEqual(playerDTO.name, "Napheesa Collier")
        XCTAssertEqual(playerDTO.team.id, "67c22115-2385-458f-8632-a67a025fef55")
    }
    
    func testMapToDomainModel() throws {
        // Given
        let jsonData = sportradarPlayerProfileJSON.data(using: .utf8)!
        let playerProfile = try JSONDecoder().decode(SportradarPlayerProfileDTO.self, from: jsonData)
        
        let teamDTO = TeamDTO(
            id: "67c22115-2385-458f-8632-a67a025fef55",
            name: "Lunar Owls",
            abbreviation: "LNR",
            logoURL: nil,
            city: nil,
            conference: nil,
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        let playerDTO = playerProfile.toPlayerDTO(teamDTO: teamDTO)
        
        // When
        let player = try playerDTO.toDomain()
        
        // Then
        XCTAssertEqual(player.id, "fd8d4b11-3d70-450a-b65c-016bec29cc9d")
        XCTAssertEqual(player.name, "Napheesa Collier")
        XCTAssertEqual(player.position, "F")
        XCTAssertEqual(player.jerseyNumber, 24)
        XCTAssertEqual(player.height, "6'1\"")
        XCTAssertEqual(player.weight, 180)
        XCTAssertEqual(player.college, "UConn")
        XCTAssertGreaterThan(player.statistics.count, 0)
    }
}
