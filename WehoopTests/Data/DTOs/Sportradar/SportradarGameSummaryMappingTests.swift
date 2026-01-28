//
//  SportradarGameSummaryMappingTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class SportradarGameSummaryMappingTests: XCTestCase {
    // MARK: - Sportradar Game Summary JSON Example
    // This is the actual Sportradar API game summary response structure
    // Full JSON example from the API - includes all players, periods, and detailed statistics
    let sportradarGameSummaryJSON = """
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
      "broadcasts": [
        {
          "type": "TV",
          "locale": "National",
          "network": "TNT",
          "channel": "245"
        }
      ],
      "time_zones": {
        "venue": "US/Eastern",
        "home": "US/Eastern",
        "away": "US/Eastern"
      },
      "season": {
        "id": "c86ab7c9-5408-44e6-af06-c22636262927",
        "year": 2025,
        "type": "REG",
        "name": "Regular Season"
      },
      "venue": {
        "id": "67e49419-cb04-4ce0-ab33-ae42af8d8634",
        "name": "Sephora Arena",
        "capacity": 850,
        "address": "7321 NW 75th Street",
        "city": "Medley",
        "state": "FL",
        "zip": "33166",
        "country": "USA",
        "location": {
          "lat": "25.842035",
          "lng": "-80.317192"
        }
      },
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
        "statistics": {
          "minutes": "1:13:18",
          "field_goals_made": 30,
          "field_goals_att": 68,
          "field_goals_pct": 44.1,
          "three_points_made": 6,
          "three_points_att": 21,
          "three_points_pct": 28.6,
          "two_points_made": 24,
          "two_points_att": 47,
          "two_points_pct": 51.1,
          "blocked_att": 2,
          "free_throws_made": 8,
          "free_throws_att": 10,
          "free_throws_pct": 80,
          "offensive_rebounds": 8,
          "defensive_rebounds": 30,
          "rebounds": 38,
          "assists": 13,
          "steals": 5,
          "blocks": 2,
          "assists_turnover_ratio": 1.18,
          "personal_fouls": 15,
          "ejections": 0,
          "foulouts": 0,
          "points": 80,
          "fast_break_pts": 0,
          "second_chance_pts": 6,
          "team_turnovers": 0,
          "points_off_turnovers": 11,
          "team_rebounds": 5,
          "flagrant_fouls": 0,
          "player_tech_fouls": 0,
          "team_tech_fouls": 0,
          "coach_tech_fouls": 0,
          "team_points": 0,
          "total_points": 80,
          "winning_basket": false,
          "free_throw_points": 14,
          "points_in_paint": 19,
          "team_offensive_rebounds": 2,
          "team_defensive_rebounds": 3,
          "total_rebounds": 43,
          "total_turnovers": 11,
          "personal_rebounds": 38,
          "player_turnovers": 11,
          "field_goals_at_rim_made": 2,
          "field_goals_at_rim_att": 2,
          "field_goals_at_rim_pct": 100,
          "field_goals_at_midrange_made": 2,
          "field_goals_at_midrange_att": 10,
          "field_goals_at_midrange_pct": 20,
          "bench_points": 34,
          "biggest_lead": 10,
          "effective_fg_pct": 48.5,
          "efficiency": 81,
          "efficiency_game_score": 56.7,
          "fouls_drawn": 11,
          "offensive_fouls": 1,
          "pls_min": -4,
          "points_in_paint_att": 16,
          "points_in_paint_made": 9,
          "points_in_paint_pct": 56.3,
          "total_fouls": 15,
          "true_shooting_att": 72.4,
          "true_shooting_pct": 55.2,
          "most_unanswered": {
            "points": 9,
            "own_score": 11,
            "opp_score": 6
          }
        },
        "coaches": [
          {
            "id": "8ded6ff7-ca32-4b9a-a5e9-d08ecf32ca5e",
            "full_name": "Phil Handy",
            "first_name": "Phil",
            "last_name": "Handy",
            "position": "Head Coach"
          }
        ],
        "players": [
          {
            "full_name": "Aaliyah Edwards",
            "jersey_number": "3",
            "id": "dee02847-c8ac-4a83-83e3-6eb7ddcb696e",
            "first_name": "Aaliyah",
            "last_name": "Edwards",
            "position": "F",
            "primary_position": "NA",
            "played": true,
            "active": true,
            "on_court": false,
            "statistics": {
              "minutes": "9:03",
              "field_goals_made": 5,
              "field_goals_att": 7,
              "field_goals_pct": 71.4,
              "three_points_made": 0,
              "three_points_att": 0,
              "three_points_pct": 0,
              "two_points_made": 5,
              "two_points_att": 7,
              "two_points_pct": 71.4,
              "blocked_att": 1,
              "free_throws_made": 0,
              "free_throws_att": 0,
              "free_throws_pct": 0,
              "offensive_rebounds": 3,
              "defensive_rebounds": 6,
              "rebounds": 9,
              "assists": 2,
              "turnovers": 1,
              "steals": 0,
              "blocks": 0,
              "assists_turnover_ratio": 2,
              "personal_fouls": 2,
              "tech_fouls": 0,
              "flagrant_fouls": 0,
              "pls_min": 11,
              "points": 10,
              "free_throw_points": 0,
              "tech_fouls_non_unsportsmanlike": 0,
              "winning_basket": false,
              "double_double": false,
              "triple_double": false,
              "effective_fg_pct": 71.4,
              "efficiency": 15,
              "efficiency_game_score": 10.6,
              "fouls_drawn": 0,
              "offensive_fouls": 0,
              "points_in_paint": 0,
              "points_in_paint_att": 0,
              "points_in_paint_made": 0,
              "points_in_paint_pct": 0,
              "points_off_turnovers": 0,
              "true_shooting_att": 7,
              "true_shooting_pct": 71.4,
              "coach_ejections": 0,
              "coach_tech_fouls": 0,
              "second_chance_pts": 2,
              "second_chance_pct": 0
            }
          }
        ]
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
        "statistics": {
          "minutes": "1:13:18",
          "field_goals_made": 32,
          "field_goals_att": 65,
          "field_goals_pct": 49.2,
          "three_points_made": 8,
          "three_points_att": 20,
          "three_points_pct": 40,
          "two_points_made": 24,
          "two_points_att": 45,
          "two_points_pct": 53.3,
          "blocked_att": 1,
          "free_throws_made": 6,
          "free_throws_att": 8,
          "free_throws_pct": 75,
          "offensive_rebounds": 7,
          "defensive_rebounds": 28,
          "rebounds": 35,
          "assists": 18,
          "steals": 6,
          "blocks": 1,
          "assists_turnover_ratio": 2.25,
          "personal_fouls": 13,
          "ejections": 0,
          "foulouts": 0,
          "points": 84,
          "fast_break_pts": 0,
          "second_chance_pts": 8,
          "team_turnovers": 0,
          "points_off_turnovers": 12,
          "team_rebounds": 3,
          "flagrant_fouls": 0,
          "player_tech_fouls": 0,
          "team_tech_fouls": 0,
          "coach_tech_fouls": 0,
          "team_points": 0,
          "total_points": 84,
          "winning_basket": true,
          "free_throw_points": 11,
          "points_in_paint": 24,
          "team_offensive_rebounds": 1,
          "team_defensive_rebounds": 2,
          "total_rebounds": 38,
          "total_turnovers": 8,
          "personal_rebounds": 35,
          "player_turnovers": 8,
          "field_goals_at_rim_made": 4,
          "field_goals_at_rim_att": 4,
          "field_goals_at_rim_pct": 100,
          "field_goals_at_midrange_made": 3,
          "field_goals_at_midrange_att": 8,
          "field_goals_at_midrange_pct": 37.5,
          "bench_points": 28,
          "biggest_lead": 12,
          "effective_fg_pct": 55.4,
          "efficiency": 95,
          "efficiency_game_score": 66.3,
          "fouls_drawn": 15,
          "offensive_fouls": 0,
          "pls_min": 4,
          "points_in_paint_att": 18,
          "points_in_paint_made": 12,
          "points_in_paint_pct": 66.7,
          "total_fouls": 13,
          "true_shooting_att": 68.2,
          "true_shooting_pct": 61.6,
          "most_unanswered": {
            "points": 8,
            "own_score": 25,
            "opp_score": 17
          }
        },
        "coaches": [],
        "players": []
      },
      "officials": []
    }
    """
    
    // MARK: - Decoding Tests
    
    func testDecodeSportradarGameSummary() throws {
        // Given
        let jsonData = sportradarGameSummaryJSON.data(using: .utf8)!
        
        // When
        let gameSummary = try JSONDecoder().decode(SportradarGameSummaryDTO.self, from: jsonData)
        
        // Then
        XCTAssertEqual(gameSummary.id, "838316ea-ab7b-4581-a1dd-74229d1970d5")
        XCTAssertEqual(gameSummary.status, "closed")
        XCTAssertEqual(gameSummary.coverage, "full")
        XCTAssertEqual(gameSummary.scheduled, "2025-01-18T00:00:00+00:00")
        XCTAssertEqual(gameSummary.leadChanges, 7)
        XCTAssertEqual(gameSummary.timesTied, 6)
        XCTAssertEqual(gameSummary.quarter, 4)
        XCTAssertNotNil(gameSummary.home)
        XCTAssertNotNil(gameSummary.away)
        XCTAssertNotNil(gameSummary.venue)
        XCTAssertNotNil(gameSummary.season)
    }
    
    func testDecodeTeamStatistics() throws {
        // Given
        let jsonData = sportradarGameSummaryJSON.data(using: .utf8)!
        let gameSummary = try JSONDecoder().decode(SportradarGameSummaryDTO.self, from: jsonData)
        
        // When
        let homeStats = gameSummary.home?.statistics
        let awayStats = gameSummary.away?.statistics
        
        // Then
        XCTAssertNotNil(homeStats)
        XCTAssertNotNil(awayStats)
        XCTAssertEqual(homeStats?.points, 80)
        XCTAssertEqual(awayStats?.points, 84)
        XCTAssertEqual(homeStats?.rebounds, 38)
        XCTAssertEqual(awayStats?.rebounds, 33)
        XCTAssertEqual(homeStats?.assists, 13)
        XCTAssertEqual(awayStats?.assists, 18)
        XCTAssertEqual(homeStats?.steals, 5)
        XCTAssertEqual(awayStats?.steals, 6)
        XCTAssertEqual(homeStats?.blocks, 2)
        XCTAssertEqual(awayStats?.blocks, 1)
        XCTAssertEqual(homeStats?.fieldGoalsPct ?? 0, 44.1, accuracy: 0.1)
        XCTAssertEqual(awayStats?.fieldGoalsPct ?? 0, 50.8, accuracy: 0.1)
    }
    
    func testDecodeScoringPeriods() throws {
        // Given
        let jsonData = sportradarGameSummaryJSON.data(using: .utf8)!
        let gameSummary = try JSONDecoder().decode(SportradarGameSummaryDTO.self, from: jsonData)
        
        // When
        let homeScoring = gameSummary.home?.scoring
        let awayScoring = gameSummary.away?.scoring
        
        // Then
        XCTAssertNotNil(homeScoring)
        XCTAssertNotNil(awayScoring)
        XCTAssertEqual(homeScoring?.count, 4)
        XCTAssertEqual(awayScoring?.count, 4)
        
        // Verify quarter scores
        let homeQuarters = homeScoring?.filter { $0.type == "quarter" }
        let awayQuarters = awayScoring?.filter { $0.type == "quarter" }
        XCTAssertEqual(homeQuarters?.count, 3)
        XCTAssertEqual(awayQuarters?.count, 3)
        
        XCTAssertEqual(homeQuarters?[0].points, 20)
        XCTAssertEqual(homeQuarters?[1].points, 26)
        XCTAssertEqual(homeQuarters?[2].points, 27)
        XCTAssertEqual(awayQuarters?[0].points, 19)
        XCTAssertEqual(awayQuarters?[1].points, 25)
        XCTAssertEqual(awayQuarters?[2].points, 23)
    }
    
    func testDecodePlayers() throws {
        // Given
        let jsonData = sportradarGameSummaryJSON.data(using: .utf8)!
        let gameSummary = try JSONDecoder().decode(SportradarGameSummaryDTO.self, from: jsonData)
        
        // When
        let homePlayers = gameSummary.home?.players
        let awayPlayers = gameSummary.away?.players
        
        // Then
        XCTAssertNotNil(homePlayers)
        XCTAssertNotNil(awayPlayers)
        XCTAssertGreaterThanOrEqual(homePlayers?.count ?? 0, 1, "Home team should have at least one player")
        XCTAssertGreaterThanOrEqual(awayPlayers?.count ?? 0, 1, "Away team should have at least one player")
        
        if let player = homePlayers?.first {
            XCTAssertEqual(player.fullName, "Aaliyah Edwards")
            XCTAssertEqual(player.jerseyNumber, "3")
            XCTAssertEqual(player.id, "dee02847-c8ac-4a83-83e3-6eb7ddcb696e")
            XCTAssertEqual(player.position, "F")
            XCTAssertEqual(player.statistics?.points, 10)
            XCTAssertEqual(player.statistics?.rebounds, 9)
            XCTAssertEqual(player.statistics?.assists, 2)
        }
    }
    
    // MARK: - Mapping Tests
    
    func testMapGameSummaryToBoxScoreDTO() throws {
        // Given
        let jsonData = sportradarGameSummaryJSON.data(using: .utf8)!
        let gameSummary = try JSONDecoder().decode(SportradarGameSummaryDTO.self, from: jsonData)
        
        // When
        let boxScoreDTO = try gameSummary.toBoxScoreDTO()
        
        // Then - Verify scores
        XCTAssertEqual(boxScoreDTO.homeScore, 80)
        XCTAssertEqual(boxScoreDTO.awayScore, 84)
        XCTAssertEqual(boxScoreDTO.homeStats.points, 80)
        XCTAssertEqual(boxScoreDTO.awayStats.points, 84)
        
        // Verify team statistics from game summary (much more accurate than aggregating)
        XCTAssertEqual(boxScoreDTO.homeStats.rebounds, 38)
        XCTAssertEqual(boxScoreDTO.awayStats.rebounds, 33)
        XCTAssertEqual(boxScoreDTO.homeStats.assists, 13)
        XCTAssertEqual(boxScoreDTO.awayStats.assists, 18)
        XCTAssertEqual(boxScoreDTO.homeStats.steals, 5)
        XCTAssertEqual(boxScoreDTO.awayStats.steals, 6)
        XCTAssertEqual(boxScoreDTO.homeStats.blocks, 2)
        XCTAssertEqual(boxScoreDTO.awayStats.blocks, 1)
        
        // Verify percentages
        XCTAssertNotNil(boxScoreDTO.homeStats.fieldGoalPercentage)
        XCTAssertNotNil(boxScoreDTO.awayStats.fieldGoalPercentage)
        XCTAssertEqual(boxScoreDTO.homeStats.fieldGoalPercentage ?? 0, 44.1, accuracy: 0.1)
        XCTAssertEqual(boxScoreDTO.awayStats.fieldGoalPercentage ?? 0, 50.8, accuracy: 0.1)
        
        // Verify lastUpdated uses scheduled time
        XCTAssertEqual(boxScoreDTO.lastUpdated, "2025-01-18T00:00:00+00:00")
    }
    
    func testMapQuartersFromGameSummary() throws {
        // Given
        let jsonData = sportradarGameSummaryJSON.data(using: .utf8)!
        let gameSummary = try JSONDecoder().decode(SportradarGameSummaryDTO.self, from: jsonData)
        
        // When
        let boxScoreDTO = try gameSummary.toBoxScoreDTO()
        
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
    
    func testMapGameSummaryToGameDTO() throws {
        // Given
        let jsonData = sportradarGameSummaryJSON.data(using: .utf8)!
        let gameSummary = try JSONDecoder().decode(SportradarGameSummaryDTO.self, from: jsonData)
        
        let homeTeamDTO = TeamDTO(
            id: "0780b080-347b-407b-b8d6-fa109ec23908",
            name: "Mist",
            abbreviation: "MST",
            logoURL: nil,
            city: nil,
            conference: nil,
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        let awayTeamDTO = TeamDTO(
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
        let gameDTO = try gameSummary.toGameDTO(
            homeTeamDTO: homeTeamDTO,
            awayTeamDTO: awayTeamDTO
        )
        
        // Then
        XCTAssertEqual(gameDTO.id, "838316ea-ab7b-4581-a1dd-74229d1970d5")
        XCTAssertEqual(gameDTO.homeTeam.id, "0780b080-347b-407b-b8d6-fa109ec23908")
        XCTAssertEqual(gameDTO.awayTeam.id, "67c22115-2385-458f-8632-a67a025fef55")
        XCTAssertEqual(gameDTO.status, GameStatus.finished.rawValue)
        XCTAssertEqual(gameDTO.venue, "Sephora Arena")
        XCTAssertEqual(gameDTO.league, "Regular Season")
        XCTAssertNotNil(gameDTO.boxScore)
        XCTAssertEqual(gameDTO.boxScore?.homeScore, 80)
        XCTAssertEqual(gameDTO.boxScore?.awayScore, 84)
    }
    
    func testMapGameStatus() throws {
        // Given
        let jsonData = sportradarGameSummaryJSON.data(using: .utf8)!
        let gameSummary = try JSONDecoder().decode(SportradarGameSummaryDTO.self, from: jsonData)
        
        let homeTeamDTO = TeamDTO(
            id: "0780b080-347b-407b-b8d6-fa109ec23908",
            name: "Mist",
            abbreviation: "MST",
            logoURL: nil,
            city: nil,
            conference: nil,
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        let awayTeamDTO = TeamDTO(
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
        let gameDTO = try gameSummary.toGameDTO(
            homeTeamDTO: homeTeamDTO,
            awayTeamDTO: awayTeamDTO
        )
        
        // Then - "closed" should map to "finished"
        XCTAssertEqual(gameDTO.status, GameStatus.finished.rawValue)
    }
    
    func testMapperUtility() throws {
        // Given
        let jsonData = sportradarGameSummaryJSON.data(using: .utf8)!
        let gameSummary = try JSONDecoder().decode(SportradarGameSummaryDTO.self, from: jsonData)
        
        let teams: [String: TeamDTO] = [
            "0780b080-347b-407b-b8d6-fa109ec23908": TeamDTO(
                id: "0780b080-347b-407b-b8d6-fa109ec23908",
                name: "Mist",
                abbreviation: "MST",
                logoURL: nil,
                city: nil,
                conference: nil,
                division: nil,
                wins: nil,
                losses: nil,
                winPercentage: nil
            ),
            "67c22115-2385-458f-8632-a67a025fef55": TeamDTO(
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
        ]
        
        // When
        let gameDTO = try SportradarDTOMapper.mapGameSummary(gameSummary, teams: teams)
        
        // Then
        XCTAssertEqual(gameDTO.id, "838316ea-ab7b-4581-a1dd-74229d1970d5")
        XCTAssertEqual(gameDTO.homeTeam.id, "0780b080-347b-407b-b8d6-fa109ec23908")
        XCTAssertEqual(gameDTO.awayTeam.id, "67c22115-2385-458f-8632-a67a025fef55")
        XCTAssertEqual(gameDTO.boxScore?.homeScore, 80)
        XCTAssertEqual(gameDTO.boxScore?.awayScore, 84)
    }
    
    func testMapToDomainModel() throws {
        // Given
        let jsonData = sportradarGameSummaryJSON.data(using: .utf8)!
        let gameSummary = try JSONDecoder().decode(SportradarGameSummaryDTO.self, from: jsonData)
        
        let homeTeamDTO = TeamDTO(
            id: "0780b080-347b-407b-b8d6-fa109ec23908",
            name: "Mist",
            abbreviation: "MST",
            logoURL: nil,
            city: nil,
            conference: nil,
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        let awayTeamDTO = TeamDTO(
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
        
        let gameDTO = try gameSummary.toGameDTO(
            homeTeamDTO: homeTeamDTO,
            awayTeamDTO: awayTeamDTO
        )
        
        // When
        let game = try gameDTO.toDomain()
        
        // Then
        XCTAssertEqual(game.id, "838316ea-ab7b-4581-a1dd-74229d1970d5")
        XCTAssertEqual(game.homeTeam.id, "0780b080-347b-407b-b8d6-fa109ec23908")
        XCTAssertEqual(game.awayTeam.id, "67c22115-2385-458f-8632-a67a025fef55")
        XCTAssertEqual(game.status, .finished)
        XCTAssertNotNil(game.boxScore)
        XCTAssertEqual(game.boxScore?.homeScore, 80)
        XCTAssertEqual(game.boxScore?.awayScore, 84)
        XCTAssertEqual(game.boxScore?.quarters?.count, 3)
    }
    
    // MARK: - Full JSON Tests
    
    func testDecodeFullGameSummaryJSON() throws {
        // Given - Use the full JSON provided by the user
        let fullJSON = """
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
          "broadcasts": [
            {
              "type": "TV",
              "locale": "National",
              "network": "TNT",
              "channel": "245"
            }
          ],
          "time_zones": {
            "venue": "US/Eastern",
            "home": "US/Eastern",
            "away": "US/Eastern"
          },
          "season": {
            "id": "c86ab7c9-5408-44e6-af06-c22636262927",
            "year": 2025,
            "type": "REG",
            "name": "Regular Season"
          },
          "venue": {
            "id": "67e49419-cb04-4ce0-ab33-ae42af8d8634",
            "name": "Sephora Arena",
            "capacity": 850,
            "address": "7321 NW 75th Street",
            "city": "Medley",
            "state": "FL",
            "zip": "33166",
            "country": "USA",
            "location": {
              "lat": "25.842035",
              "lng": "-80.317192"
            }
          },
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
            "statistics": {
              "minutes": "1:13:18",
              "field_goals_made": 30,
              "field_goals_att": 68,
              "field_goals_pct": 44.1,
              "three_points_made": 6,
              "three_points_att": 21,
              "three_points_pct": 28.6,
              "two_points_made": 24,
              "two_points_att": 47,
              "two_points_pct": 51.1,
              "blocked_att": 2,
              "free_throws_made": 8,
              "free_throws_att": 10,
              "free_throws_pct": 80,
              "offensive_rebounds": 8,
              "defensive_rebounds": 30,
              "assists": 13,
              "steals": 5,
              "blocks": 2,
              "assists_turnover_ratio": 1.18,
              "personal_fouls": 15,
              "ejections": 0,
              "foulouts": 0,
              "points": 80,
              "fast_break_pts": 0,
              "second_chance_pts": 6,
              "team_turnovers": 0,
              "points_off_turnovers": 11,
              "team_rebounds": 5,
              "flagrant_fouls": 0,
              "player_tech_fouls": 0,
              "team_tech_fouls": 0,
              "coach_tech_fouls": 0,
              "team_points": 0,
              "total_points": 80,
              "winning_basket": false,
              "free_throw_points": 14,
              "points_in_paint": 19,
              "team_offensive_rebounds": 2,
              "team_defensive_rebounds": 3,
              "total_rebounds": 43,
              "total_turnovers": 11,
              "personal_rebounds": 38,
              "player_turnovers": 11,
              "field_goals_at_rim_made": 2,
              "field_goals_at_rim_att": 2,
              "field_goals_at_rim_pct": 100,
              "field_goals_at_midrange_made": 2,
              "field_goals_at_midrange_att": 10,
              "field_goals_at_midrange_pct": 20,
              "bench_points": 34,
              "biggest_lead": 10,
              "effective_fg_pct": 48.5,
              "efficiency": 81,
              "efficiency_game_score": 56.7,
              "fouls_drawn": 11,
              "offensive_fouls": 1,
              "pls_min": -4,
              "points_in_paint_att": 16,
              "points_in_paint_made": 9,
              "points_in_paint_pct": 56.3,
              "total_fouls": 15,
              "true_shooting_att": 72.4,
              "true_shooting_pct": 55.2,
              "most_unanswered": {
                "points": 9,
                "own_score": 11,
                "opp_score": 6
              },
              "periods": [
                {
                  "type": "REG",
                  "id": "c2a3e4bd-1eb2-4730-9460-0ea601ed6d6e",
                  "number": 1,
                  "sequence": 1,
                  "minutes": "21:00",
                  "field_goals_made": 9,
                  "field_goals_att": 22,
                  "field_goals_pct": 40.9,
                  "three_points_made": 2,
                  "three_points_att": 6,
                  "three_points_pct": 33.3,
                  "two_points_made": 7,
                  "two_points_att": 16,
                  "two_points_pct": 43.8,
                  "blocked_att": 0,
                  "free_throws_made": 0,
                  "free_throws_att": 0,
                  "free_throws_pct": 0,
                  "offensive_rebounds": 3,
                  "defensive_rebounds": 7,
                  "rebounds": 10,
                  "assists": 5,
                  "turnovers": 3,
                  "steals": 4,
                  "blocks": 1,
                  "assists_turnover_ratio": 1.67,
                  "personal_fouls": 4,
                  "offensive_fouls": 0,
                  "ejections": 0,
                  "points": 20,
                  "second_chance_pts": 2,
                  "team_turnovers": 0,
                  "points_off_turnovers": 5,
                  "team_rebounds": 2,
                  "flagrant_fouls": 0,
                  "player_tech_fouls": 0,
                  "team_tech_fouls": 0,
                  "coach_tech_fouls": 0,
                  "pls_min": 1,
                  "effective_fg_pct": 45.5,
                  "bench_points": 10,
                  "points_in_paint": 0,
                  "points_in_paint_att": 0,
                  "points_in_paint_made": 0,
                  "points_in_paint_pct": 0,
                  "true_shooting_att": 22,
                  "true_shooting_pct": 45.5,
                  "biggest_lead": 8,
                  "fouls_drawn": 0,
                  "total_turnovers": 3,
                  "efficiency": 20,
                  "efficiency_game_score": 16,
                  "winning_basket": false,
                  "free_throw_points": 0
                }
              ]
            },
            "coaches": [
              {
                "id": "8ded6ff7-ca32-4b9a-a5e9-d08ecf32ca5e",
                "full_name": "Phil Handy",
                "first_name": "Phil",
                "last_name": "Handy",
                "position": "Head Coach"
              }
            ],
            "players": [
              {
                "full_name": "Aaliyah Edwards",
                "jersey_number": "3",
                "id": "dee02847-c8ac-4a83-83e3-6eb7ddcb696e",
                "first_name": "Aaliyah",
                "last_name": "Edwards",
                "position": "F",
                "primary_position": "NA",
                "played": true,
                "active": true,
                "on_court": false,
                "statistics": {
                  "minutes": "9:03",
                  "field_goals_made": 5,
                  "field_goals_att": 7,
                  "field_goals_pct": 71.4,
                  "three_points_made": 0,
                  "three_points_att": 0,
                  "three_points_pct": 0,
                  "two_points_made": 5,
                  "two_points_att": 7,
                  "two_points_pct": 71.4,
                  "blocked_att": 1,
                  "free_throws_made": 0,
                  "free_throws_att": 0,
                  "free_throws_pct": 0,
                  "offensive_rebounds": 3,
                  "defensive_rebounds": 6,
                  "rebounds": 9,
                  "assists": 2,
                  "turnovers": 1,
                  "steals": 0,
                  "blocks": 0,
                  "assists_turnover_ratio": 2,
                  "personal_fouls": 2,
                  "tech_fouls": 0,
                  "flagrant_fouls": 0,
                  "pls_min": 11,
                  "points": 10,
                  "free_throw_points": 0,
                  "tech_fouls_non_unsportsmanlike": 0,
                  "winning_basket": false,
                  "double_double": false,
                  "triple_double": false,
                  "effective_fg_pct": 71.4,
                  "efficiency": 15,
                  "efficiency_game_score": 10.6,
                  "fouls_drawn": 0,
                  "offensive_fouls": 0,
                  "points_in_paint": 0,
                  "points_in_paint_att": 0,
                  "points_in_paint_made": 0,
                  "points_in_paint_pct": 0,
                  "points_off_turnovers": 0,
                  "true_shooting_att": 7,
                  "true_shooting_pct": 71.4,
                  "coach_ejections": 0,
                  "coach_tech_fouls": 0,
                  "second_chance_pts": 2,
                  "second_chance_pct": 0,
                  "periods": [
                    {
                      "type": "REG",
                      "id": "c2a3e4bd-1eb2-4730-9460-0ea601ed6d6e",
                      "number": 1,
                      "sequence": 1,
                      "minutes": "3:25",
                      "field_goals_made": 4,
                      "field_goals_att": 4,
                      "field_goals_pct": 100,
                      "three_points_made": 0,
                      "three_points_att": 0,
                      "three_points_pct": 0,
                      "two_points_made": 4,
                      "two_points_att": 4,
                      "two_points_pct": 100,
                      "blocked_att": 0,
                      "free_throws_made": 0,
                      "free_throws_att": 0,
                      "free_throws_pct": 0,
                      "offensive_rebounds": 2,
                      "defensive_rebounds": 1,
                      "rebounds": 3,
                      "assists": 1,
                      "turnovers": 0,
                      "steals": 0,
                      "blocks": 0,
                      "assists_turnover_ratio": 0,
                      "personal_fouls": 0,
                      "offensive_fouls": 0,
                      "tech_fouls": 0,
                      "flagrant_fouls": 0,
                      "pls_min": 3,
                      "points": 8,
                      "effective_fg_pct": 100,
                      "efficiency": 12,
                      "efficiency_game_score": 9.2,
                      "points_in_paint": 0,
                      "points_in_paint_att": 0,
                      "points_in_paint_made": 0,
                      "points_in_paint_pct": 0,
                      "true_shooting_att": 4,
                      "true_shooting_pct": 100,
                      "fouls_drawn": 0,
                      "points_off_turnovers": 0,
                      "second_chance_pts": 2,
                      "free_throw_points": 0,
                      "tech_fouls_non_unsportsmanlike": 0,
                      "winning_basket": false
                    }
                  ]
                }
              }
            ]
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
            "statistics": {
              "minutes": "1:13:18",
              "field_goals_made": 32,
              "field_goals_att": 63,
              "field_goals_pct": 50.8,
              "three_points_made": 7,
              "three_points_att": 20,
              "three_points_pct": 35,
              "two_points_made": 25,
              "two_points_att": 43,
              "two_points_pct": 58.1,
              "blocked_att": 2,
              "free_throws_made": 7,
              "free_throws_att": 12,
              "free_throws_pct": 58.3,
              "offensive_rebounds": 3,
              "defensive_rebounds": 28,
              "assists": 9,
              "steals": 6,
              "blocks": 2,
              "assists_turnover_ratio": 1.13,
              "personal_fouls": 14,
              "ejections": 0,
              "foulouts": 0,
              "points": 84,
              "fast_break_pts": 0,
              "second_chance_pts": 4,
              "team_turnovers": 0,
              "points_off_turnovers": 14,
              "team_rebounds": 2,
              "flagrant_fouls": 0,
              "player_tech_fouls": 0,
              "team_tech_fouls": 0,
              "coach_tech_fouls": 0,
              "team_points": 0,
              "total_points": 84,
              "winning_basket": true,
              "free_throw_points": 13,
              "points_in_paint": 16,
              "team_offensive_rebounds": 0,
              "team_defensive_rebounds": 2,
              "total_rebounds": 33,
              "total_turnovers": 8,
              "personal_rebounds": 31,
              "player_turnovers": 8,
              "field_goals_at_rim_made": 0,
              "field_goals_at_rim_att": 1,
              "field_goals_at_rim_pct": 0,
              "field_goals_at_midrange_made": 11,
              "field_goals_at_midrange_att": 20,
              "field_goals_at_midrange_pct": 55,
              "bench_points": 18,
              "biggest_lead": 4,
              "effective_fg_pct": 56.3,
              "efficiency": 84,
              "efficiency_game_score": 61.3,
              "fouls_drawn": 12,
              "offensive_fouls": 1,
              "pls_min": 4,
              "points_in_paint_att": 15,
              "points_in_paint_made": 8,
              "points_in_paint_pct": 53.3,
              "total_fouls": 14,
              "true_shooting_att": 68.28,
              "true_shooting_pct": 61.5,
              "most_unanswered": {
                "points": 10,
                "own_score": 81,
                "opp_score": 78
              },
              "periods": [
                {
                  "type": "REG",
                  "id": "c2a3e4bd-1eb2-4730-9460-0ea601ed6d6e",
                  "number": 1,
                  "sequence": 1,
                  "minutes": "21:00",
                  "field_goals_made": 6,
                  "field_goals_att": 15,
                  "field_goals_pct": 40,
                  "three_points_made": 1,
                  "three_points_att": 5,
                  "three_points_pct": 20,
                  "two_points_made": 5,
                  "two_points_att": 10,
                  "two_points_pct": 50,
                  "blocked_att": 1,
                  "free_throws_made": 3,
                  "free_throws_att": 4,
                  "free_throws_pct": 75,
                  "offensive_rebounds": 1,
                  "defensive_rebounds": 10,
                  "rebounds": 11,
                  "assists": 1,
                  "turnovers": 4,
                  "steals": 2,
                  "blocks": 0,
                  "assists_turnover_ratio": 0.25,
                  "personal_fouls": 0,
                  "offensive_fouls": 0,
                  "ejections": 0,
                  "points": 19,
                  "second_chance_pts": 2,
                  "team_turnovers": 0,
                  "points_off_turnovers": 3,
                  "team_rebounds": 0,
                  "flagrant_fouls": 0,
                  "player_tech_fouls": 0,
                  "team_tech_fouls": 0,
                  "coach_tech_fouls": 0,
                  "pls_min": -1,
                  "effective_fg_pct": 43.3,
                  "bench_points": 6,
                  "points_in_paint": 6,
                  "points_in_paint_att": 6,
                  "points_in_paint_made": 3,
                  "points_in_paint_pct": 50,
                  "true_shooting_att": 16.76,
                  "true_shooting_pct": 56.7,
                  "biggest_lead": 4,
                  "fouls_drawn": 4,
                  "total_turnovers": 4,
                  "efficiency": 22,
                  "efficiency_game_score": 12.9,
                  "winning_basket": false,
                  "free_throw_points": 6
                }
              ]
            },
            "coaches": [
              {
                "id": "ec258031-0e88-43dc-8abf-1c76c6ff9a4e",
                "full_name": "DJ Sackmann",
                "first_name": "DJ",
                "last_name": "Sackmann",
                "position": "Head Coach"
              }
            ],
            "players": [
              {
                "full_name": "Napheesa Collier",
                "jersey_number": "24",
                "id": "fd8d4b11-3d70-450a-b65c-016bec29cc9d",
                "first_name": "Napheesa",
                "last_name": "Collier",
                "position": "F",
                "primary_position": "NA",
                "played": true,
                "active": true,
                "starter": true,
                "on_court": true,
                "statistics": {
                  "minutes": "30:15",
                  "field_goals_made": 11,
                  "field_goals_att": 20,
                  "field_goals_pct": 55,
                  "three_points_made": 3,
                  "three_points_att": 7,
                  "three_points_pct": 42.9,
                  "two_points_made": 8,
                  "two_points_att": 13,
                  "two_points_pct": 61.5,
                  "blocked_att": 0,
                  "free_throws_made": 1,
                  "free_throws_att": 3,
                  "free_throws_pct": 33.3,
                  "offensive_rebounds": 1,
                  "defensive_rebounds": 9,
                  "rebounds": 10,
                  "assists": 3,
                  "turnovers": 1,
                  "steals": 1,
                  "blocks": 0,
                  "assists_turnover_ratio": 3,
                  "personal_fouls": 1,
                  "tech_fouls": 0,
                  "flagrant_fouls": 0,
                  "pls_min": 3,
                  "points": 27,
                  "free_throw_points": 2,
                  "tech_fouls_non_unsportsmanlike": 0,
                  "winning_basket": false,
                  "double_double": true,
                  "triple_double": false,
                  "effective_fg_pct": 62.5,
                  "efficiency": 31,
                  "efficiency_game_score": 21.7,
                  "fouls_drawn": 3,
                  "offensive_fouls": 0,
                  "points_in_paint": 10,
                  "points_in_paint_att": 7,
                  "points_in_paint_made": 5,
                  "points_in_paint_pct": 71.4,
                  "points_off_turnovers": 0,
                  "true_shooting_att": 21.32,
                  "true_shooting_pct": 63.3,
                  "coach_ejections": 0,
                  "coach_tech_fouls": 0,
                  "second_chance_pts": 2,
                  "second_chance_pct": 0
                }
              }
            ]
          },
          "officials": []
        }
        """
        
        // When
        let jsonData = fullJSON.data(using: .utf8)!
        let gameSummary = try JSONDecoder().decode(SportradarGameSummaryDTO.self, from: jsonData)
        
        // Then - Verify all major fields decode correctly
        XCTAssertEqual(gameSummary.id, "838316ea-ab7b-4581-a1dd-74229d1970d5")
        XCTAssertEqual(gameSummary.status, "closed")
        XCTAssertEqual(gameSummary.leadChanges, 7)
        XCTAssertEqual(gameSummary.timesTied, 6)
        XCTAssertNotNil(gameSummary.home)
        XCTAssertNotNil(gameSummary.away)
        XCTAssertNotNil(gameSummary.venue)
        XCTAssertNotNil(gameSummary.season)
        
        // Verify team statistics
        XCTAssertEqual(gameSummary.home?.statistics?.points, 80)
        XCTAssertEqual(gameSummary.away?.statistics?.points, 84)
        XCTAssertEqual(gameSummary.away?.statistics?.rebounds, 33)
        XCTAssertEqual(gameSummary.away?.statistics?.fieldGoalsPct ?? 0, 50.8, accuracy: 0.1)
        
        // Verify periods exist
        XCTAssertNotNil(gameSummary.home?.periods)
      XCTAssertNotNil(gameSummary.away?.periods)
        XCTAssertGreaterThanOrEqual(gameSummary.home?.periods?.count ?? 0, 1)
        XCTAssertGreaterThanOrEqual(gameSummary.away?.periods?.count ?? 0, 1)
        
        // Verify players have periods
        if let homePlayer = gameSummary.home?.players?.first {
            XCTAssertNotNil(homePlayer.periods)
            XCTAssertGreaterThanOrEqual(homePlayer.periods?.count ?? 0, 1)
        }
        
        if let awayPlayer = gameSummary.away?.players?.first {
            XCTAssertNotNil(awayPlayer.statistics)
            XCTAssertEqual(awayPlayer.statistics?.points, 27)
            XCTAssertEqual(awayPlayer.statistics?.doubleDouble, true)
        }
    }
    
    func testDecodeTeamPeriods() throws {
        // Given
        let jsonData = sportradarGameSummaryJSON.data(using: .utf8)!
        let gameSummary = try JSONDecoder().decode(SportradarGameSummaryDTO.self, from: jsonData)
        
        // When
        let homePeriods = gameSummary.home?.periods
        let awayPeriods = gameSummary.away?.periods
        
        // Then
        if let periods = homePeriods, !periods.isEmpty {
            let firstPeriod = periods[0]
            XCTAssertNotNil(firstPeriod.type)
            XCTAssertNotNil(firstPeriod.number)
            XCTAssertNotNil(firstPeriod.points)
            XCTAssertNotNil(firstPeriod.minutes)
        }
        
        if let periods = awayPeriods, !periods.isEmpty {
            let firstPeriod = periods[0]
            XCTAssertNotNil(firstPeriod.type)
            XCTAssertNotNil(firstPeriod.number)
            XCTAssertNotNil(firstPeriod.points)
        }
    }
    
    func testDecodePlayerPeriods() throws {
        // Given
        let jsonData = sportradarGameSummaryJSON.data(using: .utf8)!
        let gameSummary = try JSONDecoder().decode(SportradarGameSummaryDTO.self, from: jsonData)
        
        // When
        let homePlayers = gameSummary.home?.players
        
        // Then
        if let players = homePlayers, let firstPlayer = players.first {
            let playerPeriods = firstPlayer.periods
            if let periods = playerPeriods, !periods.isEmpty {
                let firstPeriod = periods[0]
                XCTAssertNotNil(firstPeriod.type)
                XCTAssertNotNil(firstPeriod.number)
                XCTAssertNotNil(firstPeriod.points)
                XCTAssertNotNil(firstPeriod.minutes)
            }
        }
    }
}
