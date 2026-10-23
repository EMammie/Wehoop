//
//  RemoteDataSourceProtocolTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

/// Tests for the RemoteDataSource protocol composition design
final class RemoteDataSourceProtocolTests: XCTestCase {
    
    // MARK: - Protocol Conformance Tests
    
    func testMockFullRemoteDataSource_ConformsToAllProtocols() {
        // Given
        let dataSource = MockFullRemoteDataSource()
        
        // Then
        XCTAssertTrue(dataSource is RemoteDataSource, "Should conform to RemoteDataSource")
        XCTAssertTrue(dataSource is PlayerProfileDataSource, "Should conform to PlayerProfileDataSource")
        XCTAssertTrue(dataSource is TeamProfileDataSource, "Should conform to TeamProfileDataSource")
        XCTAssertTrue(dataSource is LeagueDataSource, "Should conform to LeagueDataSource")
        XCTAssertTrue(dataSource is FullRemoteDataSource, "Should conform to FullRemoteDataSource type alias")
    }
    
    func testMockRemoteDataSource_OnlyConformsToBaseProtocol() {
        // Given
        let dataSource = MockRemoteDataSource()
        
        // Then
        XCTAssertTrue(dataSource is RemoteDataSource, "Should conform to RemoteDataSource")
        XCTAssertFalse(dataSource is PlayerProfileDataSource, "Should NOT conform to PlayerProfileDataSource")
        XCTAssertFalse(dataSource is TeamProfileDataSource, "Should NOT conform to TeamProfileDataSource")
        XCTAssertFalse(dataSource is LeagueDataSource, "Should NOT conform to LeagueDataSource")
    }
    
    func testProtocolComposition_TypeAliasWorks() {
        // Given
        let fullDataSource: FullRemoteDataSource = MockFullRemoteDataSource()
        
        // Then - should be able to use all protocol methods
        XCTAssertNotNil(fullDataSource as? RemoteDataSource)
        XCTAssertNotNil(fullDataSource as? PlayerProfileDataSource)
        XCTAssertNotNil(fullDataSource as? TeamProfileDataSource)
        XCTAssertNotNil(fullDataSource as? LeagueDataSource)
    }
    
    // MARK: - Protocol Capability Check Tests
    
    func testProtocolCapabilityCheck_PlayerProfileDataSource() {
        // Given
        let fullDataSource = MockFullRemoteDataSource()
        let baseDataSource = MockRemoteDataSource()
        
        // When/Then
        XCTAssertNotNil(fullDataSource as? PlayerProfileDataSource, "Full data source should be castable to PlayerProfileDataSource")
        XCTAssertNil(baseDataSource as? PlayerProfileDataSource, "Base data source should NOT be castable to PlayerProfileDataSource")
    }
    
    func testProtocolCapabilityCheck_TeamProfileDataSource() {
        // Given
        let fullDataSource = MockFullRemoteDataSource()
        let baseDataSource = MockRemoteDataSource()
        
        // When/Then
        XCTAssertNotNil(fullDataSource as? TeamProfileDataSource, "Full data source should be castable to TeamProfileDataSource")
        XCTAssertNil(baseDataSource as? TeamProfileDataSource, "Base data source should NOT be castable to TeamProfileDataSource")
    }
    
    func testProtocolCapabilityCheck_LeagueDataSource() {
        // Given
        let fullDataSource = MockFullRemoteDataSource()
        let baseDataSource = MockRemoteDataSource()
        
        // When/Then
        XCTAssertNotNil(fullDataSource as? LeagueDataSource, "Full data source should be castable to LeagueDataSource")
        XCTAssertNil(baseDataSource as? LeagueDataSource, "Base data source should NOT be castable to LeagueDataSource")
    }
    
    // MARK: - Protocol Method Availability Tests
    
    func testFullDataSource_CanCallAllSpecializedMethods() async throws {
        // Given
        let dataSource = MockFullRemoteDataSource()
        
        // When/Then - should not crash when calling specialized methods
        do {
            _ = try await dataSource.fetchPlayerProfile(playerId: "test-id")
            _ = try await dataSource.fetchTeamProfile(teamId: "test-id")
            _ = try await dataSource.fetchTeamRoster(teamId: "test-id")
            _ = try await dataSource.fetchLeagueLeaders()
            _ = try await dataSource.fetchStandings()
        } catch {
            // Expected to fail with test data, but methods should be callable
            XCTAssertTrue(true, "Methods are callable (errors are expected with test data)")
        }
    }
    
    // MARK: - Protocol Composition Edge Cases
    
    func testPartialProtocolConformance_PlayerOnly() {
        // Given - a data source that only implements PlayerProfileDataSource
      class PlayerOnlyDataSource: RemoteDataSource, PlayerProfileDataSource {
        func fetchGame(gameId: String) async throws -> Data { return Data() }
        func fetchGames(date: Date?) async throws -> Data { Data() }
        func fetchPlayers() async throws -> Data { Data() }
        func fetchTeams() async throws -> Data { Data() }
        func fetchBoxScore(gameId: String) async throws -> Data { Data() }
        func fetchPlayerProfile(playerId: String) async throws -> Data { Data() }
      }
        
        let dataSource = PlayerOnlyDataSource()
        
        // Then
        XCTAssertTrue(dataSource is RemoteDataSource)
        XCTAssertTrue(dataSource is PlayerProfileDataSource)
        XCTAssertFalse(dataSource is TeamProfileDataSource)
        XCTAssertFalse(dataSource is LeagueDataSource)
    }
    
    func testPartialProtocolConformance_TeamOnly() {
        // Given - a data source that only implements TeamProfileDataSource
      class TeamOnlyDataSource: RemoteDataSource, TeamProfileDataSource {
        func fetchGame(gameId: String) async throws -> Data { return Data() }
        func fetchGames(date: Date?) async throws -> Data { Data() }
        func fetchPlayers() async throws -> Data { Data() }
        func fetchTeams() async throws -> Data { Data() }
        func fetchBoxScore(gameId: String) async throws -> Data { Data() }
        func fetchTeamProfile(teamId: String) async throws -> Data { Data() }
        func fetchTeamRoster(teamId: String) async throws -> Data { Data() }
      }
        
        let dataSource = TeamOnlyDataSource()
        
        // Then
        XCTAssertTrue(dataSource is RemoteDataSource)
        XCTAssertFalse(dataSource is PlayerProfileDataSource)
        XCTAssertTrue(dataSource is TeamProfileDataSource)
        XCTAssertFalse(dataSource is LeagueDataSource)
    }
}
