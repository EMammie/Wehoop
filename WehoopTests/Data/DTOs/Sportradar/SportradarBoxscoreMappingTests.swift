//
//  SportradarBoxscoreMappingTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class SportradarBoxscoreMappingTests: XCTestCase {
    
    // MARK: - Sportradar Boxscore JSON Example
    // This is the actual Sportradar API boxscore response structure
    let sportradarBoxscoreJSON = """
    {
      "id": "838316ea-ab7b-4581-a1dd-74229d1970d5",
      "status": "closed",
      "coverage": "full",
      "scheduled": "2025-01-18T00:00:00+00:00",
      "lead_changes": 7,
      "times_tied": 6,
      "clock": "3:26",
      "quarter": 4,
      "possession_arrow": "0780b080-347b-407b-b8d6-fa109ec23908",
      "track_on_court": true,
      "entry_mode": "LDE",
      "clock_decimal": "3:26",
      "home": {
        "name": "Mist",
        "alias": "MST",
        "id": "0780b080-347b-407b-b8d6-fa109ec23908",
        "points": 80,
        "remaining_timeouts": 0,
        "scoring": [
          {
            "type": "quarter",
            "number": 1,
            "sequence": 1,
            "points": 20
          },
          {
            "type": "quarter",
            "number": 2,
            "sequence": 2,
            "points": 26
          },
          {
            "type": "quarter",
            "number": 3,
            "sequence": 3,
            "points": 27
          },
          {
            "type": "elam",
            "number": 4,
            "sequence": 4,
            "points": 7
          }
        ],
        "leaders": {
          "points": [
            {
              "full_name": "Jewell Loyd",
              "jersey_number": "24",
              "id": "2387d221-be55-495a-b2b7-cddbce9addcc",
              "position": "G",
              "primary_position": "NA",
              "statistics": {
                "minutes": "17:05",
                "field_goals_made": 10,
                "field_goals_att": 21,
                "field_goals_pct": 47.6,
                "three_points_made": 4,
                "three_points_att": 9,
                "three_points_pct": 44.4,
                "rebounds": 6,
                "assists": 2,
                "turnovers": 3,
                "steals": 0,
                "blocks": 0,
                "personal_fouls": 2,
                "points": 29
              }
            }
          ],
          "rebounds": [
            {
              "full_name": "Breanna Stewart",
              "jersey_number": "30",
              "id": "a00515fd-bdd9-44d1-83a5-597a99316c54",
              "position": "F",
              "primary_position": "NA",
              "statistics": {
                "minutes": "13:06",
                "rebounds": 13,
                "assists": 3,
                "turnovers": 1,
                "steals": 1,
                "blocks": 0,
                "personal_fouls": 3,
                "points": 6
              }
            }
          ],
          "assists": [
            {
              "full_name": "DiJonai Carrington",
              "jersey_number": "21",
              "id": "47169cbe-5640-460b-a840-7f438a124330",
              "position": "G-F",
              "primary_position": "NA",
              "statistics": {
                "minutes": "9:34",
                "rebounds": 6,
                "assists": 3,
                "turnovers": 3,
                "steals": 2,
                "blocks": 2,
                "personal_fouls": 3,
                "points": 8
              }
            }
          ]
        }
      },
      "away": {
        "name": "Lunar Owls",
        "alias": "LNR",
        "id": "67c22115-2385-458f-8632-a67a025fef55",
        "points": 84,
        "remaining_timeouts": 1,
        "scoring": [
          {
            "type": "quarter",
            "number": 1,
            "sequence": 1,
            "points": 19
          },
          {
            "type": "quarter",
            "number": 2,
            "sequence": 2,
            "points": 25
          },
          {
            "type": "quarter",
            "number": 3,
            "sequence": 3,
            "points": 23
          },
          {
            "type": "elam",
            "number": 4,
            "sequence": 4,
            "points": 17
          }
        ],
        "leaders": {
          "points": [
            {
              "full_name": "Napheesa Collier",
              "jersey_number": "24",
              "id": "fd8d4b11-3d70-450a-b65c-016bec29cc9d",
              "position": "F",
              "primary_position": "NA",
              "statistics": {
                "minutes": "30:15",
                "field_goals_made": 11,
                "field_goals_att": 20,
                "field_goals_pct": 55,
                "three_points_made": 3,
                "three_points_att": 7,
                "three_points_pct": 42.9,
                "rebounds": 10,
                "assists": 3,
                "turnovers": 1,
                "steals": 1,
                "blocks": 0,
                "personal_fouls": 1,
                "points": 27
              }
            }
          ],
          "rebounds": [
            {
              "full_name": "Napheesa Collier",
              "jersey_number": "24",
              "id": "fd8d4b11-3d70-450a-b65c-016bec29cc9d",
              "position": "F",
              "primary_position": "NA",
              "statistics": {
                "minutes": "30:15",
                "rebounds": 10,
                "assists": 3,
                "turnovers": 1,
                "steals": 1,
                "blocks": 0,
                "personal_fouls": 1,
                "points": 27
              }
            }
          ],
          "assists": [
            {
              "full_name": "Courtney Williams",
              "jersey_number": "10",
              "id": "95b03dc9-26cf-47ca-abf6-8380850d1e4e",
              "position": "G",
              "primary_position": "NA",
              "statistics": {
                "minutes": "12:39",
                "rebounds": 7,
                "assists": 4,
                "turnovers": 0,
                "steals": 0,
                "blocks": 0,
                "personal_fouls": 3,
                "points": 14
              }
            }
          ]
        }
      }
    }
    """
    
    // MARK: - Decode and Map Tests
    
    func testDecodeSportradarBoxscore() throws {
        // Given
        let jsonData = sportradarBoxscoreJSON.data(using: .utf8)!
        
        // When
        let sportradarBoxscore = try JSONDecoder().decode(SportradarBoxscoreDTO.self, from: jsonData)
        
        // Then
        XCTAssertEqual(sportradarBoxscore.id, "838316ea-ab7b-4581-a1dd-74229d1970d5")
        XCTAssertEqual(sportradarBoxscore.status, "closed")
        XCTAssertEqual(sportradarBoxscore.home?.points, 80)
        XCTAssertEqual(sportradarBoxscore.away?.points, 84)
        XCTAssertEqual(sportradarBoxscore.home?.name, "Mist")
        XCTAssertEqual(sportradarBoxscore.away?.name, "Lunar Owls")
        XCTAssertEqual(sportradarBoxscore.home?.scoring?.count, 4)
        XCTAssertEqual(sportradarBoxscore.away?.scoring?.count, 4)
        XCTAssertNotNil(sportradarBoxscore.home?.leaders)
        XCTAssertNotNil(sportradarBoxscore.away?.leaders)
    }
    
    func testMapSportradarBoxscoreToBoxScoreDTO() throws {
        // Given
        let jsonData = sportradarBoxscoreJSON.data(using: .utf8)!
        let sportradarBoxscore = try JSONDecoder().decode(SportradarBoxscoreDTO.self, from: jsonData)
        
        // When
        let boxScoreDTO = try sportradarBoxscore.toBoxScoreDTO()
        
        // Then - Verify scores
        XCTAssertEqual(boxScoreDTO.homeScore, 80)
        XCTAssertEqual(boxScoreDTO.awayScore, 84)
        XCTAssertEqual(boxScoreDTO.homeStats.points, 80)
        XCTAssertEqual(boxScoreDTO.awayStats.points, 84)
        
        // Verify aggregated stats from leaders (approximate values)
        XCTAssertGreaterThan(boxScoreDTO.homeStats.rebounds, 0, "Should aggregate rebounds from leaders")
        XCTAssertGreaterThan(boxScoreDTO.awayStats.rebounds, 0, "Should aggregate rebounds from leaders")
        XCTAssertGreaterThan(boxScoreDTO.homeStats.assists, 0, "Should aggregate assists from leaders")
        XCTAssertGreaterThan(boxScoreDTO.awayStats.assists, 0, "Should aggregate assists from leaders")
        
        // Verify percentages from points leader
        XCTAssertNotNil(boxScoreDTO.homeStats.fieldGoalPercentage, "Should have FG% from points leader")
        XCTAssertNotNil(boxScoreDTO.awayStats.fieldGoalPercentage, "Should have FG% from points leader")
        
        // Verify lastUpdated uses scheduled time
        XCTAssertEqual(boxScoreDTO.lastUpdated, "2025-01-18T00:00:00+00:00")
    }
    
    func testMapQuarters() throws {
        // Given
        let jsonData = sportradarBoxscoreJSON.data(using: .utf8)!
        let sportradarBoxscore = try JSONDecoder().decode(SportradarBoxscoreDTO.self, from: jsonData)
        
        // When
        let boxScoreDTO = try sportradarBoxscore.toBoxScoreDTO()
        
        // Then
        XCTAssertNotNil(boxScoreDTO.quarters)
        XCTAssertEqual(boxScoreDTO.quarters?.count, 3, "Should map 3 quarters (excluding elam)")
        
        let quarters = boxScoreDTO.quarters!
        XCTAssertEqual(quarters[0].homeScore, 20)
        XCTAssertEqual(quarters[0].awayScore, 19)
        XCTAssertEqual(quarters[0].quarterNumber, 1)
        
        XCTAssertEqual(quarters[1].homeScore, 26)
        XCTAssertEqual(quarters[1].awayScore, 25)
        XCTAssertEqual(quarters[1].quarterNumber, 2)
        
        XCTAssertEqual(quarters[2].homeScore, 27)
        XCTAssertEqual(quarters[2].awayScore, 23)
        XCTAssertEqual(quarters[2].quarterNumber, 3)
    }
    
    func testMapLastUpdated() throws {
        // Given
        let jsonData = sportradarBoxscoreJSON.data(using: .utf8)!
        let sportradarBoxscore = try JSONDecoder().decode(SportradarBoxscoreDTO.self, from: jsonData)
        
        // When
        let boxScoreDTO = try sportradarBoxscore.toBoxScoreDTO()
        
        // Then - Should use scheduled time
        XCTAssertEqual(boxScoreDTO.lastUpdated, "2025-01-18T00:00:00+00:00")
    }
    
    func testMapToDomainModel() throws {
        // Given
        let jsonData = sportradarBoxscoreJSON.data(using: .utf8)!
        let sportradarBoxscore = try JSONDecoder().decode(SportradarBoxscoreDTO.self, from: jsonData)
        let boxScoreDTO = try sportradarBoxscore.toBoxScoreDTO()
        
        // When
        let boxScore = try boxScoreDTO.toDomain()
        
        // Then
        XCTAssertEqual(boxScore.homeScore, 80)
        XCTAssertEqual(boxScore.awayScore, 84)
        XCTAssertEqual(boxScore.homeStats.points, 80)
        XCTAssertEqual(boxScore.awayStats.points, 84)
        XCTAssertGreaterThan(boxScore.homeStats.rebounds, 0)
        XCTAssertGreaterThan(boxScore.awayStats.rebounds, 0)
        XCTAssertNotNil(boxScore.lastUpdated)
        XCTAssertEqual(boxScore.quarters?.count, 3)
    }
    
    func testMapperUtility() throws {
        // Given
        let jsonData = sportradarBoxscoreJSON.data(using: .utf8)!
        let sportradarBoxscore = try JSONDecoder().decode(SportradarBoxscoreDTO.self, from: jsonData)
        
        // When
        let boxScoreDTO = try SportradarDTOMapper.mapBoxscore(sportradarBoxscore)
        
        // Then
        XCTAssertEqual(boxScoreDTO.homeScore, 62)
        XCTAssertEqual(boxScoreDTO.awayScore, 58)
        XCTAssertEqual(boxScoreDTO.homeStats.points, 62)
        XCTAssertEqual(boxScoreDTO.awayStats.points, 58)
    }
    
    // MARK: - Edge Cases
    
    func testBoxscoreWithMissingStatistics() throws {
        // Given - Boxscore with only scores, no detailed stats
        let minimalJSON = """
        {
          "home": {
            "points": 100
          },
          "away": {
            "points": 95
          }
        }
        """
        let jsonData = minimalJSON.data(using: .utf8)!
        let sportradarBoxscore = try JSONDecoder().decode(SportradarBoxscoreDTO.self, from: jsonData)
        
        // When
        let boxScoreDTO = try sportradarBoxscore.toBoxScoreDTO()
        
        // Then
        XCTAssertEqual(boxScoreDTO.homeScore, 100)
        XCTAssertEqual(boxScoreDTO.awayScore, 95)
        XCTAssertEqual(boxScoreDTO.homeStats.points, 100)
        XCTAssertEqual(boxScoreDTO.awayStats.points, 95)
        XCTAssertEqual(boxScoreDTO.homeStats.rebounds, 0)
        XCTAssertEqual(boxScoreDTO.awayStats.rebounds, 0)
        XCTAssertNil(boxScoreDTO.quarters)
        XCTAssertNil(boxScoreDTO.lastUpdated)
    }
    
    func testBoxscoreWithMissingQuarters() throws {
        // Given - Boxscore without quarters
        let noQuartersJSON = """
        {
          "home": {
            "points": 62,
            "statistics": {
              "rebounds": 28,
              "assists": 14
            }
          },
          "away": {
            "points": 58,
            "statistics": {
              "rebounds": 26,
              "assists": 12
            }
          }
        }
        """
        let jsonData = noQuartersJSON.data(using: .utf8)!
        let sportradarBoxscore = try JSONDecoder().decode(SportradarBoxscoreDTO.self, from: jsonData)
        
        // When
        let boxScoreDTO = try sportradarBoxscore.toBoxScoreDTO()
        
        // Then
        XCTAssertEqual(boxScoreDTO.homeScore, 62)
        XCTAssertEqual(boxScoreDTO.awayScore, 58)
        XCTAssertNil(boxScoreDTO.quarters)
    }
    
    func testBoxscoreWithPartialStatistics() throws {
        // Given - Boxscore with some missing optional stats
        let partialStatsJSON = """
        {
          "home": {
            "points": 62,
            "statistics": {
              "rebounds": 28,
              "assists": 14,
              "steals": 6
            }
          },
          "away": {
            "points": 58,
            "statistics": {
              "rebounds": 26,
              "assists": 12
            }
          }
        }
        """
        let jsonData = partialStatsJSON.data(using: .utf8)!
        let sportradarBoxscore = try JSONDecoder().decode(SportradarBoxscoreDTO.self, from: jsonData)
        
        // When
        let boxScoreDTO = try sportradarBoxscore.toBoxScoreDTO()
        
        // Then
        XCTAssertEqual(boxScoreDTO.homeScore, 62)
        XCTAssertEqual(boxScoreDTO.awayScore, 58)
        XCTAssertEqual(boxScoreDTO.homeStats.rebounds, 28)
        XCTAssertEqual(boxScoreDTO.awayStats.rebounds, 26)
        XCTAssertEqual(boxScoreDTO.homeStats.steals, 6)
        XCTAssertNil(boxScoreDTO.awayStats.steals)
        XCTAssertNil(boxScoreDTO.homeStats.blocks)
        XCTAssertNil(boxScoreDTO.awayStats.blocks)
    }
}
