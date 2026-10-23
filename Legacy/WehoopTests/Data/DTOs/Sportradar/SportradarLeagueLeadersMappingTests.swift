//
//  SportradarLeagueLeadersMappingTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

@MainActor
final class SportradarLeagueLeadersMappingTests: XCTestCase {
  // MARK: - Sportradar League Leaders JSON Example
  // Updated to match current API structure with categories array

  let sportradarLeagueLeadersJSON = """
    {
      "season": {
        "id": "season-2025",
        "year": 2025,
        "type": "REG",
        "name": "Regular Season"
      },
      "id": "844ee10a-00c8-4dc1-9c17-52598de2ef47",
      "name": "Unrivaled",
      "alias": "UNRIVALED",
      "categories": [
        {
          "name": "points",
          "type": "average",
          "ranks": [
            {
              "rank": 1,
              "tied": false,
              "score": 28.5,
              "player": {
                "id": "061f14c8-06ae-4ad1-aa4b-91260b8a4dbb",
                "full_name": "Caitlin Clark",
                "first_name": "Caitlin",
                "last_name": "Clark",
                "position": "G",
                "jersey_number": "22"
              },
              "teams": [
                {
                  "id": "3b7f5d56-3586-4d58-98a7-562e267a965e",
                  "name": "Rose"
                }
              ]
            },
            {
              "rank": 2,
              "tied": false,
              "score": 24.2,
              "player": {
                "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                "full_name": "Rickea Jackson",
                "first_name": "Rickea",
                "last_name": "Jackson",
                "position": "F",
                "jersey_number": "4"
              },
              "teams": [
                {
                  "id": "3b7f5d56-3586-4d58-98a7-562e267a965e",
                  "name": "Rose"
                }
              ]
            },
            {
              "rank": 3,
              "tied": false,
              "score": 22.8,
              "player": {
                "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
                "full_name": "Breanna Stewart",
                "first_name": "Breanna",
                "last_name": "Stewart",
                "position": "F",
                "jersey_number": "30"
              },
              "teams": [
                {
                  "id": "0780b080-347b-407b-b8d6-fa109ec23908",
                  "name": "Mist"
                }
              ]
            }
          ]
        }
      ]
    }
    """

