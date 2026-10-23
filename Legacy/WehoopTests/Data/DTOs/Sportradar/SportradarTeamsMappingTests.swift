//
//  SportradarTeamsMappingTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class SportradarTeamsMappingTests: XCTestCase {
    
    // MARK: - Sportradar Teams JSON Example
    // This is the actual Sportradar API teams response structure
    let sportradarTeamsJSON = """
    {
      "league": {
        "id": "844ee10a-00c8-4dc1-9c17-52598de2ef47",
        "name": "Unrivaled",
        "alias": "UNRIVALED"
      },
      "teams": [
        {
          "id": "7347fb5a-12db-4554-b1db-85d449395d72",
          "name": "Aaliyah Edwards",
          "alias": "AE"
        },
        {
          "id": "dafb6f71-6e29-4b06-958a-4149c1bba417",
          "name": "Aliyah Boston",
          "alias": "AB"
        },
        {
          "id": "7f58c9e5-e2e5-48bb-ab62-9c9819f07372",
          "name": "Allisha Gray",
          "alias": "AG"
        },
        {
          "id": "72d4c667-924d-4f20-9ec0-24ea40aaa55a",
          "name": "Alyssa Thomas",
          "alias": "AT"
        },
        {
          "id": "e6a6348f-8c9b-49fe-a332-157e1c483a25",
          "name": "Arike Ogunbowale",
          "alias": "AO"
        },
        {
          "id": "828eb47b-7d5f-43a5-bd24-50a553ce86b0",
          "name": "Azurá Stevens",
          "alias": "AS"
        },
        {
          "id": "243c3966-4298-4615-89a4-b06257d11219",
          "name": "Breanna Stewart",
          "alias": "BS"
        },
        {
          "id": "865d71fd-8173-4f06-ba93-fe886dd78330",
          "name": "Breeze",
          "alias": "BRZ"
        },
        {
          "id": "1b7ee316-17b2-4067-b190-c0fe629c546a",
          "name": "Brittney Sykes",
          "alias": "BS"
        },
        {
          "id": "2da44197-ab13-4b75-9470-c1595c1c08b3",
          "name": "Chelsea Gray",
          "alias": "CG"
        },
        {
          "id": "1dedf709-41cc-4fed-8eee-01367647993d",
          "name": "Courtney Williams",
          "alias": "CW"
        },
        {
          "id": "70def231-bbfc-446d-b394-650f1959000e",
          "name": "Dearica Hamby",
          "alias": "DH"
        },
        {
          "id": "3665628c-4b5b-490e-a869-a911e454c4ce",
          "name": "DiJonai Carrington",
          "alias": "DC"
        },
        {
          "id": "56351bfa-e888-400d-ade3-01f551dd33b9",
          "name": "Hive",
          "alias": "HVE"
        },
        {
          "id": "9733425c-1132-48b5-b371-e325cf45f569",
          "name": "Jackie Young",
          "alias": "JY"
        },
        {
          "id": "187b3c8d-6dac-4599-a82e-cbb26361b3d4",
          "name": "Jewell Loyd",
          "alias": "JL"
        },
        {
          "id": "405beda6-4682-4506-83c0-7f0909f08931",
          "name": "Jordin Canada",
          "alias": "JC"
        },
        {
          "id": "0c7150a3-577b-40f3-b5e7-bd74c107993c",
          "name": "Kahleah Copper",
          "alias": "KC"
        },
        {
          "id": "5f70d32b-f1cd-4169-ad07-d8292bd89cbf",
          "name": "Kate Martin",
          "alias": "KM"
        },
        {
          "id": "f705bafc-f431-44ff-923a-512e7d8380f3",
          "name": "Katie Lou Samuelson",
          "alias": "KLS"
        },
        {
          "id": "52a5087b-2d1a-4b8f-9f49-190ccb3c8aac",
          "name": "Kayla McBride",
          "alias": "KM"
        },
        {
          "id": "b1da8619-1db7-4c21-99bb-4c7307e25026",
          "name": "Laces",
          "alias": "LCS"
        },
        {
          "id": "4df28e77-b0ee-4440-aa9f-9f934e61738d",
          "name": "Lexie Hull",
          "alias": "LH"
        },
        {
          "id": "67c22115-2385-458f-8632-a67a025fef55",
          "name": "Lunar Owls",
          "alias": "LNR"
        },
        {
          "id": "2ab4e44e-f543-4507-b68b-4f8a48bbf702",
          "name": "Marina Mabrey",
          "alias": "MM"
        },
        {
          "id": "0780b080-347b-407b-b8d6-fa109ec23908",
          "name": "Mist",
          "alias": "MST"
        },
        {
          "id": "88255955-f6e1-4d8b-bce2-99be5240775e",
          "name": "Napheesa Collier",
          "alias": "NC"
        },
        {
          "id": "c749ce30-8dc9-4b09-af14-e90904b64b1e",
          "name": "Natasha Cloud",
          "alias": "NC"
        },
        {
          "id": "e5be75a6-cd4a-41d3-b3c3-638506ced50a",
          "name": "Phantom",
          "alias": "PHA"
        },
        {
          "id": "04936db0-c019-47b1-ae9a-300268212711",
          "name": "Rae Burrell",
          "alias": "RB"
        },
        {
          "id": "f742d6ca-b724-40d0-bcd8-ad6c1deff885",
          "name": "Rhyne Howard",
          "alias": "RH"
        },
        {
          "id": "ecf4435c-8414-49c5-b68e-8a4f58dfb8d8",
          "name": "Rickea Jackson",
          "alias": "RJ"
        },
        {
          "id": "3b7f5d56-3586-4d58-98a7-562e267a965e",
          "name": "Rose",
          "alias": "ROS"
        },
        {
          "id": "82c763e7-e402-44c8-933f-47ba5136a8a1",
          "name": "Satou Sabally",
          "alias": "SS"
        },
        {
          "id": "c1ecd7cd-13eb-467f-9979-053b65001286",
          "name": "Shakira Austin",
          "alias": "SA"
        },
        {
          "id": "531f9c45-b1fb-4713-8880-dc208f58ec12",
          "name": "Skylar Diggins-Smith",
          "alias": "SDS"
        },
        {
          "id": "64577946-68a2-4339-801d-7784df45cf78",
          "name": "TBD",
          "alias": "TBD",
          "market": "Team"
        },
        {
          "id": "75b77616-19c9-463a-9a5c-44b50d3582ce",
          "name": "Tiffany Hayes",
          "alias": "TH"
        },
        {
          "id": "4eeb0d49-106d-4a2d-8917-b703595219dc",
          "name": "Vinyl",
          "alias": "VNL"
        }
      ],
      "_comment": "Generation started @ 2025-12-23 16:29:22 +0000 ended @ 2025-12-23 16:29:22 +0000"
    }
    """
    
    // MARK: - Decode Tests
    
    func testDecodeSportradarTeamsResponse() throws {
        // Given
        let jsonData = sportradarTeamsJSON.data(using: .utf8)!
        
        // When
        let response = try JSONDecoder().decode(SportradarTeamsResponseDTO.self, from: jsonData)
        
        // Then
        XCTAssertNotNil(response.league)
        XCTAssertEqual(response.league?.name, "Unrivaled")
        XCTAssertEqual(response.league?.alias, "UNRIVALED")
        XCTAssertEqual(response.teams.count, 40)
        
        // Verify first team
        XCTAssertEqual(response.teams[0].name, "Aaliyah Edwards")
        XCTAssertEqual(response.teams[0].alias, "AE")
        
        // Verify specific teams by finding them (since order may vary)
        let lunarOwls = response.teams.first { $0.name == "Lunar Owls" }
        XCTAssertNotNil(lunarOwls)
        XCTAssertEqual(lunarOwls?.alias, "LNR")
        
        let mist = response.teams.first { $0.name == "Mist" }
        XCTAssertNotNil(mist)
        XCTAssertEqual(mist?.alias, "MST")
        
        let tbd = response.teams.first { $0.name == "TBD" }
        XCTAssertNotNil(tbd)
        XCTAssertEqual(tbd?.market, "Team")
    }
    
    func testDecodeTeamWithMarket() throws {
        // Given
        let jsonData = sportradarTeamsJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(SportradarTeamsResponseDTO.self, from: jsonData)
        
        // When
        let tbdTeam = response.teams.first { $0.name == "TBD" }
        
        // Then
        XCTAssertNotNil(tbdTeam)
        XCTAssertEqual(tbdTeam?.market, "Team")
    }
    
    // MARK: - Mapping Tests
    
    func testMapTeamsResponse() throws {
        // Given
        let jsonData = sportradarTeamsJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(SportradarTeamsResponseDTO.self, from: jsonData)
        
        // When
        let teamDTOs = SportradarDTOMapper.mapTeams(response)
        
        // Then
        XCTAssertEqual(teamDTOs.count, 39)
        XCTAssertEqual(teamDTOs[0].id, "7347fb5a-12db-4554-b1db-85d449395d72")
        XCTAssertEqual(teamDTOs[0].name, "Aaliyah Edwards")
        XCTAssertEqual(teamDTOs[0].abbreviation, "AE")
        
        // Verify specific teams by finding them
        let lunarOwls = teamDTOs.first { $0.name == "Lunar Owls" }
        XCTAssertNotNil(lunarOwls)
        XCTAssertEqual(lunarOwls?.abbreviation, "LNR")
        
        let mist = teamDTOs.first { $0.name == "Mist" }
        XCTAssertNotNil(mist)
        XCTAssertEqual(mist?.abbreviation, "MST")
    }
    
    func testMapTeamWithMarket() throws {
        // Given
        let jsonData = sportradarTeamsJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(SportradarTeamsResponseDTO.self, from: jsonData)
        let tbdTeam = response.teams.first { $0.name == "TBD" }!
        
        // When
        let teamDTO = SportradarDTOMapper.mapTeam(tbdTeam)
        
        // Then
        XCTAssertEqual(teamDTO.name, "TBD")
        XCTAssertEqual(teamDTO.abbreviation, "TBD")
        XCTAssertEqual(teamDTO.city, "Team")
    }
    
    func testMapTeamToDomain() throws {
        // Given
        let jsonData = sportradarTeamsJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(SportradarTeamsResponseDTO.self, from: jsonData)
        let mistTeam = response.teams.first { $0.name == "Mist" }!
        let teamDTO = SportradarDTOMapper.mapTeam(mistTeam)
        
        // When
        let team = try teamDTO.toDomain()
        
        // Then
        XCTAssertEqual(team.id, "0780b080-347b-407b-b8d6-fa109ec23908")
        XCTAssertEqual(team.name, "Mist")
        XCTAssertEqual(team.abbreviation, "MST")
    }
    
    func testMapTeamWithoutAlias() throws {
        // Given - Team without alias should use first 3 characters of name
        let teamJSON = """
        {
          "id": "test-id",
          "name": "Test Team Name"
        }
        """
        let jsonData = teamJSON.data(using: .utf8)!
        let sportradarTeam = try JSONDecoder().decode(SportradarTeamDTO.self, from: jsonData)
        
        // When
        let teamDTO = sportradarTeam.toTeamDTO()
        
        // Then
        XCTAssertEqual(teamDTO.abbreviation, "TES", "Should use first 3 characters when alias is missing")
    }
    
    func testMapTeamsArray() throws {
        // Given
        let jsonData = sportradarTeamsJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(SportradarTeamsResponseDTO.self, from: jsonData)
        
        // When
        let teamDTOs = SportradarDTOMapper.mapTeams(response.teams)
        
        // Then
        XCTAssertEqual(teamDTOs.count, 40)
        XCTAssertEqual(teamDTOs[0].name, "Aaliyah Edwards")
        
        // Verify specific teams by finding them
        let lunarOwls = teamDTOs.first { $0.name == "Lunar Owls" }
        XCTAssertNotNil(lunarOwls)
    }
    
    // MARK: - Edge Cases
    
    func testMapEmptyTeamsArray() throws {
        // Given
        let emptyResponse = SportradarTeamsResponseDTO(
            league: nil,
            teams: [],
            comment: nil
        )
        
        // When
        let teamDTOs = SportradarDTOMapper.mapTeams(emptyResponse)
        
        // Then
        XCTAssertEqual(teamDTOs.count, 0)
    }
    
    func testMapTeamsResponseWithEmptyArray() throws {
        // Given
        let emptyResponse = SportradarTeamsResponseDTO(
            league: SportradarLeagueDTO(id: "league-1", name: "Test League", alias: "TEST"),
            teams: [],
            comment: nil
        )
        
        // When
        let teamDTOs = SportradarDTOMapper.mapTeams(emptyResponse)
        
        // Then
        XCTAssertEqual(teamDTOs.count, 0)
        XCTAssertNotNil(emptyResponse.league)
    }
    
    func testMapTeamWithAllOptionalFields() throws {
        // Given - Team with optional fields populated
        // Note: Since SportradarTeamDTO doesn't have CodingKeys, we'll test with fields that match property names
        let sportradarTeam = SportradarTeamDTO(
            id: "full-team-id",
            name: "Full Team",
            alias: "FT",
            market: "Test City",
            conference: "East",
            division: "North",
            wins: 10,
            losses: 5,
            winPercentage: 0.667,
            logo: "https://example.com/logo.png",
            founded: 2020,
            venue: nil
        )
        
        // When
        let teamDTO = SportradarDTOMapper.mapTeam(sportradarTeam)
        
        // Then
        XCTAssertEqual(teamDTO.id, "full-team-id")
        XCTAssertEqual(teamDTO.name, "Full Team")
        XCTAssertEqual(teamDTO.abbreviation, "FT")
        XCTAssertEqual(teamDTO.city, "Test City")
        XCTAssertEqual(teamDTO.conference, "East")
        XCTAssertEqual(teamDTO.division, "North")
        XCTAssertEqual(teamDTO.wins, 10)
        XCTAssertEqual(teamDTO.losses, 5)
        XCTAssertEqual(teamDTO.winPercentage, 0.667)
        XCTAssertEqual(teamDTO.logoURL, "https://example.com/logo.png")
    }
}
