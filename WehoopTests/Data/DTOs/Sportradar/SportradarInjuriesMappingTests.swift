//
//  SportradarInjuriesMappingTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class SportradarInjuriesMappingTests: XCTestCase {
    // MARK: - Sportradar Injuries JSON Example
    let sportradarInjuriesJSON = """
    {
      "league": {
        "id": "844ee10a-00c8-4dc1-9c17-52598de2ef47",
        "name": "Unrivaled",
        "alias": "UNRIVALED"
      },
      "teams": [
        {
          "id": "3b7f5d56-3586-4d58-98a7-562e267a965e",
          "name": "Rose",
          "franchise_id": "05f487c9-1fe6-4253-a49a-e7870662f445",
          "players": [
            {
              "id": "061f14c8-06ae-4ad1-aa4b-91260b8a4dbb",
              "full_name": "Kahleah Copper",
              "first_name": "Kahleah",
              "last_name": "Copper",
              "position": "G-F",
              "primary_position": "NA",
              "jersey_number": "2",
              "injuries": [
                {
                  "id": "9dba230e-0fda-4184-9cfd-a2d2c8cc9b06",
                  "comment": "Copper did not play in Sunday's (Jan. 11) game versus Breeze BC.",
                  "desc": "R Lower Extremity",
                  "status": "Day To Day",
                  "start_date": "2026-01-02",
                  "update_date": "2026-01-12"
                }
              ]
            }
          ]
        },
        {
          "id": "865d71fd-8173-4f06-ba93-fe886dd78330",
          "name": "Breeze",
          "franchise_id": "8e8152ab-ab83-4647-adb4-e1fb1d5d5831",
          "players": [
            {
              "id": "285bb3a5-6359-4aa7-8f5d-b0692b92a675",
              "full_name": "Aari McDonald",
              "first_name": "Aari",
              "last_name": "McDonald",
              "position": "G",
              "primary_position": "NA",
              "jersey_number": "3",
              "injuries": [
                {
                  "id": "f1c36a34-c195-4194-a1c5-b371734ffa33",
                  "comment": "McDonald did not play in Sunday's (Jan. 11) game versus Rose BC.",
                  "desc": "R Lower Extremity",
                  "status": "Day To Day",
                  "start_date": "2026-01-09",
                  "update_date": "2026-01-12"
                }
              ]
            }
          ]
        },
        {
          "id": "e5be75a6-cd4a-41d3-b3c3-638506ced50a",
          "name": "Phantom",
          "franchise_id": "77b5abc4-be3e-4833-96cd-3fac6e0eb427",
          "players": [
            {
              "id": "41186b39-3a4c-4aab-adf4-a5612e473956",
              "full_name": "Dana Evans",
              "first_name": "Dana",
              "last_name": "Evans",
              "position": "G",
              "primary_position": "NA",
              "jersey_number": "11",
              "injuries": [
                {
                  "id": "538d270f-03aa-439d-933c-f8042063ffda",
                  "comment": "Evans did not play in Monday's (Jan. 12) game against the Mist.",
                  "desc": "L Lower Extremity",
                  "status": "Day To Day",
                  "start_date": "2026-01-02",
                  "update_date": "2026-01-13"
                }
              ]
            },
            {
              "id": "d3834c4d-c63e-4b2d-acee-6bd686f7858b",
              "full_name": "Satou Sabally",
              "first_name": "Satou",
              "last_name": "Sabally",
              "position": "F",
              "primary_position": "NA",
              "jersey_number": "0",
              "injuries": [
                {
                  "id": "9c7874f2-a197-4710-8718-200305b86aee",
                  "comment": "Sabally did not play in Monday's (Jan. 12) game against the Mist.",
                  "desc": "Concussion",
                  "status": "Day To Day",
                  "start_date": "2026-01-04",
                  "update_date": "2026-01-13"
                }
              ]
            }
          ]
        },
        {
          "id": "67c22115-2385-458f-8632-a67a025fef55",
          "name": "Lunar Owls",
          "franchise_id": "0fe49837-e922-47d2-a063-3025ab8359db",
          "players": [
            {
              "id": "bee3dbc6-82f7-4dc0-b097-0cb42a1c00a2",
              "full_name": "Skylar Diggins",
              "first_name": "Skylar",
              "last_name": "Diggins",
              "position": "G",
              "primary_position": "NA",
              "jersey_number": "4",
              "injuries": [
                {
                  "id": "198af9ba-91ff-4654-abb7-4a0a6b39aecf",
                  "comment": "Diggins did not play in Monday's (Jan. 12) game against the Laces.",
                  "desc": "R Lower Extremity",
                  "status": "Day To Day",
                  "start_date": "2026-01-02",
                  "update_date": "2026-01-13"
                }
              ]
            },
            {
              "id": "fd8d4b11-3d70-450a-b65c-016bec29cc9d",
              "full_name": "Napheesa Collier",
              "first_name": "Napheesa",
              "last_name": "Collier",
              "position": "F",
              "primary_position": "NA",
              "jersey_number": "24",
              "injuries": [
                {
                  "id": "f7b1c392-afdc-4f4d-8417-851cfee9190f",
                  "comment": "The Lunar Owls announced that F Napheesa Collier will miss the season while recovering from surgeries on both ankles.",
                  "desc": "Ankles",
                  "status": "Out For Season",
                  "start_date": "2026-01-02",
                  "update_date": "2026-01-02"
                }
              ]
            }
          ]
        }
      ]
    }
    """
    
    // MARK: - Decoding Tests
    
    func testDecodeSportradarInjuriesResponse() throws {
        // Given
        let jsonData = sportradarInjuriesJSON.data(using: .utf8)!
        
        // When
        let injuriesResponse = try JSONDecoder().decode(SportradarInjuriesResponseDTO.self, from: jsonData)
        
        // Then
        XCTAssertNotNil(injuriesResponse.league)
        XCTAssertEqual(injuriesResponse.league?.id, "844ee10a-00c8-4dc1-9c17-52598de2ef47")
        XCTAssertEqual(injuriesResponse.league?.name, "Unrivaled")
        XCTAssertEqual(injuriesResponse.teams.count, 4)
    }
    
    func testDecodeTeamInjuries() throws {
        // Given
        let jsonData = sportradarInjuriesJSON.data(using: .utf8)!
        let injuriesResponse = try JSONDecoder().decode(SportradarInjuriesResponseDTO.self, from: jsonData)
        
        // When
        let firstTeam = injuriesResponse.teams[0]
        
        // Then
        XCTAssertEqual(firstTeam.id, "3b7f5d56-3586-4d58-98a7-562e267a965e")
        XCTAssertEqual(firstTeam.name, "Rose")
        XCTAssertEqual(firstTeam.franchiseId, "05f487c9-1fe6-4253-a49a-e7870662f445")
        XCTAssertEqual(firstTeam.players.count, 1)
    }
    
    func testDecodePlayerInjuries() throws {
        // Given
        let jsonData = sportradarInjuriesJSON.data(using: .utf8)!
        let injuriesResponse = try JSONDecoder().decode(SportradarInjuriesResponseDTO.self, from: jsonData)
        
        // When
        let firstTeam = injuriesResponse.teams[0]
        let firstPlayer = firstTeam.players[0]
        
        // Then
        XCTAssertEqual(firstPlayer.id, "061f14c8-06ae-4ad1-aa4b-91260b8a4dbb")
        XCTAssertEqual(firstPlayer.fullName, "Kahleah Copper")
        XCTAssertEqual(firstPlayer.firstName, "Kahleah")
        XCTAssertEqual(firstPlayer.lastName, "Copper")
        XCTAssertEqual(firstPlayer.position, "G-F")
        XCTAssertEqual(firstPlayer.jerseyNumber, "2")
        XCTAssertEqual(firstPlayer.injuries.count, 1)
    }
    
    func testDecodeInjury() throws {
        // Given
        let jsonData = sportradarInjuriesJSON.data(using: .utf8)!
        let injuriesResponse = try JSONDecoder().decode(SportradarInjuriesResponseDTO.self, from: jsonData)
        
        // When
        let firstTeam = injuriesResponse.teams[0]
        let firstPlayer = firstTeam.players[0]
        let firstInjury = firstPlayer.injuries[0]
        
        // Then
        XCTAssertEqual(firstInjury.id, "9dba230e-0fda-4184-9cfd-a2d2c8cc9b06")
        XCTAssertNotNil(firstInjury.comment)
        XCTAssertEqual(firstInjury.desc, "R Lower Extremity")
        XCTAssertEqual(firstInjury.status, "Day To Day")
        XCTAssertEqual(firstInjury.startDate, "2026-01-02")
        XCTAssertEqual(firstInjury.updateDate, "2026-01-12")
    }
    
    func testDecodeMultipleInjuryStatuses() throws {
        // Given
        let jsonData = sportradarInjuriesJSON.data(using: .utf8)!
        let injuriesResponse = try JSONDecoder().decode(SportradarInjuriesResponseDTO.self, from: jsonData)
        
        // When
        let lunarOwls = injuriesResponse.teams.first { $0.name == "Lunar Owls" }!
        let collier = lunarOwls.players.first { $0.fullName == "Napheesa Collier" }!
        let collierInjury = collier.injuries[0]
        
        // Then
        XCTAssertEqual(collierInjury.status, "Out For Season")
        XCTAssertEqual(collierInjury.desc, "Ankles")
    }
    
    // MARK: - Mapping Tests
    
    func testMapInjuryToDomain() throws {
        // Given
        let jsonData = sportradarInjuriesJSON.data(using: .utf8)!
        let injuriesResponse = try JSONDecoder().decode(SportradarInjuriesResponseDTO.self, from: jsonData)
        let firstTeam = injuriesResponse.teams[0]
        let firstPlayer = firstTeam.players[0]
        let injuryDTO = firstPlayer.injuries[0]
        
        // When
        let injury = try injuryDTO.toDomain()
        
        // Then
        XCTAssertEqual(injury.id, "9dba230e-0fda-4184-9cfd-a2d2c8cc9b06")
        XCTAssertEqual(injury.description, "R Lower Extremity")
        XCTAssertEqual(injury.status, .dayToDay)
        XCTAssertNotNil(injury.startDate)
        XCTAssertNotNil(injury.updateDate)
        XCTAssertTrue(injury.isActive)
    }
    
    func testMapPlayerWithInjuriesToDomain() throws {
        // Given
        let jsonData = sportradarInjuriesJSON.data(using: .utf8)!
        let injuriesResponse = try JSONDecoder().decode(SportradarInjuriesResponseDTO.self, from: jsonData)
        let firstTeam = injuriesResponse.teams[0]
        let playerDTO = firstTeam.players[0]
        
        // When
        let player = try playerDTO.toDomain()
        
        // Then
        XCTAssertEqual(player.id, "061f14c8-06ae-4ad1-aa4b-91260b8a4dbb")
        XCTAssertEqual(player.fullName, "Kahleah Copper")
        XCTAssertEqual(player.position, "G-F")
        XCTAssertEqual(player.jerseyNumber, "2")
        XCTAssertEqual(player.injuries.count, 1)
        XCTAssertTrue(player.hasActiveInjuries)
        XCTAssertNotNil(player.mostSevereInjury)
    }
    
    func testMapTeamInjuriesToDomain() throws {
        // Given
        let jsonData = sportradarInjuriesJSON.data(using: .utf8)!
        let injuriesResponse = try JSONDecoder().decode(SportradarInjuriesResponseDTO.self, from: jsonData)
        let teamDTO = injuriesResponse.teams[0]
        
        // When
        let team = try teamDTO.toDomain()
        
        // Then
        XCTAssertEqual(team.id, "3b7f5d56-3586-4d58-98a7-562e267a965e")
        XCTAssertEqual(team.name, "Rose")
        XCTAssertEqual(team.players.count, 1)
        XCTAssertEqual(team.activeInjuryCount, 1)
    }
    
    func testMapLeagueInjuriesToDomain() throws {
        // Given
        let jsonData = sportradarInjuriesJSON.data(using: .utf8)!
        let injuriesResponse = try JSONDecoder().decode(SportradarInjuriesResponseDTO.self, from: jsonData)
        
        // When
        let leagueInjuries = try injuriesResponse.toDomain()
        
        // Then
        XCTAssertEqual(leagueInjuries.id, "844ee10a-00c8-4dc1-9c17-52598de2ef47")
        XCTAssertEqual(leagueInjuries.name, "Unrivaled")
        XCTAssertEqual(leagueInjuries.alias, "UNRIVALED")
        XCTAssertEqual(leagueInjuries.teams.count, 4)
        XCTAssertGreaterThan(leagueInjuries.totalActiveInjuries, 0)
    }
    
    func testInjuryStatusMapping() throws {
        // Given
        let dayToDayJSON = """
        {
          "id": "test-id",
          "comment": "Test",
          "desc": "Test Injury",
          "status": "Day To Day",
          "start_date": "2026-01-01",
          "update_date": "2026-01-02"
        }
        """
        
        let outForSeasonJSON = """
        {
          "id": "test-id-2",
          "comment": "Test",
          "desc": "Test Injury",
          "status": "Out For Season",
          "start_date": "2026-01-01",
          "update_date": "2026-01-02"
        }
        """
        
        // When
        let dayToDayData = dayToDayJSON.data(using: .utf8)!
        let outForSeasonData = outForSeasonJSON.data(using: .utf8)!
        let dayToDayDTO = try JSONDecoder().decode(SportradarInjuryDTO.self, from: dayToDayData)
        let outForSeasonDTO = try JSONDecoder().decode(SportradarInjuryDTO.self, from: outForSeasonData)
        
        let dayToDay = try dayToDayDTO.toDomain()
        let outForSeason = try outForSeasonDTO.toDomain()
        
        // Then
        XCTAssertEqual(dayToDay.status, .dayToDay)
        XCTAssertEqual(outForSeason.status, .outForSeason)
        XCTAssertTrue(dayToDay.isActive)
        XCTAssertTrue(outForSeason.isActive)
        XCTAssertGreaterThan(outForSeason.status.severity, dayToDay.status.severity)
    }
    
    func testMostSevereInjury() throws {
        // Given
        let jsonData = sportradarInjuriesJSON.data(using: .utf8)!
        let injuriesResponse = try JSONDecoder().decode(SportradarInjuriesResponseDTO.self, from: jsonData)
        let lunarOwls = injuriesResponse.teams.first { $0.name == "Lunar Owls" }!
        let collier = lunarOwls.players.first { $0.fullName == "Napheesa Collier" }!
        
        // When
        let player = try collier.toDomain()
        
        // Then
        XCTAssertTrue(player.hasActiveInjuries)
        XCTAssertNotNil(player.mostSevereInjury)
        XCTAssertEqual(player.mostSevereInjury?.status, .outForSeason)
    }
    
    func testAllPlayersWithInjuries() throws {
        // Given
        let jsonData = sportradarInjuriesJSON.data(using: .utf8)!
        let injuriesResponse = try JSONDecoder().decode(SportradarInjuriesResponseDTO.self, from: jsonData)
        
        // When
        let leagueInjuries = try injuriesResponse.toDomain()
        let allPlayersWithInjuries = leagueInjuries.allPlayersWithInjuries
        
        // Then
        XCTAssertGreaterThan(allPlayersWithInjuries.count, 0)
        XCTAssertTrue(allPlayersWithInjuries.allSatisfy { $0.hasActiveInjuries })
    }
    
    func testDateParsing() throws {
        // Given
        let jsonData = sportradarInjuriesJSON.data(using: .utf8)!
        let injuriesResponse = try JSONDecoder().decode(SportradarInjuriesResponseDTO.self, from: jsonData)
        let firstTeam = injuriesResponse.teams[0]
        let firstPlayer = firstTeam.players[0]
        let injuryDTO = firstPlayer.injuries[0]
        
        // When
        let injury = try injuryDTO.toDomain()
        
        // Then
        XCTAssertNotNil(injury.startDate)
        XCTAssertNotNil(injury.updateDate)
        XCTAssertNotNil(injury.formattedStartDate)
        XCTAssertNotNil(injury.formattedUpdateDate)
    }
}
