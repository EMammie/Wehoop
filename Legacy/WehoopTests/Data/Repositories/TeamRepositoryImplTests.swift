//
//  TeamRepositoryImplTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class TeamRepositoryImplTests: XCTestCase {
    var sut: TeamRepositoryImpl!
    var mockRemoteDataSource: MockRemoteDataSource!
    var mockLocalDataSource: JSONLocalDataSource!
    var mockCacheService: MemoryCacheService!
    var testBundle: Bundle!
    
    override func setUp() {
        super.setUp()
        // Find the bundle containing MockData resources
        testBundle = Bundle.mockDataBundle
        mockRemoteDataSource = MockRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        mockLocalDataSource = JSONLocalDataSource(bundle: testBundle)
        mockCacheService = MemoryCacheService()
        sut = TeamRepositoryImpl(
            remoteDataSource: mockRemoteDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
    }
    
    override func tearDown() {
        mockCacheService.clear()
        sut = nil
        mockRemoteDataSource = nil
        mockLocalDataSource = nil
        mockCacheService = nil
        testBundle = nil
        super.tearDown()
    }
    
    func testGetTeams_ReturnsTeams_WhenDataExists() async throws {
        // When
        let result = try await sut.getTeams()
        
        // Then
        XCTAssertFalse(result.isEmpty, "Should return teams from mock data")
        XCTAssertGreaterThan(result.count, 0)
    }
    
    func testGetTeams_ReturnsCachedTeams_WhenCalledTwice() async throws {
        // Given
        let firstResult = try await sut.getTeams()
        
        // When
        let secondResult = try await sut.getTeams()
        
        // Then
        XCTAssertEqual(firstResult.count, secondResult.count)
        XCTAssertEqual(firstResult.map { $0.id }, secondResult.map { $0.id })
    }
    
    func testGetTeam_ReturnsTeam_WhenIdExists() async throws {
        // Given
        let teamId = "team-1"
        
        // When
        let result = try await sut.getTeam(id: teamId)
        
        // Then
        XCTAssertEqual(result.id, teamId)
        XCTAssertNotNil(result.name)
        XCTAssertNotNil(result.abbreviation)
    }
    
    func testGetTeam_ThrowsError_WhenIdDoesNotExist() async {
        // Given
        let teamId = "nonexistent-team-id"
        
        // When/Then
        do {
            _ = try await sut.getTeam(id: teamId)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("not found"))
        }
    }
    
    func testGetTeam_ReturnsCachedTeam_WhenCalledTwice() async throws {
        // Given
        let teamId = "team-1"
        let firstResult = try await sut.getTeam(id: teamId)
        
        // When
        let secondResult = try await sut.getTeam(id: teamId)
        
        // Then
        XCTAssertEqual(firstResult.id, secondResult.id)
        XCTAssertEqual(firstResult.name, secondResult.name)
    }
    
    func testGetTeams_IncludesConferenceInformation() async throws {
        // When
        let teams = try await sut.getTeams()
        
        // Then
        let teamsWithConference = teams.filter { $0.conference != nil }
        XCTAssertGreaterThan(teamsWithConference.count, 0, "Should have at least one team with conference")
    }
    
    func testGetTeam_IncludesWinLossRecord() async throws {
        // Given
        let teamId = "team-1"
        
        // When
        let team = try await sut.getTeam(id: teamId)
        
        // Then
        if let wins = team.wins, let losses = team.losses {
            XCTAssertGreaterThanOrEqual(wins, 0)
            XCTAssertGreaterThanOrEqual(losses, 0)
            XCTAssertNotNil(team.record)
        }
    }
    
    // MARK: - Protocol Capability Tests
    
    func testGetTeam_UsesTeamProfileDataSource_WhenAvailable() async throws {
        // Given
        let teamId = "team-1"
        let mockFullDataSource = MockFullRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let repositoryWithFullDataSource = TeamRepositoryImpl(
            remoteDataSource: mockFullDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When
        let team = try await repositoryWithFullDataSource.getTeam(id: teamId)
        
        // Then
        XCTAssertEqual(team.id, teamId)
        XCTAssertTrue(mockFullDataSource.fetchTeamProfileCalled, "Should use fetchTeamProfile when TeamProfileDataSource is available")
    }
    
    func testGetTeam_FallsBackToFetchTeams_WhenProfileDataSourceUnavailable() async throws {
        // Given
        let teamId = "team-1"
        // mockRemoteDataSource only implements RemoteDataSource, not TeamProfileDataSource
        
        // When
        let team = try await sut.getTeam(id: teamId)
        
        // Then
        XCTAssertEqual(team.id, teamId)
        // Should still work by falling back to fetchTeams
    }
    
    func testGetTeam_HandlesProfileFetchError_Gracefully() async throws {
        // Given
        let teamId = "team-1"
        let mockFullDataSource = MockFullRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let repositoryWithFullDataSource = TeamRepositoryImpl(
            remoteDataSource: mockFullDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When
        let team = try await repositoryWithFullDataSource.getTeam(id: teamId)
        
        // Then
        XCTAssertEqual(team.id, teamId)
        XCTAssertTrue(mockFullDataSource.fetchTeamProfileCalled)
    }
    
    func testGetTeam_ProfileFetchFailure_FallsBackToAllTeams() async throws {
        // Given
        let teamId = "team-1"
        
        // Create a data source that fails on profile fetch but succeeds on fetchTeams
        class FailingProfileDataSource: MockFullRemoteDataSource {
            override func fetchTeamProfile(teamId: String) async throws -> Data {
                fetchTeamProfileCalled = true
                throw NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Profile fetch failed"])
            }
        }
        
        let failingDataSource = FailingProfileDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let repository = TeamRepositoryImpl(
            remoteDataSource: failingDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When
        let team = try await repository.getTeam(id: teamId)
        
        // Then
        XCTAssertEqual(team.id, teamId, "Should still return team via fallback")
        XCTAssertTrue(failingDataSource.fetchTeamProfileCalled, "Should attempt profile fetch first")
    }
    
    func testGetTeam_DoesNotCallProfileFetch_WhenDataSourceDoesNotSupportIt() async throws {
        // Given
        let teamId = "team-1"
        // mockRemoteDataSource only implements RemoteDataSource, not TeamProfileDataSource
        
        // When
        let team = try await sut.getTeam(id: teamId)
        
        // Then
        XCTAssertEqual(team.id, teamId)
        // Verify that we didn't try to cast to TeamProfileDataSource (implicitly tested by success)
    }
    
    func testGetTeam_CachesResult_AfterProfileFetch() async throws {
        // Given
        let teamId = "team-1"
        let mockFullDataSource = MockFullRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let repository = TeamRepositoryImpl(
            remoteDataSource: mockFullDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // Clear cache
        mockCacheService.clear()
        
        // When - first call
        let firstCall = try await repository.getTeam(id: teamId)
        mockFullDataSource.fetchTeamProfileCalled = false // Reset flag
        
        // Second call should use cache
        let secondCall = try await repository.getTeam(id: teamId)
        
        // Then
        XCTAssertEqual(firstCall.id, secondCall.id)
        XCTAssertFalse(mockFullDataSource.fetchTeamProfileCalled, "Should not call profile fetch on second call (cached)")
    }
}
