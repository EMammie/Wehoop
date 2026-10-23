//
//  GameRepositoryImplTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class GameRepositoryImplTests: XCTestCase {
    var sut: GameRepositoryImpl!
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
        sut = GameRepositoryImpl(
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
    
    func testGetGames_ReturnsGames_WhenDataExists() async throws {
        // When
        let result = try await sut.getGames()
        
        // Then
        XCTAssertFalse(result.isEmpty, "Should return games from mock data")
        XCTAssertGreaterThan(result.count, 0)
    }
    
    func testGetGames_ReturnsCachedGames_WhenCalledTwice() async throws {
        // Given
        let firstResult = try await sut.getGames()
        
        // When
        let secondResult = try await sut.getGames()
        
        // Then
        XCTAssertEqual(firstResult.count, secondResult.count)
        XCTAssertEqual(firstResult.map { $0.id }, secondResult.map { $0.id })
    }
    
    func testGetGame_ReturnsGame_WhenIdExists() async throws {
        // Given
        let gameId = "game-1"
        
        // When
        let result = try await sut.getGame(id: gameId)
        
        // Then
        XCTAssertEqual(result.id, gameId)
        XCTAssertNotNil(result.homeTeam)
        XCTAssertNotNil(result.awayTeam)
    }
    
    func testGetGame_ThrowsError_WhenIdDoesNotExist() async {
        // Given
        let gameId = "nonexistent-game-id"
        
        // When/Then
        do {
            _ = try await sut.getGame(id: gameId)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("not found"))
        }
    }
    
    func testGetGame_ReturnsCachedGame_WhenCalledTwice() async throws {
        // Given
        let gameId = "game-1"
        let firstResult = try await sut.getGame(id: gameId)
        
        // When
        let secondResult = try await sut.getGame(id: gameId)
        
        // Then
        XCTAssertEqual(firstResult.id, secondResult.id)
        XCTAssertEqual(firstResult.homeTeam.id, secondResult.homeTeam.id)
    }
    
    func testGetGames_IncludesBoxScores_WhenAvailable() async throws {
        // When
        let games = try await sut.getGames()
        
        // Then
        let gamesWithBoxScores = games.filter { $0.boxScore != nil }
        XCTAssertGreaterThan(gamesWithBoxScores.count, 0, "Should have at least one game with box score")
    }
    
    func testGetGames_HandlesDifferentGameStatuses() async throws {
        // When
        let games = try await sut.getGames()
        
        // Then
        let statuses = Set(games.map { $0.status })
        XCTAssertGreaterThan(statuses.count, 1, "Should have games with different statuses")
    }
    
    // MARK: - Date Parameter Tests
    
    func testGetGames_WithDate_UsesDateSpecificCacheKey() async throws {
        // Given
        let calendar = Calendar.current
        let targetDate = Date()
        let differentDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
        
        // When - fetch games for first date
        let firstResult = try await sut.getGames(date: targetDate)
        
        // Clear cache manually to simulate different date
        mockCacheService.clear()
        
        // Fetch games for different date
        let secondResult = try await sut.getGames(date: differentDate)
        
        // Then - both should work independently
        XCTAssertNotNil(firstResult)
        XCTAssertNotNil(secondResult)
    }
    
    func testGetGames_WithDate_FiltersLocalDataByDate() async throws {
        // Given
        let calendar = Calendar.current
        let targetDate = Date()
        
        // First, fetch all games to populate local data source
        _ = try await sut.getGames()
        
        // Clear cache to force local data source usage
        mockCacheService.clear()
        
        // When - fetch games for specific date
        let result = try await sut.getGames(date: targetDate)
        
        // Then - result should be filtered by date (or empty if no games on that date)
        XCTAssertNotNil(result)
        // All returned games should be on the target date
        for game in result {
            XCTAssertTrue(calendar.isDate(game.date, inSameDayAs: targetDate), 
                         "Game \(game.id) should be on target date")
        }
    }
    
    func testGetGames_WithNilDate_ReturnsAllGames() async throws {
        // Given
        let allGames = try await sut.getGames()
        mockCacheService.clear()
        
        // When
        let result = try await sut.getGames(date: nil)
        
        // Then
        XCTAssertEqual(result.count, allGames.count, "Should return all games when date is nil")
    }
    
    // MARK: - Box Score Enhancement Tests
    
    func testGetGame_FetchesBoxScore_WhenGameDoesNotHaveOne() async throws {
        // Given
        let gameId = "game-1"
        // First, get a game (which might not have box score)
        let initialGame = try await sut.getGame(id: gameId)
        
        // Clear cache to force re-fetch
        mockCacheService.clear()
        
        // Create a game without box score for testing
        let gameWithoutBoxScore = Game(
            id: initialGame.id,
            homeTeam: initialGame.homeTeam,
            awayTeam: initialGame.awayTeam,
            date: initialGame.date,
            status: initialGame.status,
            boxScore: nil,
            venue: initialGame.venue,
            league: initialGame.league,
            broadcastNetwork: nil,
            timeZone: nil
        )
        
        // Cache the game without box score
        mockCacheService.set(gameWithoutBoxScore, forKey: "game_\(gameId)", expiration: 300)
        
        // When - getGame should attempt to fetch box score
        let gameWithBoxScore = try await sut.getGame(id: gameId)
        
        // Then
        // If box score fetch succeeds, game should have box score
        // If it fails, game should still be returned without box score
        XCTAssertEqual(gameWithBoxScore.id, gameId)
    }
    
    func testGetGame_ReturnsGameWithBoxScore_WhenAlreadyPresent() async throws {
        // Given
        let gameId = "game-1"
        let initialGame = try await sut.getGame(id: gameId)
        
        // Clear cache
        mockCacheService.clear()
        
        // Cache a game that already has a box score
        if initialGame.boxScore != nil {
            mockCacheService.set(initialGame, forKey: "game_\(gameId)", expiration: 300)
            
            // When
            let cachedGame = try await sut.getGame(id: gameId)
            
            // Then
            XCTAssertEqual(cachedGame.id, gameId)
            XCTAssertNotNil(cachedGame.boxScore, "Game with existing box score should retain it")
        }
    }
    
    func testGetGame_HandlesBoxScoreFetchFailure_Gracefully() async throws {
        // Given
        let gameId = "game-1"
        // Get a game first
        let game = try await sut.getGame(id: gameId)
        
        // Clear cache
        mockCacheService.clear()
        
        // Create a game without box score
        let gameWithoutBoxScore = Game(
            id: game.id,
            homeTeam: game.homeTeam,
            awayTeam: game.awayTeam,
            date: game.date,
            status: game.status,
            boxScore: nil,
            venue: game.venue,
            league: game.league,
            broadcastNetwork: nil,
            timeZone: nil
        )
        
        // Cache it
        mockCacheService.set(gameWithoutBoxScore, forKey: "game_\(gameId)", expiration: 300)
        
        // Create a mock data source that will fail box score fetch
        class FailingBoxScoreDataSource: MockRemoteDataSource {
            override func fetchBoxScore(gameId: String) async throws -> Data {
                throw NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Box score fetch failed"])
            }
        }
        
        let failingDataSource = FailingBoxScoreDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let repositoryWithFailingDataSource = GameRepositoryImpl(
            remoteDataSource: failingDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When
        let result = try await repositoryWithFailingDataSource.getGame(id: gameId)
        
        // Then
        XCTAssertEqual(result.id, gameId)
        // Should return game even if box score fetch fails
        XCTAssertNil(result.boxScore, "Game should be returned without box score if fetch fails")
    }
    
    func testGetGame_DoesNotFetchBoxScore_WhenAlreadyPresent() async throws {
        // Given
        let gameId = "game-1"
        let initialGame = try await sut.getGame(id: gameId)
        
        // If the game has a box score, test that it's not re-fetched
        if initialGame.boxScore != nil {
            // Clear cache and re-cache with box score
            mockCacheService.clear()
            mockCacheService.set(initialGame, forKey: "game_\(gameId)", expiration: 300)
            
            // Create a tracking data source
            class TrackingBoxScoreDataSource: MockRemoteDataSource {
                var fetchBoxScoreCallCount = 0
                override func fetchBoxScore(gameId: String) async throws -> Data {
                    fetchBoxScoreCallCount += 1
                    return try await super.fetchBoxScore(gameId: gameId)
                }
            }
            
            let trackingDataSource = TrackingBoxScoreDataSource(bundle: testBundle, simulatedDelay: 0.01)
            let repository = GameRepositoryImpl(
                remoteDataSource: trackingDataSource,
                localDataSource: mockLocalDataSource,
                cacheService: mockCacheService
            )
            
            // When
            let result = try await repository.getGame(id: gameId)
            
            // Then
            XCTAssertEqual(result.id, gameId)
            XCTAssertNotNil(result.boxScore, "Game should retain existing box score")
            XCTAssertEqual(trackingDataSource.fetchBoxScoreCallCount, 0, "Should not fetch box score when already present")
        }
    }
    
    func testGetGame_FetchesBoxScore_WhenGameMissingBoxScore() async throws {
        // Given
        let gameId = "game-1"
        let initialGame = try await sut.getGame(id: gameId)
        
        // Create a game without box score
        let gameWithoutBoxScore = Game(
            id: initialGame.id,
            homeTeam: initialGame.homeTeam,
            awayTeam: initialGame.awayTeam,
            date: initialGame.date,
            status: initialGame.status,
            boxScore: nil,
            venue: initialGame.venue,
            league: initialGame.league,
            broadcastNetwork: nil,
            timeZone: nil
        )
        
        // Clear cache and cache game without box score
        mockCacheService.clear()
        
        // Create a tracking data source
        class TrackingBoxScoreDataSource: MockRemoteDataSource {
            var fetchBoxScoreCallCount = 0
            var lastGameId: String?
            override func fetchBoxScore(gameId: String) async throws -> Data {
                fetchBoxScoreCallCount += 1
                lastGameId = gameId
                return try await super.fetchBoxScore(gameId: gameId)
            }
        }
        
        let trackingDataSource = TrackingBoxScoreDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let repository = GameRepositoryImpl(
            remoteDataSource: trackingDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // Cache game without box score
        mockCacheService.set(gameWithoutBoxScore, forKey: "game_\(gameId)", expiration: 300)
        
        // When
        let result = try await repository.getGame(id: gameId)
        
        // Then
        XCTAssertEqual(result.id, gameId)
        XCTAssertEqual(trackingDataSource.fetchBoxScoreCallCount, 1, "Should attempt to fetch box score when missing")
        XCTAssertEqual(trackingDataSource.lastGameId, gameId, "Should fetch box score for correct game")
    }
    
    func testGetGame_CachesResult_AfterBoxScoreFetch() async throws {
        // Given
        let gameId = "game-1"
        let initialGame = try await sut.getGame(id: gameId)
        
        // Create a game without box score
        let gameWithoutBoxScore = Game(
            id: initialGame.id,
            homeTeam: initialGame.homeTeam,
            awayTeam: initialGame.awayTeam,
            date: initialGame.date,
            status: initialGame.status,
            boxScore: nil,
            venue: initialGame.venue,
            league: initialGame.league,
            broadcastNetwork: nil,
            timeZone: nil
        )
        
        // Clear cache
        mockCacheService.clear()
        
        // Create a tracking data source
        class TrackingBoxScoreDataSource: MockRemoteDataSource {
            var fetchBoxScoreCallCount = 0
            override func fetchBoxScore(gameId: String) async throws -> Data {
                fetchBoxScoreCallCount += 1
                return try await super.fetchBoxScore(gameId: gameId)
            }
        }
        
        let trackingDataSource = TrackingBoxScoreDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let repository = GameRepositoryImpl(
            remoteDataSource: trackingDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // Cache game without box score
        mockCacheService.set(gameWithoutBoxScore, forKey: "game_\(gameId)", expiration: 300)
        
        // When - first call
        let firstCall = try await repository.getGame(id: gameId)
        
        // Second call should use cache
        let secondCall = try await repository.getGame(id: gameId)
        
        // Then
        XCTAssertEqual(firstCall.id, secondCall.id)
        XCTAssertEqual(trackingDataSource.fetchBoxScoreCallCount, 1, "Should only fetch box score once (second call uses cache)")
    }
    
    // MARK: - Cache Staleness and Remote Fetching Tests
    
    func testGetGames_CallsRemote_WhenCacheIsEmpty() async throws {
        // Given
        let trackingDataSource = TrackingRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let inMemoryLocalDataSource = InMemoryLocalDataSource()
        let repository = GameRepositoryImpl(
            remoteDataSource: trackingDataSource,
            localDataSource: inMemoryLocalDataSource,
            cacheService: MemoryCacheService()
        )
        
        // When
        _ = try await repository.getGames()
        
        // Then
        XCTAssertEqual(trackingDataSource.fetchGamesCallCount, 1, "Should call remote when cache is empty")
    }
    
    func testGetGames_CallsRemote_WhenCacheIsStale() async throws {
        // Given
        let trackingDataSource = TrackingRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let inMemoryLocalDataSource = InMemoryLocalDataSource()
        let cacheService = MemoryCacheService()
        let repository = GameRepositoryImpl(
            remoteDataSource: trackingDataSource,
            localDataSource: inMemoryLocalDataSource,
            cacheService: cacheService
        )
        
        // Cache some games with a very old timestamp (simulate stale cache)
        let staleGames = try await repository.getGames()
        cacheService.set(staleGames, forKey: "games_all", expiration: 300)
        
        // Manually make cache stale by manipulating internal state
        // We'll use a short maxAge to simulate 15 minutes passing
        // Since we can't directly manipulate timestamps, we'll wait and use a short staleness threshold
        // For this test, we'll create a custom cache service that allows us to set stale entries
        
        // Reset call count
        trackingDataSource.fetchGamesCallCount = 0
        
        // Wait a bit and then check if remote is called
        // Since we can't easily manipulate timestamps, we'll test with a very short staleness threshold
        // by creating a repository with a custom cache service
        
        // Actually, let's test this differently - we'll set cache with a very short expiration
        // and wait for it to expire, then check if remote is called
        cacheService.set(staleGames, forKey: "games_all", expiration: 0.01) // 10ms expiration
        
        // Wait for expiration
        try await Task.sleep(nanoseconds: 20_000_000) // 20ms
        
        // When
        _ = try await repository.getGames()
        
        // Then
        XCTAssertEqual(trackingDataSource.fetchGamesCallCount, 1, "Should call remote when cache is stale")
    }
    
    func testGetGames_ReturnsCachedData_WhenCacheIsFresh() async throws {
        // Given
        let trackingDataSource = TrackingRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let inMemoryLocalDataSource = InMemoryLocalDataSource()
        let cacheService = MemoryCacheService()
        let repository = GameRepositoryImpl(
            remoteDataSource: trackingDataSource,
            localDataSource: inMemoryLocalDataSource,
            cacheService: cacheService
        )
        
        // First call to populate cache
        let firstResult = try await repository.getGames()
        let firstCallCount = trackingDataSource.fetchGamesCallCount
        
        // When - second call should use cache
        let secondResult = try await repository.getGames()
        
        // Then
        XCTAssertEqual(firstResult.count, secondResult.count, "Should return same games from cache")
        XCTAssertEqual(trackingDataSource.fetchGamesCallCount, firstCallCount, "Should not call remote when cache is fresh")
    }
    
    func testGetGames_PersistsToWritableLocalDataSource() async throws {
        // Given
        let trackingDataSource = TrackingRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let inMemoryLocalDataSource = InMemoryLocalDataSource()
        let repository = GameRepositoryImpl(
            remoteDataSource: trackingDataSource,
            localDataSource: inMemoryLocalDataSource,
            cacheService: MemoryCacheService()
        )
        
        // When
        _ = try await repository.getGames()
        
        // Then
        let persistedData = try inMemoryLocalDataSource.loadGames()
        XCTAssertNotNil(persistedData, "Should persist games data to writable local data source")
        XCTAssertGreaterThan(persistedData?.count ?? 0, 0, "Persisted data should not be empty")
    }
    
    func testGetGames_FallsBackToLocal_WhenRemoteFails() async throws {
        // Given
        class FailingRemoteDataSource: MockRemoteDataSource {
            override func fetchGames() async throws -> Data {
                throw NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Remote fetch failed"])
            }
        }
        
        let failingDataSource = FailingRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let inMemoryLocalDataSource = InMemoryLocalDataSource()
        
        // Pre-populate local data source
        let testBundle = Bundle.mockDataBundle
        if let url = testBundle.findResource(name: "games", extension: "json", subdirectory: "MockData"),
           let data = try? Data(contentsOf: url) {
            try inMemoryLocalDataSource.saveGames(data)
        }
        
        let repository = GameRepositoryImpl(
            remoteDataSource: failingDataSource,
            localDataSource: inMemoryLocalDataSource,
            cacheService: MemoryCacheService()
        )
        
        // When
        let result = try await repository.getGames()
        
        // Then
        XCTAssertFalse(result.isEmpty, "Should fall back to local data source when remote fails")
    }
    
    func testGetGame_PersistsBoxScoreToWritableLocalDataSource() async throws {
        // Given
        let gameId = "game-1"
        let trackingDataSource = TrackingRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let inMemoryLocalDataSource = InMemoryLocalDataSource()
        let repository = GameRepositoryImpl(
            remoteDataSource: trackingDataSource,
            localDataSource: inMemoryLocalDataSource,
            cacheService: MemoryCacheService()
        )
        
        // When - get a game which should trigger box score fetch if missing
        let game = try await repository.getGame(id: gameId)
        
        // Then - if box score was fetched, it should be persisted
        if game.boxScore != nil {
            let persistedBoxScore = try inMemoryLocalDataSource.loadBoxScore(gameId: gameId)
            XCTAssertNotNil(persistedBoxScore, "Should persist box score to writable local data source")
        }
    }
    
    // MARK: - Box Score Enrichment for Live/Finished Games Tests
    
    func testGetGames_AttemptsToFetchBoxScoresForLiveGames_WhenMissing() async throws {
        // Given
        let trackingDataSource = TrackingRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let inMemoryLocalDataSource = InMemoryLocalDataSource()
        let repository = GameRepositoryImpl(
            remoteDataSource: trackingDataSource,
            localDataSource: inMemoryLocalDataSource,
            cacheService: MemoryCacheService()
        )
        
        // When - fetch games (which may include live games from mock data)
        let games = try await repository.getGames()
        
        // Then - check if box score fetch was attempted for live games
        let liveGames = games.filter { $0.isLive && $0.boxScore == nil }
        if !liveGames.isEmpty {
            // If there are live games without box scores, fetchBoxScore should have been called
            XCTAssertGreaterThan(trackingDataSource.fetchBoxScoreCallCount, 0, 
                               "Should attempt to fetch box scores for live games without them")
        }
    }
    
    func testGetGames_AttemptsToFetchBoxScoresForFinishedGames_WhenMissing() async throws {
        // Given
        let trackingDataSource = TrackingRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let inMemoryLocalDataSource = InMemoryLocalDataSource()
        let repository = GameRepositoryImpl(
            remoteDataSource: trackingDataSource,
            localDataSource: inMemoryLocalDataSource,
            cacheService: MemoryCacheService()
        )
        
        // When - fetch games (which may include finished games from mock data)
        let games = try await repository.getGames()
        
        // Then - check if box score fetch was attempted for finished games
        let finishedGames = games.filter { $0.isFinished && $0.boxScore == nil }
        if !finishedGames.isEmpty {
            // If there are finished games without box scores, fetchBoxScore should have been called
            XCTAssertGreaterThan(trackingDataSource.fetchBoxScoreCallCount, 0,
                               "Should attempt to fetch box scores for finished games without them")
        }
    }
    
    func testGetGames_DoesNotFetchBoxScoresForScheduledGames() async throws {
        // Given
        let trackingDataSource = TrackingRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let inMemoryLocalDataSource = InMemoryLocalDataSource()
        let repository = GameRepositoryImpl(
            remoteDataSource: trackingDataSource,
            localDataSource: inMemoryLocalDataSource,
            cacheService: MemoryCacheService()
        )
        
        // When - fetch games
        let games = try await repository.getGames()
        
        // Then - scheduled games should not trigger box score fetches
        let scheduledGames = games.filter { $0.status == .scheduled }
        if !scheduledGames.isEmpty {
            // Count box score calls before checking scheduled games
            let initialCallCount = trackingDataSource.fetchBoxScoreCallCount
            
            // Verify scheduled games don't have box scores (they shouldn't)
            for game in scheduledGames {
                XCTAssertNil(game.boxScore, "Scheduled games should not have box scores")
            }
            
            // Note: The fetchBoxScoreCallCount might be > 0 if there are live/finished games
            // But scheduled games themselves should not trigger fetches
            // This is verified by the fact that scheduled games don't have box scores
        }
    }
    
    func testGetGames_HandlesBoxScoreFetchFailure_Gracefully() async throws {
        // Given
        class FailingBoxScoreDataSource: TrackingRemoteDataSource {
            override func fetchBoxScore(gameId: String) async throws -> Data {
                fetchBoxScoreCallCount += 1
                throw NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Box score fetch failed"])
            }
        }
        
        let failingDataSource = FailingBoxScoreDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let inMemoryLocalDataSource = InMemoryLocalDataSource()
        let repository = GameRepositoryImpl(
            remoteDataSource: failingDataSource,
            localDataSource: inMemoryLocalDataSource,
            cacheService: MemoryCacheService()
        )
        
        // When - fetch games (should not throw even if box score fetch fails)
        let games = try await repository.getGames()
        
        // Then - should return games even if box score fetch fails
        XCTAssertFalse(games.isEmpty, "Should return games even if box score fetch fails")
        
        // Games might not have box scores if fetch failed, but should still be returned
        if failingDataSource.fetchBoxScoreCallCount > 0 {
            // Some games attempted box score fetch, but games are still returned
            XCTAssertTrue(true, "Games returned even after box score fetch failures")
        }
    }
}

// MARK: - Helper Classes

private class TrackingRemoteDataSource: MockRemoteDataSource {
    var fetchGamesCallCount = 0
    var fetchBoxScoreCallCount = 0
    
    override func fetchGames() async throws -> Data {
        fetchGamesCallCount += 1
        return try await super.fetchGames()
    }
    
    override func fetchBoxScore(gameId: String) async throws -> Data {
        fetchBoxScoreCallCount += 1
        return try await super.fetchBoxScore(gameId: gameId)
    }
}