  let sportradarLeagueLeadersReboundsJSON = """
    {
      "season": {
        "id": "season-2025",
        "year": 2025,
        "type": "REG",
        "name": "Regular Season"
      },
      "id": "844ee10a-00c8-4dc1-9c17-52598de2ef47",
      "name": "Unrivaled",
      "alias": "UNRIVALED",
      "categories": [
        {
          "name": "rebounds",
          "type": "average",
          "ranks": [
            {
              "rank": 1,
              "tied": false,
              "score": 12.3,
              "player": {
                "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
                "full_name": "Angel Reese",
                "first_name": "Angel",
                "last_name": "Reese",
                "position": "F",
                "jersey_number": "10"
              },
              "teams": [
                {
                  "id": "4eeb0d49-106d-4a2d-8917-b703595219dc",
                  "name": "Lunar Owls"
                }
              ]
            }
          ]
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
        XCTAssertNotNil(leaders.categories)
        XCTAssertEqual(leaders.categories?.count, 1)
        XCTAssertEqual(leaders.categories?[0].name, "points")
        XCTAssertNotNil(leaders.season)
        XCTAssertEqual(leaders.name, "Unrivaled")
    }
    
    func testDecodeLeaderEntry() throws {
        // Given
        let jsonData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // When
        let firstCategory = leaders.categories![0]
        let firstRank = firstCategory.ranks![0]
        
        // Then
        XCTAssertNotNil(firstRank.player)
        XCTAssertEqual(firstRank.rank, 1)
        XCTAssertEqual(firstRank.score, 28.5)
        XCTAssertEqual(firstRank.tied, false)
    }
    
    func testDecodePlayerInLeader() throws {
        // Given
        let jsonData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        let firstCategory = leaders.categories![0]
        let firstRank = firstCategory.ranks![0]
        
        // When
        let player = firstRank.player!
        
        // Then
        XCTAssertEqual(player.id, "061f14c8-06ae-4ad1-aa4b-91260b8a4dbb")
        XCTAssertEqual(player.fullName, "Caitlin Clark")
        XCTAssertEqual(player.firstName, "Caitlin")
        XCTAssertEqual(player.lastName, "Clark")
        XCTAssertEqual(player.position, "G")
        XCTAssertEqual(player.jerseyNumber, "22")
    }
    
    func testDecodeTeamReferenceInLeader() throws {
        // Given
        let jsonData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        let firstCategory = leaders.categories![0]
        let firstRank = firstCategory.ranks![0]
        
        // When
        let teams = firstRank.teams!
        
        // Then
        XCTAssertEqual(teams.count, 1)
        XCTAssertEqual(teams[0].id, "3b7f5d56-3586-4d58-98a7-562e267a965e")
        XCTAssertEqual(teams[0].name, "Rose")
    }
    
    func testDecodeMultipleLeaders() throws {
        // Given
        let jsonData = sportradarLeagueLeadersJSON.data(using: .utf8)!
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // When
        let rankList = leaders.categories![0].ranks!
        
        // Then
        XCTAssertEqual(rankList.count, 3)
        
        // Verify first leader
        XCTAssertEqual(rankList[0].rank, 1)
        XCTAssertEqual(rankList[0].score, 28.5)
        XCTAssertEqual(rankList[0].player?.fullName, "Caitlin Clark")
        
        // Verify second leader
        XCTAssertEqual(rankList[1].rank, 2)
        XCTAssertEqual(rankList[1].score, 24.2)
        XCTAssertEqual(rankList[1].player?.fullName, "Rickea Jackson")
        
        // Verify third leader
        XCTAssertEqual(rankList[2].rank, 3)
        XCTAssertEqual(rankList[2].score, 22.8)
        XCTAssertEqual(rankList[2].player?.fullName, "Breanna Stewart")
    }
    
    func testDecodeDifferentCategory() throws {
        // Given
        let jsonData = sportradarLeagueLeadersReboundsJSON.data(using: .utf8)!
        
        // When
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // Then
        XCTAssertEqual(leaders.categories?.count, 1)
        XCTAssertEqual(leaders.categories?[0].name, "rebounds")
        XCTAssertEqual(leaders.categories?[0].ranks?.count, 1)
        XCTAssertEqual(leaders.categories?[0].ranks?[0].player?.fullName, "Angel Reese")
        XCTAssertEqual(leaders.categories?[0].ranks?[0].score, 12.3)
    }
    
    func testDecodeEmptyLeaders() throws {
        // Given
        let emptyJSON = """
        {
          "id": "test-league",
          "name": "Test League",
          "alias": "TEST",
          "categories": [
            {
              "name": "assists",
              "ranks": []
            }
          ]
        }
        """
        let jsonData = emptyJSON.data(using: .utf8)!
        
        // When
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // Then
        XCTAssertEqual(leaders.categories?.count, 1)
        XCTAssertEqual(leaders.categories?[0].name, "assists")
        XCTAssertNotNil(leaders.categories?[0].ranks)
        XCTAssertEqual(leaders.categories?[0].ranks?.count, 0)
    }
    
    func testDecodeMissingCategory() throws {
        // Given
        let missingCategoryJSON = """
        {
          "id": "test-league",
          "categories": [
            {
              "ranks": [
                {
                  "rank": 1,
                  "score": 10.0,
                  "player": {
                    "id": "test-id",
                    "full_name": "Test Player"
                  }
                }
              ]
            }
          ]
        }
        """
        let jsonData = missingCategoryJSON.data(using: .utf8)!
        
        // When
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // Then
        XCTAssertNotNil(leaders.categories)
        XCTAssertEqual(leaders.categories?.count, 1)
        XCTAssertNil(leaders.categories?[0].name)
        XCTAssertEqual(leaders.categories?[0].ranks?.count, 1)
    }
    
    func testDecodeMissingCategories() throws {
        // Given
        let missingCategoriesJSON = """
        {
          "id": "test-league",
          "name": "Test League"
        }
        """
        let jsonData = missingCategoriesJSON.data(using: .utf8)!
        
        // When
        let leaders = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        // Then
        XCTAssertEqual(leaders.name, "Test League")
        XCTAssertNil(leaders.categories)
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
          "id": "test-league",
          "categories": [
            {
              "name": "points",
              "ranks": [
                {
                  "rank": 1,
                  "score": 20.0,
                  "player": null,
                  "teams": [
                    {
                      "id": "team-1",
                      "name": "Team One"
                    }
                  ]
                },
                {
                  "rank": 2,
                  "score": 18.0,
                  "player": {
                    "id": "valid-player",
                    "full_name": "Valid Player"
                  },
                  "teams": [
                    {
                      "id": "team-1",
                      "name": "Team One"
                    }
                  ]
                }
              ]
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
    
    func testMapLeagueLeaders_WithEmptyCategories() throws {
        // Given
        let emptyJSON = """
        {
          "id": "test-league",
          "categories": [
            {
              "name": "assists",
              "ranks": []
            }
          ]
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
    
    func testMapLeagueLeaders_WithNilCategories() throws {
        // Given
        let nilCategoriesJSON = """
        {
          "id": "test-league",
          "name": "Test League"
        }
        """
        let jsonData = nilCategoriesJSON.data(using: .utf8)!
        let leadersDTO = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        let teamDTOs: [String: TeamDTO] = [:]
        
        // When
        let mappedLeaders = SportradarDTOMapper.mapLeagueLeaders(leadersDTO, teams: teamDTOs)
        
        // Then
        XCTAssertEqual(mappedLeaders.count, 0)
    }
    
    func testMapLeagueLeaders_WithUnknownCategory() throws {
        // Given - Category with nil name
        let nilCategoryNameJSON = """
        {
          "id": "test-league",
          "categories": [
            {
              "ranks": [
                {
                  "rank": 1,
                  "score": 25.5,
                  "player": {
                    "id": "player-1",
                    "full_name": "Test Player"
                  },
                  "teams": [
                    {
                      "id": "team-1",
                      "name": "Test Team"
                    }
                  ]
                }
              ]
            }
          ]
        }
        """
        let jsonData = nilCategoryNameJSON.data(using: .utf8)!
        let leadersDTO = try JSONDecoder().decode(SportradarLeagueLeadersDTO.self, from: jsonData)
        
        let teamDTOs: [String: TeamDTO] = [
            "team-1": TeamDTO(
                id: "team-1",
                name: "Test Team",
                abbreviation: "TT",
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
        // Should skip categories with no name
        XCTAssertEqual(mappedLeaders.count, 0)
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
        // Note: height/weight/age/college not in the minimal JSON structure above
    }
    
    func testMapLeagueLeaders_MultipleCategories() throws {
        // Given
        let multiCategoryJSON = """
        {
          "id": "test-league",
          "categories": [
            {
              "name": "points",
              "ranks": [
                {
                  "rank": 1,
                  "score": 28.5,
                  "player": {
                    "id": "player-1",
                    "full_name": "Top Scorer"
                  },
                  "teams": [
                    {
                      "id": "team-1",
                      "name": "Team One"
                    }
                  ]
                }
              ]
            },
            {
              "name": "rebounds",
              "ranks": [
                {
                  "rank": 1,
                  "score": 12.3,
                  "player": {
                    "id": "player-2",
                    "full_name": "Top Rebounder"
                  },
                  "teams": [
                    {
                      "id": "team-2",
                      "name": "Team Two"
                    }
                  ]
                }
              ]
            }
          ]
        }
        """
        let jsonData = multiCategoryJSON.data(using: .utf8)!
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
            ),
            "team-2": TeamDTO(
                id: "team-2",
                name: "Team Two",
                abbreviation: "T2",
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
        XCTAssertEqual(mappedLeaders.count, 2)
        
        // Check points category
        let pointsLeader = mappedLeaders.first { $0.category == "points" }
        XCTAssertNotNil(pointsLeader)
        XCTAssertEqual(pointsLeader?.player.name, "Top Scorer")
        
        // Check rebounds category
        let reboundsLeader = mappedLeaders.first { $0.category == "rebounds" }
        XCTAssertNotNil(reboundsLeader)
        XCTAssertEqual(reboundsLeader?.player.name, "Top Rebounder")
    }

}
