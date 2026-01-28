//
//  SportradarLeagueLeadersMappingTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class SportradarLeagueLeadersMappingTests: XCTestCase {
    // MARK: - Sportradar League Leaders JSON Example
    
    let sportradarLeagueLeadersJSON = """
    {
      "category": "points",
      "leaders": [
        {
          "player": {
            "id": "061f14c8-06ae-4ad1-aa4b-91260b8a4dbb",
            "full_name": "Caitlin Clark",
            "first_name": "Caitlin",
            "last_name": "Clark",
            "position": "G",
            "jersey_number": "22",
            "height": "72",
            "weight": "170",
            "age": 22,
            "birth_date": "2002-01-22",
            "birth_place": "West Des Moines, IA",
            "college": "Iowa",
            "photo": "https://example.com/photos/clark.jpg",
            "team": {
              "id": "3b7f5d56-3586-4d58-98a7-562e267a965e",
              "name": "Rose",
              "alias": "ROS"
            },
            "team_id": "3b7f5d56-3586-4d58-98a7-562e267a965e"
          },
          "player_id": "061f14c8-06ae-4ad1-aa4b-91260b8a4dbb",
          "value": 28.5,
          "rank": 1
        },
        {
          "player": {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "full_name": "Rickea Jackson",
            "first_name": "Rickea",
            "last_name": "Jackson",
            "position": "F",
            "jersey_number": "4",
            "height": "74",
            "weight": "180",
            "age": 23,
            "birth_date": "2001-05-15",
            "birth_place": "Detroit, MI",
            "college": "Tennessee",
            "photo": "https://example.com/photos/jackson.jpg",
            "team": {
              "id": "3b7f5d56-3586-4d58-98a7-562e267a965e",
              "name": "Rose",
              "alias": "ROS"
            },
            "team_id": "3b7f5d56-3586-4d58-98a7-562e267a965e"
          },
          "player_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
          "value": 24.2,
          "rank": 2
        },
        {
          "player": {
            "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
            "full_name": "Breanna Stewart",
            "first_name": "Breanna",
            "last_name": "Stewart",
            "position": "F",
            "jersey_number": "30",
            "height": "76",
            "weight": "170",
            "age": 29,
            "birth_date": "1994-08-27",
            "birth_place": "Syracuse, NY",
            "college": "UConn",
            "photo": "https://example.com/photos/stewart.jpg",
            "team": {
              "id": "0780b080-347b-407b-b8d6-fa109ec23908",
              "name": "Mist",
              "alias": "MST"
            },
            "team_id": "0780b080-347b-407b-b8d6-fa109ec23908"
          },
          "player_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
          "value": 22.8,
          "rank": 3
        }
      ]
    }
    """
    
    let sportradarLeagueLeadersReboundsJSON = """
    {
      "category": "rebounds",
      "leaders": [
        {
          "player": {
            "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
            "full_name": "Angel Reese",
            "first_name": "Angel",
            "last_name": "Reese",
            "position": "F",
            "jersey_number": "10",
            "height": "75",
            "weight": "190",
            "age": 21,
            "birth_date": "2003-05-06",
            "birth_place": "Baltimore, MD",
            "college": "LSU",
            "team": {
              "id": "4eeb0d49-106d-4a2d-8917-b703595219dc",
              "name": "Lunar Owls",
              "alias": "LUN"
            },
            "team_id": "4eeb0d49-106d-4a2d-8917-b703595219dc"
          },
          "player_id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
          "value": 12.3,
          "rank": 1
        }
      ]
    }
    """
    
    // MARK: - Decoding Tests
    
    func testDecodeSportradarLeagueLeaders() throws {
        // Given
        let jsonData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        
        // When
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // Then
        XCTAssertNotNil(leaders.category)
        XCTAssertEqual(leaders.category, "points")
        XCTAssertNotNil(leaders.leaders)
        XCTAssertEqual(leaders.leaders?.count, 3)
    }
    
    func testDecodeLeaderEntry() throws {
        // Given
        let jsonData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // When
        let firstLeader = leaders.leaders![0]
        
        // Then
        XCTAssertNotNil(firstLeader.player)
        XCTAssertEqual(firstLeader.playerId, "061f14c8-06ae-4ad1-aa4b-91260b8a4dbb")
        XCTAssertEqual(firstLeader.value, 28.5)
        XCTAssertEqual(firstLeader.rank, 1)
    }
    
    func testDecodePlayerInLeader() throws {
        // Given
        let jsonData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        let firstLeader = leaders.leaders![0]
        
        // When
        let player = firstLeader.player!
        
        // Then
        XCTAssertEqual(player.id, "061f14c8-06ae-4ad1-aa4b-91260b8a4dbb")
        XCTAssertEqual(player.fullName, "Caitlin Clark")
        XCTAssertEqual(player.firstName, "Caitlin")
        XCTAssertEqual(player.lastName, "Clark")
        XCTAssertEqual(player.position, "G")
        XCTAssertEqual(player.jerseyNumber, "22")
        XCTAssertEqual(player.height, "72")
        XCTAssertEqual(player.weight, "170")
        XCTAssertEqual(player.age, 22)
        XCTAssertEqual(player.birthDate, "2002-01-22")
        XCTAssertEqual(player.birthPlace, "West Des Moines, IA")
        XCTAssertEqual(player.college, "Iowa")
        XCTAssertNotNil(player.team)
        XCTAssertEqual(player.teamId, "3b7f5d56-3586-4d58-98a7-562e267a965e")
    }
    
    func testDecodeTeamReferenceInLeader() throws {
        // Given
        let jsonData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        let firstLeader = leaders.leaders![0]
        let player = firstLeader.player!
        
        // When
        let team = player.team!
        
        // Then
        XCTAssertEqual(team.id, "3b7f5d56-3586-4d58-98a7-562e267a965e")
        XCTAssertEqual(team.name, "Rose")
        XCTAssertEqual(team.alias, "ROS")
    }
    
    func testDecodeMultipleLeaders() throws {
        // Given
        let jsonData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // When
        let leaderList = leaders.leaders!
        
        // Then
        XCTAssertEqual(leaderList.count, 3)
        
        // Verify first leader
        XCTAssertEqual(leaderList[0].rank, 1)
        XCTAssertEqual(leaderList[0].value, 28.5)
        XCTAssertEqual(leaderList[0].player?.fullName, "Caitlin Clark")
        
        // Verify second leader
        XCTAssertEqual(leaderList[1].rank, 2)
        XCTAssertEqual(leaderList[1].value, 24.2)
        XCTAssertEqual(leaderList[1].player?.fullName, "Rickea Jackson")
        
        // Verify third leader
        XCTAssertEqual(leaderList[2].rank, 3)
        XCTAssertEqual(leaderList[2].value, 22.8)
        XCTAssertEqual(leaderList[2].player?.fullName, "Breanna Stewart")
    }
    
    func testDecodeDifferentCategory() throws {
        // Given
        let jsonData = sportradarLeagueLeadersReboundsJSON.data(using: .utf8)!
        
        // When
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // Then
        XCTAssertEqual(leaders.category, "rebounds")
        XCTAssertEqual(leaders.leaders?.count, 1)
        XCTAssertEqual(leaders.leaders?[0].player?.fullName, "Angel Reese")
        XCTAssertEqual(leaders.leaders?[0].value, 12.3)
    }
    
    func testDecodeEmptyLeaders() throws {
        // Given
        let emptyJSON = """
        {
          "category": "assists",
          "leaders": []
        }
        """
        let jsonData = emptyJSON.data(using: .utf8)!
        
        // When
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // Then
        XCTAssertEqual(leaders.category, "assists")
        XCTAssertNotNil(leaders.leaders)
        XCTAssertEqual(leaders.leaders?.count, 0)
    }
    
    func testDecodeMissingCategory() throws {
        // Given
        let missingCategoryJSON = """
        {
          "leaders": [
            {
              "player": {
                "id": "test-id",
                "full_name": "Test Player"
              },
              "player_id": "test-id",
              "value": 10.0,
              "rank": 1
            }
          ]
        }
        """
        let jsonData = missingCategoryJSON.data(using: .utf8)!
        
        // When
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // Then
        XCTAssertNil(leaders.category)
        XCTAssertNotNil(leaders.leaders)
        XCTAssertEqual(leaders.leaders?.count, 1)
    }
    
    func testDecodeMissingLeaders() throws {
        // Given
        let missingLeadersJSON = """
        {
          "category": "points"
        }
        """
        let jsonData = missingLeadersJSON.data(using: .utf8)!
        
        // When
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // Then
        XCTAssertEqual(leaders.category, "points")
        XCTAssertNil(leaders.leaders)
    }
    
    // MARK: - Mapping Tests
    
    func testMapLeagueLeadersToPlayerDTOs() throws {
        // Given
        let jsonData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        let leadersDTO = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // Create team DTOs for mapping
        let teamDTOs: [String: TeamDTO] = [
            "3b7f5d56-3586-4d58-98a7-562e267a965e": TeamDTO(
                id: "3b7f5d56-3586-4d58-98a7-562e267a965e",
                name: "Rose",
                abbreviation: "ROS",
                logoURL: nil,
                city: "City",
                conference: "East",
                division: nil,
                wins: nil,
                losses: nil,
                winPercentage: nil
            ),
            "0780b080-347b-407b-b8d6-fa109ec23908": TeamDTO(
                id: "0780b080-347b-407b-b8d6-fa109ec23908",
                name: "Mist",
                abbreviation: "MST",
                logoURL: nil,
                city: "City",
                conference: "West",
                division: nil,
                wins: nil,
                losses: nil,
                winPercentage: nil
            )
        ]
        
        // When
        let mappedLeaders = SportradarDTOMapper.mapLeagueLeaders(leadersDTO, teams: teamDTOs)
        
        // Then
        XCTAssertEqual(mappedLeaders.count, 3)
        XCTAssertEqual(mappedLeaders[0].category, "points")
        XCTAssertEqual(mappedLeaders[0].player.name, "Caitlin Clark")
        XCTAssertEqual(mappedLeaders[0].player.team.name, "Rose")
        XCTAssertEqual(mappedLeaders[1].category, "points")
        XCTAssertEqual(mappedLeaders[1].player.name, "Rickea Jackson")
        XCTAssertEqual(mappedLeaders[2].category, "points")
        XCTAssertEqual(mappedLeaders[2].player.name, "Breanna Stewart")
        XCTAssertEqual(mappedLeaders[2].player.team.name, "Mist")
    }
    
    func testMapLeagueLeaders_WithMissingTeam() throws {
        // Given
        let jsonData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        let leadersDTO = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // Create team DTOs that don't include all teams
        let teamDTOs: [String: TeamDTO] = [
            "3b7f5d56-3586-4d58-98a7-562e267a965e": TeamDTO(
                id: "3b7f5d56-3586-4d58-98a7-562e267a965e",
                name: "Rose",
                abbreviation: "ROS",
                logoURL: nil,
                city: nil,
                conference: nil,
                division: nil,
                wins: nil,
                losses: nil,
                winPercentage: nil
            )
            // Missing Mist team
        ]
        
        // When
        let mappedLeaders = SportradarDTOMapper.mapLeagueLeaders(leadersDTO, teams: teamDTOs)
        
        // Then
        // Should only map leaders with valid teams
        XCTAssertEqual(mappedLeaders.count, 2) // Only Caitlin and Rickea (both on Rose)
        XCTAssertTrue(mappedLeaders.allSatisfy { $0.player.team.id == "3b7f5d56-3586-4d58-98a7-562e267a965e" })
    }
    
    func testMapLeagueLeaders_WithMissingPlayer() throws {
        // Given
        let jsonWithMissingPlayer = """
        {
          "category": "points",
          "leaders": [
            {
              "player": null,
              "player_id": "missing-player",
              "value": 20.0,
              "rank": 1
            },
            {
              "player": {
                "id": "valid-player",
                "full_name": "Valid Player",
                "team": {
                  "id": "team-1",
                  "name": "Team One",
                  "alias": "T1"
                },
                "team_id": "team-1"
              },
              "player_id": "valid-player",
              "value": 18.0,
              "rank": 2
            }
          ]
        }
        """
        let jsonData = jsonWithMissingPlayer.data(using: .utf8)!
        let leadersDTO = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        let teamDTOs: [String: TeamDTO] = [
            "team-1": TeamDTO(
                id: "team-1",
                name: "Team One",
                abbreviation: "T1",
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
        let mappedLeaders = SportradarDTOMapper.mapLeagueLeaders(leadersDTO, teams: teamDTOs)
        
        // Then
        // Should skip leader with missing player
        XCTAssertEqual(mappedLeaders.count, 1)
        XCTAssertEqual(mappedLeaders[0].player.id, "valid-player")
    }
    
    func testMapLeagueLeaders_WithEmptyLeaders() throws {
        // Given
        let emptyJSON = """
        {
          "category": "assists",
          "leaders": []
        }
        """
        let jsonData = emptyJSON.data(using: .utf8)!
        let leadersDTO = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        let teamDTOs: [String: TeamDTO] = [:]
        
        // When
        let mappedLeaders = SportradarDTOMapper.mapLeagueLeaders(leadersDTO, teams: teamDTOs)
        
        // Then
        XCTAssertEqual(mappedLeaders.count, 0)
    }
    
    func testMapLeagueLeaders_WithNilLeaders() throws {
        // Given
        let nilLeadersJSON = """
        {
          "category": "points"
        }
        """
        let jsonData = nilLeadersJSON.data(using: .utf8)!
        let leadersDTO = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        let teamDTOs: [String: TeamDTO] = [:]
        
        // When
        let mappedLeaders = SportradarDTOMapper.mapLeagueLeaders(leadersDTO, teams: teamDTOs)
        
        // Then
        XCTAssertEqual(mappedLeaders.count, 0)
    }
    
    func testMapLeagueLeaders_WithUnknownCategory() throws {
        // Given
        let jsonData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        let leadersDTO = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // Modify category to nil
        let leadersWithNilCategory = SportradarLeagueLeadersDTO(
            category: nil,
            leaders: leadersDTO.leaders
        )
        
        let teamDTOs: [String: TeamDTO] = [
            "3b7f5d56-3586-4d58-98a7-562e267a965e": TeamDTO(
                id: "3b7f5d56-3586-4d58-98a7-562e267a965e",
                name: "Rose",
                abbreviation: "ROS",
                logoURL: nil,
                city: nil,
                conference: nil,
                division: nil,
                wins: nil,
                losses: nil,
                winPercentage: nil
            ),
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
            )
        ]
        
        // When
        let mappedLeaders = SportradarDTOMapper.mapLeagueLeaders(leadersWithNilCategory, teams: teamDTOs)
        
        // Then
        XCTAssertEqual(mappedLeaders.count, 3)
        XCTAssertEqual(mappedLeaders[0].category, "unknown")
    }
    
    func testMapLeagueLeaders_PreservesPlayerData() throws {
        // Given
        let jsonData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        let leadersDTO = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        let teamDTOs: [String: TeamDTO] = [
            "3b7f5d56-3586-4d58-98a7-562e267a965e": TeamDTO(
                id: "3b7f5d56-3586-4d58-98a7-562e267a965e",
                name: "Rose",
                abbreviation: "ROS",
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
        let mappedLeaders = SportradarDTOMapper.mapLeagueLeaders(leadersDTO, teams: teamDTOs)
        
        // Then
        let firstLeader = mappedLeaders[0]
        XCTAssertEqual(firstLeader.player.id, "061f14c8-06ae-4ad1-aa4b-91260b8a4dbb")
        XCTAssertEqual(firstLeader.player.name, "Caitlin Clark")
        XCTAssertEqual(firstLeader.player.position, "G")
        XCTAssertEqual(firstLeader.player.jerseyNumber, 22)
        XCTAssertEqual(firstLeader.player.height, "6'0\"")
        XCTAssertEqual(firstLeader.player.weight, 170)
        XCTAssertEqual(firstLeader.player.age, 22)
        XCTAssertEqual(firstLeader.player.college, "Iowa")
    }
    
    func testMapLeagueLeaders_MultipleCategories() throws {
        // Given
        let pointsData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        let reboundsData = sportradarLeagueLeadersReboundsJSON.data(using: .utf8)!
        
        let pointsLeaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: pointsData)
        let reboundsLeaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: reboundsData)
        
        let teamDTOs: [String: TeamDTO] = [
            "3b7f5d56-3586-4d58-98a7-562e267a965e": TeamDTO(
                id: "3b7f5d56-3586-4d58-98a7-562e267a965e",
                name: "Rose",
                abbreviation: "ROS",
                logoURL: nil,
                city: nil,
                conference: nil,
                division: nil,
                wins: nil,
                losses: nil,
                winPercentage: nil
            ),
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
            "4eeb0d49-106d-4a2d-8917-b703595219dc": TeamDTO(
                id: "4eeb0d49-106d-4a2d-8917-b703595219dc",
                name: "Lunar Owls",
                abbreviation: "LUN",
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
        let pointsMapped = SportradarDTOMapper.mapLeagueLeaders(pointsLeaders, teams: teamDTOs)
        let reboundsMapped = SportradarDTOMapper.mapLeagueLeaders(reboundsLeaders, teams: teamDTOs)
        
        // Then
        XCTAssertEqual(pointsMapped.count, 3)
        XCTAssertTrue(pointsMapped.allSatisfy { $0.category == "points" })
        
        XCTAssertEqual(reboundsMapped.count, 1)
        XCTAssertTrue(reboundsMapped.allSatisfy { $0.category == "rebounds" })
        XCTAssertEqual(reboundsMapped[0].player.name, "Angel Reese")
    }
}
