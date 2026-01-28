//
//  TeamLeadersManagerTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

/// Test suite for TeamLeadersManager
final class TeamLeadersManagerTests: XCTestCase {
    var sut: TeamLeadersManager!
    var mockPlayers: [Player]!
    
    override func setUp() {
        super.setUp()
        mockPlayers = createMockPlayers()
    }
    
    override func tearDown() {
        sut = nil
        mockPlayers = nil
        super.tearDown()
    }
    
    // MARK: - Test Data
    
    /// Create mock players with varied statistics
    func createMockPlayers() -> [Player] {
        let team = Team(
            id: "team-1",
            name: "Test Team",
            abbreviation: "TST",
            logoURL: nil,
            city: "Test City",
            conference: .eastern,
            division: nil,
            wins: 10,
            losses: 5,
            winPercentage: 0.667
        )
        
        return [
            // Scoring leader
            Player(
                id: "player-1",
                name: "Sarah Scoring",
                team: team,
                position: "Guard",
                statistics: [
                    Statistic(id: "stat-1", name: "Points Per Game", value: 25.5, category: .scoring, unit: .points, season: "2025-26", gamesPlayed: 15),
                    Statistic(id: "stat-2", name: "Rebounds", value: 5.2, category: .rebounding, unit: .rebounds, season: "2025-26", gamesPlayed: 15),
                    Statistic(id: "stat-3", name: "Assists Per Game", value: 4.8, category: .assists, unit: .assists, season: "2025-26", gamesPlayed: 15)
                ],
                jerseyNumber: 23,
                height: "6'0\"",
                weight: 165,
                age: 28,
                college: "Stanford",
                photoURL: nil
            ),
            // Rebounding leader
            Player(
                id: "player-2",
                name: "Rebecca Rebound",
                team: team,
                position: "Forward",
                statistics: [
                    Statistic(id: "stat-4", name: "Points Per Game", value: 18.3, category: .scoring, unit: .points, season: "2025-26", gamesPlayed: 15),
                    Statistic(id: "stat-5", name: "Rebounds", value: 12.7, category: .rebounding, unit: .rebounds, season: "2025-26", gamesPlayed: 15),
                    Statistic(id: "stat-6", name: "Assists Per Game", value: 2.1, category: .assists, unit: .assists, season: "2025-26", gamesPlayed: 15)
                ],
                jerseyNumber: 33,
                height: "6'4\"",
                weight: 180,
                age: 26,
                college: "UConn",
                photoURL: nil
            ),
            // Assists leader
            Player(
                id: "player-3",
                name: "Amy Assist",
                team: team,
                position: "Guard",
                statistics: [
                    Statistic(id: "stat-7", name: "Points Per Game", value: 14.2, category: .scoring, unit: .points, season: "2025-26", gamesPlayed: 15),
                    Statistic(id: "stat-8", name: "Rebounds", value: 3.5, category: .rebounding, unit: .rebounds, season: "2025-26", gamesPlayed: 15),
                    Statistic(id: "stat-9", name: "Assists Per Game", value: 9.4, category: .assists, unit: .assists, season: "2025-26", gamesPlayed: 15)
                ],
                jerseyNumber: 7,
                height: "5'9\"",
                weight: 155,
                age: 25,
                college: "Notre Dame",
                photoURL: nil
            ),
            // Balanced player
            Player(
                id: "player-4",
                name: "Bonnie Balanced",
                team: team,
                position: "Forward",
                statistics: [
                    Statistic(id: "stat-10", name: "Points Per Game", value: 16.8, category: .scoring, unit: .points, season: "2025-26", gamesPlayed: 15),
                    Statistic(id: "stat-11", name: "Rebounds", value: 7.2, category: .rebounding, unit: .rebounds, season: "2025-26", gamesPlayed: 15),
                    Statistic(id: "stat-12", name: "Assists Per Game", value: 5.3, category: .assists, unit: .assists, season: "2025-26", gamesPlayed: 15)
                ],
                jerseyNumber: 15,
                height: "6'2\"",
                weight: 170,
                age: 27,
                college: "Duke",
                photoURL: nil
            )
        ]
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_WithPlayers_Succeeds() {
        // Given / When
        sut = TeamLeadersManager(players: mockPlayers)
        
        // Then
        XCTAssertNotNil(sut)
    }
    
    func testInitialization_WithEmptyArray_Succeeds() {
        // Given / When
        sut = TeamLeadersManager(players: [])
        
        // Then
        XCTAssertNotNil(sut)
    }
    
    // MARK: - Individual Leader Tests
    
    func testLeader_ForPointsPerGame_ReturnsCorrectPlayer() {
        // Given
        sut = TeamLeadersManager(players: mockPlayers)
        
        // When
        let leader = sut.leader(for: .pointsPerGame)
        
        // Then
        XCTAssertEqual(leader?.name, "Sarah Scoring")
        XCTAssertEqual(leader?.pointsPerGame, 25.5)
    }
    
    func testLeader_ForReboundsPerGame_ReturnsCorrectPlayer() {
        // Given
        sut = TeamLeadersManager(players: mockPlayers)
        
        // When
        let leader = sut.leader(for: .reboundsPerGame)
        
        // Then
        XCTAssertEqual(leader?.name, "Rebecca Rebound")
        XCTAssertEqual(leader?.reboundsPerGame, 12.7)
    }
    
    func testLeader_ForAssistsPerGame_ReturnsCorrectPlayer() {
        // Given
        sut = TeamLeadersManager(players: mockPlayers)
        
        // When
        let leader = sut.leader(for: .assistsPerGame)
        
        // Then
        XCTAssertEqual(leader?.name, "Amy Assist")
        XCTAssertEqual(leader?.assistsPerGame, 9.4)
    }
    
    func testLeader_WithNoPlayers_ReturnsNil() {
        // Given
        sut = TeamLeadersManager(players: [])
        
        // When
        let leader = sut.leader(for: .pointsPerGame)
        
        // Then
        XCTAssertNil(leader)
    }
    
    // MARK: - Multiple Leaders Tests
    
    func testLeaders_ForMultipleCategories_ReturnsCorrectPlayers() {
        // Given
        sut = TeamLeadersManager(players: mockPlayers)
        
        // When
        let leaders = sut.leaders(for: [.pointsPerGame, .reboundsPerGame, .assistsPerGame])
        
        // Then
        XCTAssertEqual(leaders.count, 3)
        XCTAssertEqual(leaders[0].player.name, "Sarah Scoring")
        XCTAssertEqual(leaders[1].player.name, "Rebecca Rebound")
        XCTAssertEqual(leaders[2].player.name, "Amy Assist")
    }
    
    func testLeaders_WithEmptyCategories_ReturnsEmptyArray() {
        // Given
        sut = TeamLeadersManager(players: mockPlayers)
        
        // When
        let leaders = sut.leaders(for: [])
        
        // Then
        XCTAssertTrue(leaders.isEmpty)
    }
    
    func testDefaultLeaders_ReturnsThreeCategories() {
        // Given
        sut = TeamLeadersManager(players: mockPlayers)
        
        // When
        let leaders = sut.defaultLeaders()
        
        // Then
        XCTAssertEqual(leaders.count, 3)
        XCTAssertEqual(leaders[0].category, .pointsPerGame)
        XCTAssertEqual(leaders[1].category, .reboundsPerGame)
        XCTAssertEqual(leaders[2].category, .assistsPerGame)
    }
    
    // MARK: - Edge Case Tests
    
    func testLeader_WithSinglePlayer_ReturnsPlayerForAllCategories() {
        // Given
        let singlePlayer = Array(mockPlayers.prefix(1))
        sut = TeamLeadersManager(players: singlePlayer)
        
        // When
        let scoringLeader = sut.leader(for: .pointsPerGame)
        let reboundingLeader = sut.leader(for: .reboundsPerGame)
        let assistsLeader = sut.leader(for: .assistsPerGame)
        
        // Then
        XCTAssertEqual(scoringLeader?.name, "Sarah Scoring")
        XCTAssertEqual(reboundingLeader?.name, "Sarah Scoring")
        XCTAssertEqual(assistsLeader?.name, "Sarah Scoring")
    }
    
    func testLeader_WithTiedStatistics_ReturnsOnePlayer() {
        // Given
        let team = Team(
            id: "team-1",
            name: "Test Team",
            abbreviation: "TST",
            logoURL: nil,
            city: nil,
            conference: .eastern,
            division: nil,
            wins: 10,
            losses: 5,
            winPercentage: 0.667
        )
        
        let tiedPlayers = [
            Player(
                id: "player-1",
                name: "Player One",
                team: team,
                position: "Guard",
                statistics: [
                    Statistic(id: "stat-1", name: "Points Per Game", value: 20.0, category: .scoring, unit: .points, season: "2025-26", gamesPlayed: 15)
                ],
                jerseyNumber: 1,
                height: "6'0\"",
                weight: 165,
                age: 25,
                college: nil,
                photoURL: nil
            ),
            Player(
                id: "player-2",
                name: "Player Two",
                team: team,
                position: "Guard",
                statistics: [
                    Statistic(id: "stat-2", name: "Points Per Game", value: 20.0, category: .scoring, unit: .points, season: "2025-26", gamesPlayed: 15)
                ],
                jerseyNumber: 2,
                height: "6'1\"",
                weight: 170,
                age: 26,
                college: nil,
                photoURL: nil
            )
        ]
        
        sut = TeamLeadersManager(players: tiedPlayers)
        
        // When
        let leader = sut.leader(for: .pointsPerGame)
        
        // Then
        XCTAssertNotNil(leader)
        XCTAssertEqual(leader?.pointsPerGame, 20.0)
    }
    
    // MARK: - StatisticalCategory Tests
    
    func testStatisticalCategory_DisplayNames_AreCorrect() {
        // Given / When / Then
        XCTAssertEqual(StatisticalCategory.pointsPerGame.displayName, "Points Per Game")
        XCTAssertEqual(StatisticalCategory.reboundsPerGame.displayName, "Rebounds Per Game")
        XCTAssertEqual(StatisticalCategory.assistsPerGame.displayName, "Assists Per Game")
    }
    
    func testStatisticalCategory_Abbreviations_AreCorrect() {
        // Given / When / Then
        XCTAssertEqual(StatisticalCategory.pointsPerGame.abbreviation, "PPG")
        XCTAssertEqual(StatisticalCategory.reboundsPerGame.abbreviation, "RPG")
        XCTAssertEqual(StatisticalCategory.assistsPerGame.abbreviation, "APG")
        XCTAssertEqual(StatisticalCategory.stealsPerGame.abbreviation, "SPG")
        XCTAssertEqual(StatisticalCategory.blocksPerGame.abbreviation, "BPG")
    }
    
    func testStatisticalCategory_ValueForPlayer_ReturnsCorrectValue() {
        // Given
        let sarah = mockPlayers[0] // Sarah Scoring
        
        // When
        let ppg = StatisticalCategory.pointsPerGame.value(for: sarah)
        let rpg = StatisticalCategory.reboundsPerGame.value(for: sarah)
        let apg = StatisticalCategory.assistsPerGame.value(for: sarah)
        
        // Then
        XCTAssertEqual(ppg, 25.5)
        XCTAssertEqual(rpg, 5.2)
        XCTAssertEqual(apg, 4.8)
    }
    
    // MARK: - Player Extension Tests
    
    func testPlayerComputedProperties_ReturnCorrectValues() {
        // Given
        let sarah = mockPlayers[0]
        
        // When / Then
        XCTAssertEqual(sarah.pointsPerGame, 25.5)
        XCTAssertEqual(sarah.reboundsPerGame, 5.2)
        XCTAssertEqual(sarah.assistsPerGame, 4.8)
    }
    
    func testPlayerComputedProperties_WithMissingStats_ReturnZero() {
        // Given
        let team = Team(
            id: "team-1",
            name: "Test Team",
            abbreviation: "TST",
            logoURL: nil,
            city: nil,
            conference: .eastern,
            division: nil,
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
        
        let playerWithNoStats = Player(
            id: "player-1",
            name: "No Stats",
            team: team,
            position: "Guard",
            statistics: [], // Empty statistics
            jerseyNumber: 0,
            height: nil,
            weight: nil,
            age: nil,
            college: nil,
            photoURL: nil
        )
        
        // When / Then
        XCTAssertEqual(playerWithNoStats.pointsPerGame, 0.0)
        XCTAssertEqual(playerWithNoStats.reboundsPerGame, 0.0)
        XCTAssertEqual(playerWithNoStats.assistsPerGame, 0.0)
    }
    
    // MARK: - Integration Tests
    
    func testLeaders_CanBeSortedByValue() {
        // Given
        sut = TeamLeadersManager(players: mockPlayers)
        
        // When
        let leaders = sut.defaultLeaders()
        let sortedByValue = leaders.sorted { $0.category.value(for: $0.player) > $1.category.value(for: $1.player) }
        
        // Then
        // Sarah's 25.5 PPG should be highest
        XCTAssertEqual(sortedByValue[0].player.name, "Sarah Scoring")
    }
    
    func testManager_InRealWorldScenario_HasCompleteData() {
        // Given
        sut = TeamLeadersManager(players: mockPlayers)
        
        // When
        let leaders = sut.defaultLeaders()
        
        // Then
        for (category, player) in leaders {
            let value = category.value(for: player)
            
            XCTAssertGreaterThan(value, 0.0)
            XCTAssertFalse(player.name.isEmpty)
            XCTAssertFalse(category.abbreviation.isEmpty)
        }
    }
}

//        let team = Team(
//            id: "team-1",
//            name: "Test Team",
//            abbreviation: "TST",
//            logoURL: nil,
//            city: "Test City",
//            conference: .eastern,
//            division: nil,
//            wins: 10,
//            losses: 5,
//            winPercentage: 0.667
//        )
//        
//        return [
//            // Scoring leader
//            Player(
//                id: "player-1",
//                name: "Sarah Scoring",
//                team: team,
//                position: "Guard",
//                statistics: [
//                    Statistic(id: "stat-1", name: "Points Per Game", value: 25.5, category: .scoring, unit: .points, season: "2025-26", gamesPlayed: 15),
//                    Statistic(id: "stat-2", name: "Rebounds", value: 5.2, category: .rebounding, unit: .rebounds, season: "2025-26", gamesPlayed: 15),
//                    Statistic(id: "stat-3", name: "Assists Per Game", value: 4.8, category: .assists, unit: .assists, season: "2025-26", gamesPlayed: 15)
//                ],
//                jerseyNumber: 23,
//                height: "6'0\"",
//                weight: 165,
//                age: 28,
//                college: "Stanford",
//                photoURL: nil
//            ),
//            // Rebounding leader
//            Player(
//                id: "player-2",
//                name: "Rebecca Rebound",
//                team: team,
//                position: "Forward",
//                statistics: [
//                    Statistic(id: "stat-4", name: "Points Per Game", value: 18.3, category: .scoring, unit: .points, season: "2025-26", gamesPlayed: 15),
//                    Statistic(id: "stat-5", name: "Rebounds", value: 12.7, category: .rebounding, unit: .rebounds, season: "2025-26", gamesPlayed: 15),
//                    Statistic(id: "stat-6", name: "Assists Per Game", value: 2.1, category: .assists, unit: .assists, season: "2025-26", gamesPlayed: 15)
//                ],
//                jerseyNumber: 33,
//                height: "6'4\"",
//                weight: 180,
//                age: 26,
//                college: "UConn",
//                photoURL: nil
//            ),
//            // Assists leader
//            Player(
//                id: "player-3",
//                name: "Amy Assist",
//                team: team,
//                position: "Guard",
//                statistics: [
//                    Statistic(id: "stat-7", name: "Points Per Game", value: 14.2, category: .scoring, unit: .points, season: "2025-26", gamesPlayed: 15),
//                    Statistic(id: "stat-8", name: "Rebounds", value: 3.5, category: .rebounding, unit: .rebounds, season: "2025-26", gamesPlayed: 15),
//                    Statistic(id: "stat-9", name: "Assists Per Game", value: 9.4, category: .assists, unit: .assists, season: "2025-26", gamesPlayed: 15)
//                ],
//                jerseyNumber: 7,
//                height: "5'9\"",
//                weight: 155,
//                age: 25,
//                college: "Notre Dame",
//                photoURL: nil
//            ),
//            // Balanced player
//            Player(
//                id: "player-4",
//                name: "Bonnie Balanced",
//                team: team,
//                position: "Forward",
//                statistics: [
//                    Statistic(id: "stat-10", name: "Points Per Game", value: 16.8, category: .scoring, unit: .points, season: "2025-26", gamesPlayed: 15),
//                    Statistic(id: "stat-11", name: "Rebounds", value: 7.2, category: .rebounding, unit: .rebounds, season: "2025-26", gamesPlayed: 15),
//                    Statistic(id: "stat-12", name: "Assists Per Game", value: 5.3, category: .assists, unit: .assists, season: "2025-26", gamesPlayed: 15)
//                ],
//                jerseyNumber: 15,
//                height: "6'2\"",
//                weight: 170,
//                age: 27,
//                college: "Duke",
//                photoURL: nil
//            )
  //      ]
   // }

    // MARK: - Initialization Tests
    
//    @Test("Manager initializes with players")
//    func testInitialization() {
//        let players = createMockPlayers()
//        let manager = TeamLeadersManager(players: players)
//        
//        #expect(manager != nil)
//    }
//    
//    @Test("Manager initializes with empty array")
//    func testInitializationWithEmptyArray() {
//        let manager = TeamLeadersManager(players: [])
//        
//        #expect(manager != nil)
//    }
//    
//    // MARK: - Individual Leader Tests
//    
//    @Test("Returns correct points per game leader")
//    func testPointsPerGameLeader() {
//        let players = createMockPlayers()
//        let manager = TeamLeadersManager(players: players)
//        
//        let leader = manager.leader(for: .pointsPerGame)
//        
//        #expect(leader?.name == "Sarah Scoring")
//        #expect(leader?.pointsPerGame == 25.5)
//    }
//    
//    @Test("Returns correct rebounds per game leader")
//    func testReboundsPerGameLeader() {
//        let players = createMockPlayers()
//        let manager = TeamLeadersManager(players: players)
//        
//        let leader = manager.leader(for: .reboundsPerGame)
//        
//        #expect(leader?.name == "Rebecca Rebound")
//        #expect(leader?.reboundsPerGame == 12.7)
//    }
//    
//    @Test("Returns correct assists per game leader")
//    func testAssistsPerGameLeader() {
//        let players = createMockPlayers()
//        let manager = TeamLeadersManager(players: players)
//        
//        let leader = manager.leader(for: .assistsPerGame)
//        
//        #expect(leader?.name == "Amy Assist")
//        #expect(leader?.assistsPerGame == 9.4)
//    }
//    
//    @Test("Returns nil when no players")
//    func testLeaderWithNoPlayers() {
//        let manager = TeamLeadersManager(players: [])
//        
//        let leader = manager.leader(for: .pointsPerGame)
//        
//        #expect(leader == nil)
//    }
//    
//    // MARK: - Multiple Leaders Tests
//    
//    @Test("Returns correct leaders for multiple categories")
//    func testMultipleLeaders() {
//        let players = createMockPlayers()
//        let manager = TeamLeadersManager(players: players)
//        
//        let leaders = manager.leaders(for: [.pointsPerGame, .reboundsPerGame, .assistsPerGame])
//        
//        #expect(leaders.count == 3)
//        #expect(leaders[0].player.name == "Sarah Scoring")
//        #expect(leaders[1].player.name == "Rebecca Rebound")
//        #expect(leaders[2].player.name == "Amy Assist")
//    }
//    
//    @Test("Returns empty array for empty category list")
//    func testLeadersWithEmptyCategories() {
//        let players = createMockPlayers()
//        let manager = TeamLeadersManager(players: players)
//        
//        let leaders = manager.leaders(for: [])
//        
//        #expect(leaders.isEmpty)
//    }
//    
//    @Test("Default leaders returns three categories")
//    func testDefaultLeaders() {
//        let players = createMockPlayers()
//        let manager = TeamLeadersManager(players: players)
//        
//        let leaders = manager.defaultLeaders()
//        
//        #expect(leaders.count == 3)
//        #expect(leaders[0].category == .pointsPerGame)
//        #expect(leaders[1].category == .reboundsPerGame)
//        #expect(leaders[2].category == .assistsPerGame)
//    }
//    
//    // MARK: - Edge Case Tests
//    
//    @Test("Handles single player correctly")
//    func testSinglePlayer() {
//        let players = Array(createMockPlayers().prefix(1))
//        let manager = TeamLeadersManager(players: players)
//        
//        let scoringLeader = manager.leader(for: .pointsPerGame)
//        let reboundingLeader = manager.leader(for: .reboundsPerGame)
//        let assistsLeader = manager.leader(for: .assistsPerGame)
//        
//        #expect(scoringLeader?.name == "Sarah Scoring")
//        #expect(reboundingLeader?.name == "Sarah Scoring")
//        #expect(assistsLeader?.name == "Sarah Scoring")
//    }
//    
//    @Test("Handles tied statistics")
//    func testTiedStatistics() {
//        let team = Team(
//            id: "team-1",
//            name: "Test Team",
//            abbreviation: "TST",
//            logoURL: nil,
//            city: nil,
//            conference: .eastern,
//            division: nil,
//            wins: 10,
//            losses: 5,
//            winPercentage: 0.667
//        )
//        
//        let tiedPlayers = [
//            Player(
//                id: "player-1",
//                name: "Player One",
//                team: team,
//                position: "Guard",
//                statistics: [
//                    Statistic(id: "stat-1", name: "Points Per Game", value: 20.0, category: .scoring, unit: .points, season: "2025-26", gamesPlayed: 15)
//                ],
//                jerseyNumber: 1,
//                height: "6'0\"",
//                weight: 165,
//                age: 25,
//                college: nil,
//                photoURL: nil
//            ),
//            Player(
//                id: "player-2",
//                name: "Player Two",
//                team: team,
//                position: "Guard",
//                statistics: [
//                    Statistic(id: "stat-2", name: "Points Per Game", value: 20.0, category: .scoring, unit: .points, season: "2025-26", gamesPlayed: 15)
//                ],
//                jerseyNumber: 2,
//                height: "6'1\"",
//                weight: 170,
//                age: 26,
//                college: nil,
//                photoURL: nil
//            )
//        ]
//        
//        let manager = TeamLeadersManager(players: tiedPlayers)
//        let leader = manager.leader(for: .pointsPerGame)
//        
//        // Should return one of the tied players
//        #expect(leader != nil)
//        #expect(leader?.pointsPerGame == 20.0)
//    }
//    
//    // MARK: - StatisticalCategory Tests
//    
//    @Test("Statistical category has correct display names")
//    func testCategoryDisplayNames() {
//        #expect(StatisticalCategory.pointsPerGame.displayName == "Points Per Game")
//        #expect(StatisticalCategory.reboundsPerGame.displayName == "Rebounds Per Game")
//        #expect(StatisticalCategory.assistsPerGame.displayName == "Assists Per Game")
//    }
//    
//    @Test("Statistical category has correct abbreviations")
//    func testCategoryAbbreviations() {
//        #expect(StatisticalCategory.pointsPerGame.abbreviation == "PPG")
//        #expect(StatisticalCategory.reboundsPerGame.abbreviation == "RPG")
//        #expect(StatisticalCategory.assistsPerGame.abbreviation == "APG")
//        #expect(StatisticalCategory.stealsPerGame.abbreviation == "SPG")
//        #expect(StatisticalCategory.blocksPerGame.abbreviation == "BPG")
//    }
//    
//    @Test("Statistical category returns correct values for player")
//    func testCategoryValuesForPlayer() {
//        let players = createMockPlayers()
//        let sarah = players[0] // Sarah Scoring
//        
//        let ppg = StatisticalCategory.pointsPerGame.value(for: sarah)
//        let rpg = StatisticalCategory.reboundsPerGame.value(for: sarah)
//        let apg = StatisticalCategory.assistsPerGame.value(for: sarah)
//        
//        #expect(ppg == 25.5)
//        #expect(rpg == 5.2)
//        #expect(apg == 4.8)
//    }
//    
//    // MARK: - Player Extension Tests
//    
//    @Test("Player computed properties return correct values")
//    func testPlayerComputedProperties() {
//        let players = createMockPlayers()
//        let sarah = players[0]
//        
//        #expect(sarah.pointsPerGame == 25.5)
//        #expect(sarah.reboundsPerGame == 5.2)
//        #expect(sarah.assistsPerGame == 4.8)
//    }
//    
//    @Test("Player computed properties handle missing stats")
//    func testPlayerMissingStats() {
//        let team = Team(
//            id: "team-1",
//            name: "Test Team",
//            abbreviation: "TST",
//            logoURL: nil,
//            city: nil,
//            conference: .eastern,
//            division: nil,
//            wins: nil,
//            losses: nil,
//            winPercentage: nil
//        )
//        
//        let playerWithNoStats = Player(
//            id: "player-1",
//            name: "No Stats",
//            team: team,
//            position: "Guard",
//            statistics: [], // Empty statistics
//            jerseyNumber: 0,
//            height: nil,
//            weight: nil,
//            age: nil,
//            college: nil,
//            photoURL: nil
//        )
//        
//        #expect(playerWithNoStats.pointsPerGame == 0.0)
//        #expect(playerWithNoStats.reboundsPerGame == 0.0)
//        #expect(playerWithNoStats.assistsPerGame == 0.0)
//    }
//    
//    // MARK: - Integration Tests
//    
//    @Test("Leaders can be sorted by value")
//    func testLeadersSorting() {
//        let players = createMockPlayers()
//        let manager = TeamLeadersManager(players: players)
//        
//        let leaders = manager.defaultLeaders()
//        let sortedByValue = leaders.sorted { $0.category.value(for: $0.player) > $1.category.value(for: $1.player) }
//        
//        // Sarah's 25.5 PPG should be highest
//        #expect(sortedByValue[0].player.name == "Sarah Scoring")
//    }
//    
//    @Test("Manager works with real-world scenario")
//    func testRealWorldScenario() {
//        let players = createMockPlayers()
//        let manager = TeamLeadersManager(players: players)
//        
//        // Get all default leaders
//        let leaders = manager.defaultLeaders()
//        
//        // Verify we have complete data for display
//        for (category, player) in leaders {
//            let value = category.value(for: player)
//            
//            #expect(value > 0.0)
//            #expect(!player.name.isEmpty)
//            #expect(!category.abbreviation.isEmpty)
//        }
//    }
//}
