//
//  MockFullRemoteDataSourceTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

/// Tests for MockFullRemoteDataSource to ensure it correctly implements all protocols
final class MockFullRemoteDataSourceTests: XCTestCase {
    var sut: MockFullRemoteDataSource!
    var testBundle: Bundle!
    
    override func setUp() {
        super.setUp()
        testBundle = Bundle.mockDataBundle
        sut = MockFullRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
    }
    
    override func tearDown() {
        sut = nil
        testBundle = nil
        super.tearDown()
    }
    
    // MARK: - Base Protocol Tests
    
    func testFetchGames_ReturnsData() async throws {
        // When
        let data = try await sut.fetchGames(date: nil)

        // Then
        XCTAssertFalse(data.isEmpty, "Should return game data")
    }
    
    func testFetchPlayers_ReturnsData() async throws {
        // When
        let data = try await sut.fetchPlayers()
        
        // Then
        XCTAssertFalse(data.isEmpty, "Should return player data")
    }
    
    func testFetchTeams_ReturnsData() async throws {
        // When
        let data = try await sut.fetchTeams()
        
        // Then
        XCTAssertFalse(data.isEmpty, "Should return team data")
    }
    
    func testFetchBoxScore_ReturnsData_ForValidGameId() async throws {
        // Given
        // First get a valid game ID from games data
      let gamesData = try await sut.fetchGames(date: nil)
        let decoder = JSONDecoder()
        let gameDTOs = try decoder.decode([GameDTO].self, from: gamesData)
        guard let gameId = gameDTOs.first?.id else {
            XCTFail("No games found in test data")
            return
        }
        
        // When
        let boxScoreData = try await sut.fetchBoxScore(gameId: gameId)
        
        // Then
        XCTAssertFalse(boxScoreData.isEmpty, "Should return box score data")
    }
    
    // MARK: - PlayerProfileDataSource Tests
    
    func testFetchPlayerProfile_SetsTrackingFlag() async throws {
        // Given
        // First get a valid player ID from players data
        let playersData = try await sut.fetchPlayers()
        let decoder = JSONDecoder()
        let playerDTOs = try decoder.decode([PlayerDTO].self, from: playersData)
        guard let playerId = playerDTOs.first?.id else {
            XCTFail("No players found in test data")
            return
        }
        
        // Reset flag
        sut.fetchPlayerProfileCalled = false
        
        // When
        _ = try await sut.fetchPlayerProfile(playerId: playerId)
        
        // Then
        XCTAssertTrue(sut.fetchPlayerProfileCalled, "Should set tracking flag when fetchPlayerProfile is called")
    }
    
    func testFetchPlayerProfile_ReturnsPlayerData() async throws {
        // Given
        let playersData = try await sut.fetchPlayers()
        let decoder = JSONDecoder()
        let playerDTOs = try decoder.decode([PlayerDTO].self, from: playersData)
        guard let playerId = playerDTOs.first?.id else {
            XCTFail("No players found in test data")
            return
        }
        
        // When
        let profileData = try await sut.fetchPlayerProfile(playerId: playerId)
        let profileDTO = try decoder.decode(PlayerDTO.self, from: profileData)
        
        // Then
        XCTAssertEqual(profileDTO.id, playerId, "Should return correct player")
    }
    
