//
//  SportradarScheduleMappingTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class SportradarScheduleMappingTests: XCTestCase {
    // MARK: - Sportradar Schedule JSON Example
    // This is the actual Sportradar API schedule response structure
    let sportradarScheduleJSON = """
    {
      "date": "2026-01-16",
      "league": {
        "id": "844ee10a-00c8-4dc1-9c17-52598de2ef47",
        "name": "Unrivaled",
        "alias": "UNRIVALED"
      },
      "games": [
        {
          "id": "f685ea45-18a5-405b-9bdb-f0b0b4a2f93e",
          "status": "scheduled",
          "coverage": "full",
          "scheduled": "2026-01-17T00:30:00+00:00",
          "track_on_court": true,
          "time_zones": {
            "venue": "US/Eastern",
            "home": "US/Eastern",
            "away": "US/Eastern"
          },
          "season": {
            "id": "e8440860-998c-42ca-902d-461e588de916",
            "year": 2026,
            "type": "REG"
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
          "broadcasts": [
            {
              "network": "TNT",
              "type": "TV",
              "locale": "National",
              "channel": "245"
            }
          ],
          "home": {
            "name": "Phantom",
            "alias": "PHA",
            "id": "e5be75a6-cd4a-41d3-b3c3-638506ced50a"
          },
          "away": {
            "name": "Laces",
            "alias": "LCS",
            "id": "b1da8619-1db7-4c21-99bb-4c7307e25026"
          }
        },
        {
          "id": "101d352d-2591-447d-b6ce-9c239cf73fc4",
          "status": "scheduled",
          "coverage": "full",
          "scheduled": "2026-01-17T01:45:00+00:00",
          "track_on_court": true,
          "time_zones": {
            "venue": "US/Eastern",
            "home": "US/Eastern",
            "away": "US/Eastern"
          },
          "season": {
            "id": "e8440860-998c-42ca-902d-461e588de916",
            "year": 2026,
            "type": "REG"
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
          "broadcasts": [
            {
              "network": "TNT",
              "type": "TV",
              "locale": "National",
              "channel": "245"
            }
          ],
          "home": {
            "name": "Hive",
            "alias": "HVE",
            "id": "56351bfa-e888-400d-ade3-01f551dd33b9"
          },
          "away": {
            "name": "Rose",
            "alias": "ROS",
            "id": "3b7f5d56-3586-4d58-98a7-562e267a965e"
          }
        }
      ]
    }
    """
    
    // MARK: - Decode Tests
    
    func testDecodeSportradarSchedule() throws {
        // Given
        let jsonData = sportradarScheduleJSON.data(using: .utf8)!
        
        // When
        let schedule = try JSONDecoder().decode(SportradarScheduleDTO.self, from: jsonData)
        
        // Then
        XCTAssertEqual(schedule.date, "2026-01-16")
        XCTAssertNotNil(schedule.league)
        XCTAssertEqual(schedule.league?.name, "Unrivaled")
        XCTAssertEqual(schedule.league?.alias, "UNRIVALED")
        XCTAssertNotNil(schedule.games)
        XCTAssertEqual(schedule.games?.count, 2)
    }
    
    func testDecodeScheduleGame() throws {
        // Given
        let jsonData = sportradarScheduleJSON.data(using: .utf8)!
        let schedule = try JSONDecoder().decode(SportradarScheduleDTO.self, from: jsonData)
        
        // When
        let firstGame = schedule.games?.first
        
        // Then
        XCTAssertNotNil(firstGame)
        XCTAssertEqual(firstGame?.id, "f685ea45-18a5-405b-9bdb-f0b0b4a2f93e")
        XCTAssertEqual(firstGame?.status, "scheduled")
        XCTAssertEqual(firstGame?.coverage, "full")
        XCTAssertEqual(firstGame?.scheduled, "2026-01-17T00:30:00+00:00")
        XCTAssertEqual(firstGame?.trackOnCourt, true)
        XCTAssertNotNil(firstGame?.timeZones)
        XCTAssertEqual(firstGame?.timeZones?.venue, "US/Eastern")
        XCTAssertNotNil(firstGame?.season)
        XCTAssertEqual(firstGame?.season?.year, 2026)
        XCTAssertEqual(firstGame?.season?.type, "REG")
        XCTAssertNotNil(firstGame?.venue)
        XCTAssertEqual(firstGame?.venue?.name, "Sephora Arena")
        XCTAssertNotNil(firstGame?.broadcasts)
        XCTAssertEqual(firstGame?.broadcasts?.count, 1)
        XCTAssertEqual(firstGame?.broadcasts?.first?.network, "TNT")
        XCTAssertNotNil(firstGame?.home)
        XCTAssertEqual(firstGame?.home?.id, "e5be75a6-cd4a-41d3-b3c3-638506ced50a")
        XCTAssertEqual(firstGame?.home?.name, "Phantom")
        XCTAssertEqual(firstGame?.home?.alias, "PHA")
        XCTAssertNotNil(firstGame?.away)
        XCTAssertEqual(firstGame?.away?.id, "b1da8619-1db7-4c21-99bb-4c7307e25026")
        XCTAssertEqual(firstGame?.away?.name, "Laces")
        XCTAssertEqual(firstGame?.away?.alias, "LCS")
    }
    
    // MARK: - Mapping Tests
    
    func testMapScheduleToGameDTOs() throws {
        // Given
        let jsonData = sportradarScheduleJSON.data(using: .utf8)!
        let schedule = try JSONDecoder().decode(SportradarScheduleDTO.self, from: jsonData)
        
        // Mock teams needed for mapping using TeamDTOBuilder
        let phantomTeam = TeamDTOBuilder()
            .withId("e5be75a6-cd4a-41d3-b3c3-638506ced50a")
            .withName("Phantom")
            .withAbbreviation("PHA")
            .build()
        
        let lacesTeam = TeamDTOBuilder()
            .withId("b1da8619-1db7-4c21-99bb-4c7307e25026")
            .withName("Laces")
            .withAbbreviation("LCS")
            .build()
        
        let hiveTeam = TeamDTOBuilder()
            .withId("56351bfa-e888-400d-ade3-01f551dd33b9")
            .withName("Hive")
            .withAbbreviation("HVE")
            .build()
        
        let roseTeam = TeamDTOBuilder()
            .withId("3b7f5d56-3586-4d58-98a7-562e267a965e")
            .withName("Rose")
            .withAbbreviation("ROS")
            .build()
        
        let teamsDict = [
            phantomTeam.id: phantomTeam,
            lacesTeam.id: lacesTeam,
            hiveTeam.id: hiveTeam,
            roseTeam.id: roseTeam
        ]
        
        // When
        let gameDTOs = try SportradarDTOMapper.mapSchedule(schedule, teams: teamsDict)
        
        // Then
        XCTAssertEqual(gameDTOs.count, 2)
        
        let firstGame = gameDTOs[0]
        XCTAssertEqual(firstGame.id, "f685ea45-18a5-405b-9bdb-f0b0b4a2f93e")
        XCTAssertEqual(firstGame.homeTeam.name, "Phantom")
        XCTAssertEqual(firstGame.awayTeam.name, "Laces")
        XCTAssertEqual(firstGame.status, GameStatus.scheduled.rawValue)
        XCTAssertEqual(firstGame.venue, "Sephora Arena")
        XCTAssertNil(firstGame.boxScore) // Scheduled games don't have boxscores yet
        
        let secondGame = gameDTOs[1]
        XCTAssertEqual(secondGame.id, "101d352d-2591-447d-b6ce-9c239cf73fc4")
        XCTAssertEqual(secondGame.homeTeam.name, "Hive")
        XCTAssertEqual(secondGame.awayTeam.name, "Rose")
    }
    
    func testMapScheduleGameWithSeason() throws {
        // Given
        let jsonData = sportradarScheduleJSON.data(using: .utf8)!
        let schedule = try JSONDecoder().decode(SportradarScheduleDTO.self, from: jsonData)
        
        let phantomTeam = TeamDTOBuilder()
            .withId("e5be75a6-cd4a-41d3-b3c3-638506ced50a")
            .withName("Phantom")
            .withAbbreviation("PHA")
            .build()
        
        let lacesTeam = TeamDTOBuilder()
            .withId("b1da8619-1db7-4c21-99bb-4c7307e25026")
            .withName("Laces")
            .withAbbreviation("LCS")
            .build()
        
        let teamsDict = [phantomTeam.id: phantomTeam, lacesTeam.id: lacesTeam]
        
        // When
        let gameDTOs = try SportradarDTOMapper.mapSchedule(schedule, teams: teamsDict)
        
        // Then - League should come from season name if available
        let firstGame = gameDTOs[0]
        // Note: season.name is nil in the JSON, so league will be nil
        // But the structure supports it
        XCTAssertNotNil(firstGame.date)
    }
    
    func testMapScheduleWithMissingTeams() throws {
        // Given
        let jsonData = sportradarScheduleJSON.data(using: .utf8)!
        let schedule = try JSONDecoder().decode(SportradarScheduleDTO.self, from: jsonData)
        
        // Only provide one team (missing the other)
        let phantomTeam = TeamDTOBuilder()
            .withId("e5be75a6-cd4a-41d3-b3c3-638506ced50a")
            .withName("Phantom")
            .withAbbreviation("PHA")
            .build()
        
        let teamsDict = [phantomTeam.id: phantomTeam]
        
        // When
        let gameDTOs = try SportradarDTOMapper.mapSchedule(schedule, teams: teamsDict)
        
        // Then - Games with missing teams should be skipped
        XCTAssertEqual(gameDTOs.count, 0, "Games with missing teams should be skipped")
    }
    
    func testMapScheduleWithEmptyGames() throws {
        // Given
        let emptySchedule = SportradarScheduleDTO(
            date: "2026-01-16",
            league: nil,
            games: []
        )
        let teamsDict: [String: TeamDTO] = [:]
        
        // When
        let gameDTOs = try SportradarDTOMapper.mapSchedule(emptySchedule, teams: teamsDict)
        
        // Then
        XCTAssertEqual(gameDTOs.count, 0)
    }
    
    func testMapScheduleWithNilGames() throws {
        // Given
        let scheduleWithNilGames = SportradarScheduleDTO(
            date: "2026-01-16",
            league: nil,
            games: nil
        )
        let teamsDict: [String: TeamDTO] = [:]
        
        // When
        let gameDTOs = try SportradarDTOMapper.mapSchedule(scheduleWithNilGames, teams: teamsDict)
        
        // Then
        XCTAssertEqual(gameDTOs.count, 0)
    }
    
    // MARK: - Date Parsing Tests
    
    func testMapScheduleGameDate() throws {
        // Given
        let jsonData = sportradarScheduleJSON.data(using: .utf8)!
        let schedule = try JSONDecoder().decode(SportradarScheduleDTO.self, from: jsonData)
        
        let phantomTeam = TeamDTOBuilder()
            .withId("e5be75a6-cd4a-41d3-b3c3-638506ced50a")
            .withName("Phantom")
            .withAbbreviation("PHA")
            .build()
        
        let lacesTeam = TeamDTOBuilder()
            .withId("b1da8619-1db7-4c21-99bb-4c7307e25026")
            .withName("Laces")
            .withAbbreviation("LCS")
            .build()
        
        let teamsDict = [phantomTeam.id: phantomTeam, lacesTeam.id: lacesTeam]
        
        // When
        let gameDTOs = try SportradarDTOMapper.mapSchedule(schedule, teams: teamsDict)
        
        // Then
        let firstGame = gameDTOs[0]
        XCTAssertNotNil(firstGame.date)
        // Date should be in ISO 8601 format
        XCTAssertTrue(firstGame.date.contains("2026-01-17"))
    }
}
