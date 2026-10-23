//
//  SportradarLeagueHierarchyMappingTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class SportradarLeagueHierarchyMappingTests: XCTestCase {
    // MARK: - Sportradar League Hierarchy JSON Example
    let sportradarLeagueHierarchyJSON = """
    {
      "league": {
        "id": "844ee10a-00c8-4dc1-9c17-52598de2ef47",
        "name": "Unrivaled",
        "alias": "UNRIVALED"
      },
      "conferences": [
        {
          "id": "56089804-dbb3-4621-96eb-ec520ab26988",
          "name": "Unrivaled",
          "alias": "UNRIVALED",
          "teams": [
            {
              "id": "0780b080-347b-407b-b8d6-fa109ec23908",
              "name": "Mist",
              "alias": "MST",
              "franchise_id": "a730984c-2f67-4d33-aabf-dcd9d45b2e2b",
              "founded": 2025,
              "sponsor": "VistaPrint",
              "team_colors": [
                {
                  "type": "secondary",
                  "hex_color": "#a3d3e7",
                  "rgb_color": {
                    "red": 163,
                    "green": 211,
                    "blue": 231
                  }
                },
                {
                  "type": "primary",
                  "hex_color": "#083860",
                  "rgb_color": {
                    "red": 8,
                    "green": 56,
                    "blue": 96
                  }
                }
              ],
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
              }
            },
            {
              "id": "3b7f5d56-3586-4d58-98a7-562e267a965e",
              "name": "Rose",
              "alias": "ROS",
              "franchise_id": "05f487c9-1fe6-4253-a49a-e7870662f445",
              "founded": 2025,
              "championships_won": 1,
              "championship_seasons": "2025",
              "playoff_appearances": 1,
              "team_colors": [
                {
                  "type": "secondary",
                  "hex_color": "#dda493",
                  "rgb_color": {
                    "red": 221,
                    "green": 164,
                    "blue": 147
                  }
                },
                {
                  "type": "primary",
                  "hex_color": "#1b5751",
                  "rgb_color": {
                    "red": 27,
                    "green": 87,
                    "blue": 81
                  }
                }
              ],
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
              }
            },
            {
              "id": "4eeb0d49-106d-4a2d-8917-b703595219dc",
              "name": "Vinyl",
              "alias": "VNL",
              "franchise_id": "64d73b11-82a2-4093-a5ce-0586e994725e",
              "founded": 2025,
              "sponsor": "iHeart Radio",
              "playoff_appearances": 1,
              "team_colors": [
                {
                  "type": "primary",
                  "hex_color": "#820533",
                  "rgb_color": {
                    "red": 130,
                    "green": 5,
                    "blue": 51
                  }
                },
                {
                  "type": "secondary",
                  "hex_color": "#1e9cbf",
                  "rgb_color": {
                    "red": 30,
                    "green": 156,
                    "blue": 191
                  }
                }
              ],
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
              }
            }
          ]
        }
      ]
    }
    """
    
    // MARK: - Decoding Tests
    
    func testDecodeSportradarLeagueHierarchy() throws {
        // Given
        let jsonData = sportradarLeagueHierarchyJSON.data(using: .utf8)!
        
        // When
        let hierarchy = try JSONDecoder().decode(SportradarLeagueHierarchyDTO.self, from: jsonData)
        
        // Then
        XCTAssertNotNil(hierarchy.league)
        XCTAssertEqual(hierarchy.league?.id, "844ee10a-00c8-4dc1-9c17-52598de2ef47")
        XCTAssertEqual(hierarchy.league?.name, "Unrivaled")
        XCTAssertEqual(hierarchy.conferences.count, 1)
    }
    
    func testDecodeConference() throws {
        // Given
        let jsonData = sportradarLeagueHierarchyJSON.data(using: .utf8)!
        let hierarchy = try JSONDecoder().decode(SportradarLeagueHierarchyDTO.self, from: jsonData)
        
        // When
        let conference = hierarchy.conferences[0]
        
        // Then
        XCTAssertEqual(conference.id, "56089804-dbb3-4621-96eb-ec520ab26988")
        XCTAssertEqual(conference.name, "Unrivaled")
        XCTAssertEqual(conference.alias, "UNRIVALED")
        XCTAssertEqual(conference.teams.count, 3)
    }
    
    func testDecodeTeamInHierarchy() throws {
        // Given
        let jsonData = sportradarLeagueHierarchyJSON.data(using: .utf8)!
        let hierarchy = try JSONDecoder().decode(SportradarLeagueHierarchyDTO.self, from: jsonData)
        
        // When
        let conference = hierarchy.conferences[0]
        let firstTeam = conference.teams[0]
        
        // Then
        XCTAssertEqual(firstTeam.id, "0780b080-347b-407b-b8d6-fa109ec23908")
        XCTAssertEqual(firstTeam.name, "Mist")
        XCTAssertEqual(firstTeam.alias, "MST")
        XCTAssertEqual(firstTeam.franchiseId, "a730984c-2f67-4d33-aabf-dcd9d45b2e2b")
        XCTAssertEqual(firstTeam.founded, 2025)
        XCTAssertEqual(firstTeam.sponsor, "VistaPrint")
        XCTAssertNotNil(firstTeam.venue)
        XCTAssertNotNil(firstTeam.teamColors)
    }
    
    func testDecodeTeamColors() throws {
        // Given
        let jsonData = sportradarLeagueHierarchyJSON.data(using: .utf8)!
        let hierarchy = try JSONDecoder().decode(SportradarLeagueHierarchyDTO.self, from: jsonData)
        
        // When
        let conference = hierarchy.conferences[0]
        let firstTeam = conference.teams[0]
        let teamColors = firstTeam.teamColors!
        
        // Then
        XCTAssertEqual(teamColors.count, 2)
        
        let primaryColor = teamColors.first { $0.type == "primary" }
        let secondaryColor = teamColors.first { $0.type == "secondary" }
        
        XCTAssertNotNil(primaryColor)
        XCTAssertNotNil(secondaryColor)
        XCTAssertEqual(primaryColor?.hexColor, "#083860")
        XCTAssertEqual(secondaryColor?.hexColor, "#a3d3e7")
        
        XCTAssertNotNil(primaryColor?.rgbColor)
        XCTAssertEqual(primaryColor?.rgbColor?.red, 8)
        XCTAssertEqual(primaryColor?.rgbColor?.green, 56)
        XCTAssertEqual(primaryColor?.rgbColor?.blue, 96)
    }
    
    func testDecodeTeamVenue() throws {
        // Given
        let jsonData = sportradarLeagueHierarchyJSON.data(using: .utf8)!
        let hierarchy = try JSONDecoder().decode(SportradarLeagueHierarchyDTO.self, from: jsonData)
        
        // When
        let conference = hierarchy.conferences[0]
        let firstTeam = conference.teams[0]
        let venue = firstTeam.venue!
        
        // Then
        XCTAssertEqual(venue.id, "67e49419-cb04-4ce0-ab33-ae42af8d8634")
        XCTAssertEqual(venue.name, "Sephora Arena")
        XCTAssertEqual(venue.capacity, 850)
        XCTAssertEqual(venue.city, "Medley")
        XCTAssertEqual(venue.state, "FL")
        XCTAssertEqual(venue.country, "USA")
        XCTAssertNotNil(venue.location)
        XCTAssertEqual(venue.location?.lat, "25.842035")
        XCTAssertEqual(venue.location?.lng, "-80.317192")
    }
    
    func testDecodeTeamChampionships() throws {
        // Given
        let jsonData = sportradarLeagueHierarchyJSON.data(using: .utf8)!
        let hierarchy = try JSONDecoder().decode(SportradarLeagueHierarchyDTO.self, from: jsonData)
        
        // When
        let conference = hierarchy.conferences[0]
        let roseTeam = conference.teams.first { $0.name == "Rose" }!
        
        // Then
        XCTAssertEqual(roseTeam.championshipsWon, 1)
        XCTAssertEqual(roseTeam.championshipSeasons, "2025")
        XCTAssertEqual(roseTeam.playoffAppearances, 1)
    }
    
    // MARK: - Mapping Tests
    
    func testMapHierarchyToTeamDTOs() throws {
        // Given
        let jsonData = sportradarLeagueHierarchyJSON.data(using: .utf8)!
        let hierarchy = try JSONDecoder().decode(SportradarLeagueHierarchyDTO.self, from: jsonData)
        
        // When
        let teamDTOs = hierarchy.toTeamDTOs()
        
        // Then
        XCTAssertEqual(teamDTOs.count, 3)
        
        let mistTeam = teamDTOs.first { $0.id == "0780b080-347b-407b-b8d6-fa109ec23908" }!
        XCTAssertEqual(mistTeam.name, "Mist")
        XCTAssertEqual(mistTeam.abbreviation, "MST")
        XCTAssertEqual(mistTeam.conference, "Unrivaled")
        XCTAssertEqual(mistTeam.city, "Medley")
        
        let roseTeam = teamDTOs.first { $0.id == "3b7f5d56-3586-4d58-98a7-562e267a965e" }!
        XCTAssertEqual(roseTeam.name, "Rose")
        XCTAssertEqual(roseTeam.abbreviation, "ROS")
    }
    
    func testMapTeamToTeamDTO_WithConference() throws {
        // Given
        let jsonData = sportradarLeagueHierarchyJSON.data(using: .utf8)!
        let hierarchy = try JSONDecoder().decode(SportradarLeagueHierarchyDTO.self, from: jsonData)
        let conference = hierarchy.conferences[0]
        let team = conference.teams[0]
        
        // When
        let teamDTO = team.toTeamDTO(conference: conference.name)
        
        // Then
        XCTAssertEqual(teamDTO.id, team.id)
        XCTAssertEqual(teamDTO.name, team.name)
        XCTAssertEqual(teamDTO.abbreviation, team.alias)
        XCTAssertEqual(teamDTO.conference, conference.name)
        XCTAssertEqual(teamDTO.city, team.venue?.city)
    }
    
    func testMapTeamToTeamDTO_WithoutAlias() throws {
        // Given
        let teamJSON = """
        {
          "id": "test-id",
          "name": "Test Team",
          "franchise_id": "test-franchise",
          "team_colors": [],
          "venue": {
            "id": "venue-id",
            "name": "Test Venue",
            "city": "Test City",
            "state": "CA",
            "country": "USA"
          }
        }
        """
        let teamData = teamJSON.data(using: .utf8)!
        let team = try JSONDecoder().decode(SportradarHierarchyTeamDTO.self, from: teamData)
        
        // When
        let teamDTO = team.toTeamDTO(conference: "Test Conference")
        
        // Then
        XCTAssertEqual(teamDTO.abbreviation, "TES") // Should use first 3 letters of name
    }
    
    func testMapMultipleConferences() throws {
        // Given
        let multipleConferencesJSON = """
        {
          "league": {
            "id": "test-league",
            "name": "Test League",
            "alias": "TEST"
          },
          "conferences": [
            {
              "id": "conf-1",
              "name": "Eastern",
              "alias": "EAST",
              "teams": [
                {
                  "id": "team-1",
                  "name": "Team One",
                  "alias": "T1",
                  "franchise_id": "franchise-1",
                  "team_colors": [],
                  "venue": {
                    "id": "venue-1",
                    "name": "Venue One",
                    "city": "City One",
                    "state": "NY",
                    "country": "USA"
                  }
                }
              ]
            },
            {
              "id": "conf-2",
              "name": "Western",
              "alias": "WEST",
              "teams": [
                {
                  "id": "team-2",
                  "name": "Team Two",
                  "alias": "T2",
                  "franchise_id": "franchise-2",
                  "team_colors": [],
                  "venue": {
                    "id": "venue-2",
                    "name": "Venue Two",
                    "city": "City Two",
                    "state": "CA",
                    "country": "USA"
                  }
                }
              ]
            }
          ]
        }
        """
        
        let jsonData = multipleConferencesJSON.data(using: .utf8)!
        let hierarchy = try JSONDecoder().decode(SportradarLeagueHierarchyDTO.self, from: jsonData)
        
        // When
        let teamDTOs = hierarchy.toTeamDTOs()
        
        // Then
        XCTAssertEqual(teamDTOs.count, 2)
        
        let easternTeam = teamDTOs.first { $0.id == "team-1" }!
        let westernTeam = teamDTOs.first { $0.id == "team-2" }!
        
        XCTAssertEqual(easternTeam.conference, "Eastern")
        XCTAssertEqual(westernTeam.conference, "Western")
    }
}