    func testFetchPlayerProfile_ThrowsError_ForInvalidPlayerId() async {
        // Given
        let invalidPlayerId = "invalid-player-id"
        
        // When/Then
        do {
            _ = try await sut.fetchPlayerProfile(playerId: invalidPlayerId)
            XCTFail("Should throw error for invalid player ID")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("not found") || error.localizedDescription.contains(invalidPlayerId))
        }
    }
    
    // MARK: - TeamProfileDataSource Tests
    
    func testFetchTeamProfile_SetsTrackingFlag() async throws {
        // Given
        // First get a valid team ID from teams data
        let teamsData = try await sut.fetchTeams()
        let decoder = JSONDecoder()
        let teamDTOs = try decoder.decode([TeamDTO].self, from: teamsData)
        guard let teamId = teamDTOs.first?.id else {
            XCTFail("No teams found in test data")
            return
        }
        
        // Reset flag
        sut.fetchTeamProfileCalled = false
        
        // When
        _ = try await sut.fetchTeamProfile(teamId: teamId)
        
        // Then
        XCTAssertTrue(sut.fetchTeamProfileCalled, "Should set tracking flag when fetchTeamProfile is called")
    }
    
    func testFetchTeamProfile_ReturnsTeamData() async throws {
        // Given
        let teamsData = try await sut.fetchTeams()
        let decoder = JSONDecoder()
        let teamDTOs = try decoder.decode([TeamDTO].self, from: teamsData)
        guard let teamId = teamDTOs.first?.id else {
            XCTFail("No teams found in test data")
            return
        }
        
        // When
        let profileData = try await sut.fetchTeamProfile(teamId: teamId)
        let profileDTO = try decoder.decode(TeamDTO.self, from: profileData)
        
        // Then
        XCTAssertEqual(profileDTO.id, teamId, "Should return correct team")
    }
    
    func testFetchTeamProfile_ThrowsError_ForInvalidTeamId() async {
        // Given
        let invalidTeamId = "invalid-team-id"
        
        // When/Then
        do {
            _ = try await sut.fetchTeamProfile(teamId: invalidTeamId)
            XCTFail("Should throw error for invalid team ID")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("not found") || error.localizedDescription.contains(invalidTeamId))
        }
    }
    
    func testFetchTeamRoster_SetsTrackingFlag() async throws {
        // Given
        // First get a valid team ID from teams data
        let teamsData = try await sut.fetchTeams()
        let decoder = JSONDecoder()
        let teamDTOs = try decoder.decode([TeamDTO].self, from: teamsData)
        guard let teamId = teamDTOs.first?.id else {
            XCTFail("No teams found in test data")
            return
        }
        
        // Reset flag
        sut.fetchTeamRosterCalled = false
        
        // When
        _ = try await sut.fetchTeamRoster(teamId: teamId)
        
        // Then
        XCTAssertTrue(sut.fetchTeamRosterCalled, "Should set tracking flag when fetchTeamRoster is called")
    }
    
    func testFetchTeamRoster_ReturnsPlayersForTeam() async throws {
        // Given
        // Get a team that has players
        let teamsData = try await sut.fetchTeams()
        let playersData = try await sut.fetchPlayers()
        let decoder = JSONDecoder()
        let teamDTOs = try decoder.decode([TeamDTO].self, from: teamsData)
        let playerDTOs = try decoder.decode([PlayerDTO].self, from: playersData)
        
        // Find a team that has players
        guard let teamWithPlayers = teamDTOs.first(where: { team in
            playerDTOs.contains { $0.team.id == team.id }
        }) else {
            XCTSkip("No team with players found in test data")
            return
        }
        
        // When
        let rosterData = try await sut.fetchTeamRoster(teamId: teamWithPlayers.id)
        let rosterDTOs = try decoder.decode([PlayerDTO].self, from: rosterData)
        
        // Then
        XCTAssertFalse(rosterDTOs.isEmpty, "Should return players for team")
        XCTAssertTrue(rosterDTOs.allSatisfy { $0.team.id == teamWithPlayers.id }, "All players should belong to the team")
    }
    
    // MARK: - LeagueDataSource Tests
    
    func testFetchLeagueLeaders_SetsTrackingFlag() async throws {
        // Reset flag
        sut.fetchLeagueLeadersCalled = false
        
        // When
        _ = try await sut.fetchLeagueLeaders()
        
        // Then
        XCTAssertTrue(sut.fetchLeagueLeadersCalled, "Should set tracking flag when fetchLeagueLeaders is called")
    }
    
    func testFetchLeagueLeaders_ReturnsData() async throws {
        // When
        let data = try await sut.fetchLeagueLeaders()
        
        // Then
        XCTAssertFalse(data.isEmpty, "Should return data (even if empty array)")
    }
    
    func testFetchStandings_SetsTrackingFlag() async throws {
        // Reset flag
        sut.fetchStandingsCalled = false
        
        // When
        _ = try await sut.fetchStandings()
        
        // Then
        XCTAssertTrue(sut.fetchStandingsCalled, "Should set tracking flag when fetchStandings is called")
    }
    
    func testFetchStandings_ReturnsData() async throws {
        // When
        let data = try await sut.fetchStandings()
        
        // Then
        XCTAssertFalse(data.isEmpty, "Should return standings data")
    }
}
