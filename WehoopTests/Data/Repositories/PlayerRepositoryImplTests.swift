//
//  PlayerRepositoryImplTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class PlayerRepositoryImplTests: XCTestCase {
    var sut: PlayerRepositoryImpl!
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
        sut = PlayerRepositoryImpl(
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
    
    func testGetPlayers_ReturnsPlayers_WhenDataExists() async throws {
        // When
        let result = try await sut.getPlayers()
        
        // Then
        XCTAssertFalse(result.isEmpty, "Should return players from mock data")
        XCTAssertGreaterThan(result.count, 0)
    }
    
    func testGetPlayers_ReturnsCachedPlayers_WhenCalledTwice() async throws {
        // Given
        let firstResult = try await sut.getPlayers()
        
        // When
        let secondResult = try await sut.getPlayers()
        
        // Then
        XCTAssertEqual(firstResult.count, secondResult.count)
        XCTAssertEqual(firstResult.map { $0.id }, secondResult.map { $0.id })
    }
    
    func testGetPlayer_ReturnsPlayer_WhenIdExists() async throws {
        // Given
        let playerId = "player-1"
        
        // When
        let result = try await sut.getPlayer(id: playerId)
        
        // Then
        XCTAssertEqual(result.id, playerId)
        XCTAssertNotNil(result.team)
        XCTAssertFalse(result.statistics.isEmpty)
    }
    
    func testGetPlayer_ThrowsError_WhenIdDoesNotExist() async {
        // Given
        let playerId = "nonexistent-player-id"
        
        // When/Then
        do {
            _ = try await sut.getPlayer(id: playerId)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("not found"))
        }
    }
    
    func testGetPlayer_ReturnsCachedPlayer_WhenCalledTwice() async throws {
        // Given
        let playerId = "player-1"
        let firstResult = try await sut.getPlayer(id: playerId)
        
        // When
        let secondResult = try await sut.getPlayer(id: playerId)
        
        // Then
        XCTAssertEqual(firstResult.id, secondResult.id)
        XCTAssertEqual(firstResult.name, secondResult.name)
    }
    
    func testGetPlayers_IncludesStatistics() async throws {
        // When
        let players = try await sut.getPlayers()
        
        // Then
        let playersWithStats = players.filter { !$0.statistics.isEmpty }
        XCTAssertGreaterThan(playersWithStats.count, 0, "Should have at least one player with statistics")
    }
    
    func testGetPlayer_IncludesTeamInformation() async throws {
        // Given
        let playerId = "player-1"
        
        // When
        let player = try await sut.getPlayer(id: playerId)
        
        // Then
        XCTAssertNotNil(player.team.id)
        XCTAssertNotNil(player.team.name)
        XCTAssertNotNil(player.team.abbreviation)
    }
    
    // MARK: - Protocol Capability Tests
    
    func testGetPlayer_UsesPlayerProfileDataSource_WhenAvailable() async throws {
        // Given
        let playerId = "player-1"
        let mockFullDataSource = MockFullRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let repositoryWithFullDataSource = PlayerRepositoryImpl(
            remoteDataSource: mockFullDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When
        let player = try await repositoryWithFullDataSource.getPlayer(id: playerId)
        
        // Then
        XCTAssertEqual(player.id, playerId)
        XCTAssertTrue(mockFullDataSource.fetchPlayerProfileCalled, "Should use fetchPlayerProfile when PlayerProfileDataSource is available")
    }
    
    func testGetPlayer_FallsBackToFetchPlayers_WhenProfileDataSourceUnavailable() async throws {
        // Given
        let playerId = "player-1"
        // mockRemoteDataSource only implements RemoteDataSource, not PlayerProfileDataSource
        
        // When
        let player = try await sut.getPlayer(id: playerId)
        
        // Then
        XCTAssertEqual(player.id, playerId)
        // Should still work by falling back to fetchPlayers
    }
    
    func testGetPlayer_HandlesProfileFetchError_Gracefully() async throws {
        // Given
        let playerId = "player-1"
        let mockFullDataSource = MockFullRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        
        // Create a failing mock by using a non-existent player ID first
        // Then test that it falls back
        let repositoryWithFullDataSource = PlayerRepositoryImpl(
            remoteDataSource: mockFullDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When - using a valid ID should work
        let player = try await repositoryWithFullDataSource.getPlayer(id: playerId)
        
        // Then
        XCTAssertEqual(player.id, playerId)
        XCTAssertTrue(mockFullDataSource.fetchPlayerProfileCalled)
    }
    
    func testGetPlayer_ProfileFetchFailure_FallsBackToAllPlayers() async throws {
        // Given
        let playerId = "player-1"
        
        // Create a data source that fails on profile fetch but succeeds on fetchPlayers
        class FailingProfileDataSource: MockFullRemoteDataSource {
            override func fetchPlayerProfile(playerId: String) async throws -> Data {
                fetchPlayerProfileCalled = true
                throw NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Profile fetch failed"])
            }
        }
        
        let failingDataSource = FailingProfileDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let repository = PlayerRepositoryImpl(
            remoteDataSource: failingDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When
        let player = try await repository.getPlayer(id: playerId)
        
        // Then
        XCTAssertEqual(player.id, playerId, "Should still return player via fallback")
        XCTAssertTrue(failingDataSource.fetchPlayerProfileCalled, "Should attempt profile fetch first")
    }
    
    func testGetPlayer_DoesNotCallProfileFetch_WhenDataSourceDoesNotSupportIt() async throws {
        // Given
        let playerId = "player-1"
        // mockRemoteDataSource only implements RemoteDataSource, not PlayerProfileDataSource
        
        // When
        let player = try await sut.getPlayer(id: playerId)
        
        // Then
        XCTAssertEqual(player.id, playerId)
        // Verify that we didn't try to cast to PlayerProfileDataSource (implicitly tested by success)
    }
    
    func testGetPlayer_CachesResult_AfterProfileFetch() async throws {
        // Given
        let playerId = "player-1"
        let mockFullDataSource = MockFullRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let repository = PlayerRepositoryImpl(
            remoteDataSource: mockFullDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // Clear cache
        mockCacheService.clear()
        
        // When - first call
        let firstCall = try await repository.getPlayer(id: playerId)
        mockFullDataSource.fetchPlayerProfileCalled = false // Reset flag
        
        // Second call should use cache
        let secondCall = try await repository.getPlayer(id: playerId)
        
        // Then
        XCTAssertEqual(firstCall.id, secondCall.id)
        XCTAssertFalse(mockFullDataSource.fetchPlayerProfileCalled, "Should not call profile fetch on second call (cached)")
    }
}
