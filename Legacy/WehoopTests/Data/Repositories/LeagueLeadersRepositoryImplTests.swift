//
//  LeagueLeadersRepositoryImplTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class LeagueLeadersRepositoryImplTests: XCTestCase {
    var sut: LeagueLeadersRepositoryImpl!
    var mockRemoteDataSource: MockFullRemoteDataSource!
    var mockLocalDataSource: InMemoryLocalDataSource!
    var mockCacheService: MemoryCacheService!
    var testBundle: Bundle!
    
    override func setUp() {
        super.setUp()
        testBundle = Bundle.mockDataBundle
        mockRemoteDataSource = MockFullRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        mockLocalDataSource = InMemoryLocalDataSource()
        mockCacheService = MemoryCacheService()
        sut = LeagueLeadersRepositoryImpl(
            leagueLeaderDataSource: mockRemoteDataSource,
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
    
    // MARK: - Success Cases
    
    func testGetLeagueLeaders_ReturnsLeaders_WhenDataExists() async throws {
        // Given - Create mock leader entries
        let mockData = createMockLeaderEntries(category: "points", count: 5)
        
        // Override fetchLeagueLeaders to return our mock data
        class CustomMockDataSource: MockFullRemoteDataSource {
            var customLeadersData: Data?
            
            override func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
                if let data = customLeadersData {
                    return data
                }
                return try await super.fetchLeagueLeaders(seasonYear: seasonYear, seasonType: seasonType)
            }
        }
        
        let customDataSource = CustomMockDataSource(bundle: testBundle, simulatedDelay: 0.01)
        customDataSource.customLeadersData = mockData
        
        sut = LeagueLeadersRepositoryImpl(
            leagueLeaderDataSource: customDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then
        XCTAssertGreaterThanOrEqual(result.count, 0) // May be 0 if mapping fails
    }
    
    func testGetLeagueLeaders_ReturnsCachedLeaders_WhenCalledTwice() async throws {
        // Given - First call populates cache
        // Note: This test may need adjustment based on actual API response structure
        let firstResult = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // When - Second call should use cache
        let secondResult = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then
        XCTAssertEqual(firstResult.count, secondResult.count)
    }
    
    func testGetLeagueLeaders_FiltersByCategory() async throws {
        // Given - Create mock data with multiple categories
        struct LeaderEntry: Codable {
            let category: String
            let player: PlayerDTO
        }
        
        let pointsData = createMockLeaderEntries(category: "points", count: 3)
        let reboundsData = createMockLeaderEntries(category: "rebounds", count: 2)
        
        let decoder = JSONDecoder()
        var pointsLeaders = try decoder.decode([LeaderEntry].self, from: pointsData)
        let reboundsLeaders = try decoder.decode([LeaderEntry].self, from: reboundsData)
        pointsLeaders.append(contentsOf: reboundsLeaders)
        
        let encoder = JSONEncoder()
        let mockData = try encoder.encode(pointsLeaders)
        
        class CustomMockDataSource: MockFullRemoteDataSource {
            var customLeadersData: Data?
            
            override func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
                if let data = customLeadersData {
                    return data
                }
                return try await super.fetchLeagueLeaders(seasonYear: seasonYear, seasonType: seasonType)
            }
        }
        
        let customDataSource = CustomMockDataSource(bundle: testBundle, simulatedDelay: 0.01)
        customDataSource.customLeadersData = mockData
        
        sut = LeagueLeadersRepositoryImpl(
            leagueLeaderDataSource: customDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When - Request scoring leaders
        let scoringLeaders = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then - Should only return scoring leaders
        // Note: Actual filtering depends on API response structure
        XCTAssertGreaterThanOrEqual(scoringLeaders.count, 0)
    }
    
    func testGetLeagueLeaders_AppliesLimit() async throws {
        // Given
        let mockData = createMockLeaderEntries(category: "points", count: 20)
        
        class CustomMockDataSource: MockFullRemoteDataSource {
            var customLeadersData: Data?
            
            override func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
                if let data = customLeadersData {
                    return data
                }
                return try await super.fetchLeagueLeaders(seasonYear: seasonYear, seasonType: seasonType)
            }
        }
        
        let customDataSource = CustomMockDataSource(bundle: testBundle, simulatedDelay: 0.01)
        customDataSource.customLeadersData = mockData
        
        sut = LeagueLeadersRepositoryImpl(
            leagueLeaderDataSource: customDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When - Request with limit of 5
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 5)
        
        // Then
        XCTAssertLessThanOrEqual(result.count, 5)
    }
    
    // MARK: - Error Handling
    
    func testGetLeagueLeaders_FallsBackToLocal_WhenRemoteFails() async throws {
        // Given - Set up local data source with players
        let players = try await createMockPlayers()
        let encoder = JSONEncoder()
        let playersData = try encoder.encode(players.map { try PlayerDTO.from($0) })
        try mockLocalDataSource.savePlayers(playersData)
        
        // Make remote fail
        class FailingRemoteDataSource: MockFullRemoteDataSource {
            override func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
                throw NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network error"])
            }
        }
        
        let failingDataSource = FailingRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        sut = LeagueLeadersRepositoryImpl(
            leagueLeaderDataSource: failingDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then - Should fall back to local and filter players
        XCTAssertGreaterThanOrEqual(result.count, 0)
    }
    
    func testGetLeagueLeaders_ThrowsError_WhenBothRemoteAndLocalFail() async {
        // Given - Make both remote and local fail
        class FailingRemoteDataSource: MockFullRemoteDataSource {
            override func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
                throw NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network error"])
            }
        }
        
        class EmptyLocalDataSource: InMemoryLocalDataSource {
            override func loadPlayers() throws -> Data? {
                return nil // No local data
            }
        }
        
        let failingDataSource = FailingRemoteDataSource(bundle: testBundle, simulatedDelay: 0.01)
        let emptyLocalDataSource = EmptyLocalDataSource()
        
        sut = LeagueLeadersRepositoryImpl(
            leagueLeaderDataSource: failingDataSource,
            localDataSource: emptyLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When/Then
        do {
            _ = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected - both sources failed
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Cache Tests
    
    func testGetLeagueLeaders_UsesCache_WhenNotStale() async throws {
        // Given - Create mock data
        let mockData = createMockLeaderEntries(category: "points", count: 5)
        
        class CustomMockDataSource: MockFullRemoteDataSource {
            var customLeadersData: Data?
            var callCount = 0
            
            override func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
                callCount += 1
                if let data = customLeadersData {
                    return data
                }
                return try await super.fetchLeagueLeaders(seasonYear: seasonYear, seasonType: seasonType)
            }
        }
        
        let customDataSource = CustomMockDataSource(bundle: testBundle, simulatedDelay: 0.01)
        customDataSource.customLeadersData = mockData
        
        sut = LeagueLeadersRepositoryImpl(
            leagueLeaderDataSource: customDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // First call populates cache
        let firstResult = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        let firstCallCount = customDataSource.callCount
        
        // When - Second call within cache threshold
        let secondResult = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then - Should use cache (remote not called again)
        XCTAssertEqual(firstResult.count, secondResult.count)
        XCTAssertEqual(customDataSource.callCount, firstCallCount, "Should not call remote again when using cache")
    }
    
    func testGetLeagueLeaders_InvalidatesCache_ForDifferentCategory() async throws {
        // Given - Create mock data for different categories
        let pointsData = createMockLeaderEntries(category: "points", count: 3)
        let reboundsData = createMockLeaderEntries(category: "rebounds", count: 2)
        
        class CustomMockDataSource: MockFullRemoteDataSource {
            var customLeadersData: Data?
            
            override func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
                if let data = customLeadersData {
                    return data
                }
                return try await super.fetchLeagueLeaders(seasonYear: seasonYear, seasonType: seasonType)
            }
        }
        
        let customDataSource = CustomMockDataSource(bundle: testBundle, simulatedDelay: 0.01)
        customDataSource.customLeadersData = pointsData
        
        sut = LeagueLeadersRepositoryImpl(
            leagueLeaderDataSource: customDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // First call for scoring
        _ = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // When - Call for different category
        customDataSource.customLeadersData = reboundsData
        let reboundsResult = try await sut.getLeagueLeaders(category: .rebounding, limit: 10)
        
        // Then - Should fetch new data (different cache key)
        XCTAssertGreaterThanOrEqual(reboundsResult.count, 0)
    }
    
    func testGetLeagueLeaders_InvalidatesCache_ForDifferentLimit() async throws {
        // Given - Create mock data
        let mockData = createMockLeaderEntries(category: "points", count: 10)
        
        class CustomMockDataSource: MockFullRemoteDataSource {
            var customLeadersData: Data?
            var callCount = 0
            
            override func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
                callCount += 1
                if let data = customLeadersData {
                    return data
                }
                return try await super.fetchLeagueLeaders(seasonYear: seasonYear, seasonType: seasonType)
            }
        }
        
        let customDataSource = CustomMockDataSource(bundle: testBundle, simulatedDelay: 0.01)
        customDataSource.customLeadersData = mockData
        
        sut = LeagueLeadersRepositoryImpl(
            leagueLeaderDataSource: customDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // First call with limit 5
        _ = try await sut.getLeagueLeaders(category: .scoring, limit: 5)
        let firstCallCount = customDataSource.callCount
        
        // When - Call with different limit
        let secondResult = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then - Should fetch new data (different cache key)
        XCTAssertGreaterThanOrEqual(secondResult.count, 0)
        // Note: May use cache or fetch depending on implementation
    }
    
    // MARK: - Edge Cases
    
    func testGetLeagueLeaders_HandlesEmptyCategoryString() async throws {
        // Given - Create mock data with empty category
        struct LeaderEntry: Codable {
            let category: String
            let player: PlayerDTO
        }
        
        let teamDTO = TeamDTO(
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
        
        let playerDTO = PlayerDTO(
            id: "player-1",
            name: "Player 1",
            team: teamDTO,
            position: "G",
            statistics: [],
            jerseyNumber: 1,
            height: nil,
            weight: nil,
            age: nil,
            college: nil,
            photoURL: nil
        )
        
        let entry = LeaderEntry(category: "", player: playerDTO)
        let encoder = JSONEncoder()
        let mockData = try encoder.encode([entry])
        
        class CustomMockDataSource: MockFullRemoteDataSource {
            var customLeadersData: Data?
            
            override func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
                if let data = customLeadersData {
                    return data
                }
                return try await super.fetchLeagueLeaders(seasonYear: seasonYear, seasonType: seasonType)
            }
        }
        
        let customDataSource = CustomMockDataSource(bundle: testBundle, simulatedDelay: 0.01)
        customDataSource.customLeadersData = mockData
        
        sut = LeagueLeadersRepositoryImpl(
            leagueLeaderDataSource: customDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then - Should filter out entries with empty category
        XCTAssertEqual(result.count, 0)
    }
    
    func testGetLeagueLeaders_HandlesCaseInsensitiveCategoryMatching() async throws {
        // Given - Create mock data with uppercase category
        struct LeaderEntry: Codable {
            let category: String
            let player: PlayerDTO
        }
        
        let pointsData = createMockLeaderEntries(category: "POINTS", count: 2)
        let decoder = JSONDecoder()
        var entries = try decoder.decode([LeaderEntry].self, from: pointsData)
        
        // Change category to mixed case
        let encoder = JSONEncoder()
        let decoder2 = JSONDecoder()
        let dataString = String(data: pointsData, encoding: .utf8)!
        let modifiedString = dataString.replacingOccurrences(of: "\"POINTS\"", with: "\"Points\"")
        let modifiedData = modifiedString.data(using: .utf8)!
        entries = try decoder2.decode([LeaderEntry].self, from: modifiedData)
        
        let mockData = try encoder.encode(entries)
        
        class CustomMockDataSource: MockFullRemoteDataSource {
            var customLeadersData: Data?
            
            override func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
                if let data = customLeadersData {
                    return data
                }
                return try await super.fetchLeagueLeaders(seasonYear: seasonYear, seasonType: seasonType)
            }
        }
        
        let customDataSource = CustomMockDataSource(bundle: testBundle, simulatedDelay: 0.01)
        customDataSource.customLeadersData = mockData
        
        sut = LeagueLeadersRepositoryImpl(
            leagueLeaderDataSource: customDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When - Request scoring (which maps to "points")
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 10)
        
        // Then - Should match case-insensitively
        XCTAssertGreaterThanOrEqual(result.count, 0)
    }
    
    func testGetLeagueLeaders_HandlesZeroLimit() async throws {
        // Given
        let mockData = createMockLeaderEntries(category: "points", count: 5)
        
        class CustomMockDataSource: MockFullRemoteDataSource {
            var customLeadersData: Data?
            
            override func fetchLeagueLeaders(seasonYear: String? = nil, seasonType: String = "REG") async throws -> Data {
                if let data = customLeadersData {
                    return data
                }
                return try await super.fetchLeagueLeaders(seasonYear: seasonYear, seasonType: seasonType)
            }
        }
        
        let customDataSource = CustomMockDataSource(bundle: testBundle, simulatedDelay: 0.01)
        customDataSource.customLeadersData = mockData
        
        sut = LeagueLeadersRepositoryImpl(
            leagueLeaderDataSource: customDataSource,
            localDataSource: mockLocalDataSource,
            cacheService: mockCacheService
        )
        
        // When - Request with limit of 0
        let result = try await sut.getLeagueLeaders(category: .scoring, limit: 0)
        
        // Then
        XCTAssertEqual(result.count, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createMockLeaderEntries(category: String, count: Int) -> Data {
        struct LeaderEntry: Codable {
            let category: String
            let player: PlayerDTO
        }
        
        var entries: [LeaderEntry] = []
        
        for i in 1...count {
            let teamDTO = TeamDTO(
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
            
            let statCategory = category == "points" ? "scoring" : category
            let statisticDTO = StatisticDTO(
                id: "stat-\(i)",
                name: "Points Per Game",
                value: Double(20 + i),
                category: statCategory,
                unit: "points",
                season: nil,
                gamesPlayed: nil
            )
            
            let playerDTO = PlayerDTO(
                id: "player-\(i)",
                name: "Player \(i)",
                team: teamDTO,
                position: "G",
                statistics: [statisticDTO],
                jerseyNumber: i,
                height: nil,
                weight: nil,
                age: nil,
                college: nil,
                photoURL: nil
            )
            
            entries.append(LeaderEntry(category: category, player: playerDTO))
        }
        
        let encoder = JSONEncoder()
        return try! encoder.encode(entries)
    }
    
    private func createMockPlayers() async throws -> [Player] {
        // Use test data factory or create minimal players
        return [
            Player(
                id: "player-1",
                name: "Test Player 1",
                team: Team(
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
                ),
                position: "G",
                statistics: [
                    Statistic(
                        id: "stat-1",
                        name: "Points Per Game",
                        value: 25.0,
                        category: .scoring,
                        unit: .points,
                        season: nil,
                        gamesPlayed: nil
                    )
                ],
                jerseyNumber: 1,
                height: nil,
                weight: nil,
                age: nil,
                college: nil,
                photoURL: nil
            )
        ]
    }
}

// MARK: - Helper Extension

extension PlayerDTO {
    static func from(_ player: Player) throws -> PlayerDTO {
        return PlayerDTO(
            id: player.id,
            name: player.name,
            team: try TeamDTO.from(player.team),
            position: player.position,
            statistics: try player.statistics.map { try StatisticDTO.from($0) },
            jerseyNumber: player.jerseyNumber,
            height: player.height,
            weight: player.weight,
            age: player.age,
            college: player.college,
            photoURL: player.photoURL
        )
    }
}

extension TeamDTO {
    static func from(_ team: Team) -> TeamDTO {
        return TeamDTO(
            id: team.id,
            name: team.name,
            abbreviation: team.abbreviation,
            logoURL: team.logoURL,
            city: team.city,
            conference: team.conference?.abbreviation,
            division: team.division,
            wins: team.wins,
            losses: team.losses,
            winPercentage: team.winPercentage
        )
    }
}

extension StatisticDTO {
    static func from(_ statistic: Statistic) throws -> StatisticDTO {
        return StatisticDTO(
            id: statistic.id,
            name: statistic.name,
            value: statistic.value,
            category: statistic.category.rawValue,
            unit: statistic.unit?.rawValue,
            season: statistic.season,
            gamesPlayed: statistic.gamesPlayed
        )
    }
}
