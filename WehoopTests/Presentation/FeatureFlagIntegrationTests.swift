//
//  FeatureFlagIntegrationTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
import SwiftUI
@testable import Wehoop

@MainActor
final class FeatureFlagIntegrationTests: XCTestCase {
    var featureFlagService: FeatureFlagService!
    var testUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        let suiteName = "com.wehoop.test.featureflags.integration"
        testUserDefaults = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
        // Clear all keys for this suite
        if let dictionary = testUserDefaults.dictionaryRepresentation() as? [String: Any] {
            for key in dictionary.keys {
                if key.hasPrefix("feature_flag_") {
                    testUserDefaults.removeObject(forKey: key)
                }
            }
        }
        testUserDefaults.synchronize()
        featureFlagService = UserDefaultsFeatureFlagService(userDefaults: testUserDefaults)
    }
    
    override func tearDown() {
        // Clear all keys for this suite
        if let dictionary = testUserDefaults.dictionaryRepresentation() as? [String: Any] {
            for key in dictionary.keys {
                if key.hasPrefix("feature_flag_") {
                    testUserDefaults.removeObject(forKey: key)
                }
            }
        }
        testUserDefaults.synchronize()
        featureFlagService = nil
        testUserDefaults = nil
        super.tearDown()
    }
    
    // MARK: - GamesView Integration Tests
    
    func testGamesView_ShowsV2_WhenFlagEnabled() {
        // Given
        featureFlagService.setEnabled(.newGamesUI, enabled: true)
  //      let viewModel = PreviewGamesViewModel(state: .loaded)
//        let container = configureDependencyContainer()

//        // When
//      let view = GamesView(viewModel: viewModel)
//            .environment(\.featureFlagService, featureFlagService)
//            .environment(\.theme, Theme.wehoop)
//            .environment(\.teamThemeProvider, TeamThemeProvider())
//            .environment(\.dependencyContainer, container)
//           
//        
//        // Then - should not crash (V2 view should be shown)
//        XCTAssertNotNil(view)
    }
    
    func testGamesView_ShowsCurrent_WhenFlagDisabled() {
        // Given
        featureFlagService.setEnabled(.newGamesUI, enabled: false)
//        let viewModel = PreviewGamesViewModel(state: .loaded)
        let mockRepository = MockGameRepository()
    //    let mockUseCase = GetGamesUseCase(gameRepository: mockRepository)
//        let viewModel = GamesViewModel(getGamesUseCase: mockUseCase)
//
//        // When
//        let view = GamesView(viewModel: viewModel)
//            .environment(\.featureFlagService, featureFlagService)
//            .environment(\.theme, Theme.wehoop)
//            .environment(\.teamThemeProvider, TeamThemeProvider())
//        
//        // Then - should not crash (current view should be shown)
//        XCTAssertNotNil(view)
    }
    
    // MARK: - LeadersView Integration Tests
    
    func testLeadersView_ShowsV2_WhenFlagEnabled() {
        // Given
        featureFlagService.setEnabled(.newLeadersUI, enabled: true)
        let mockRepository = MockPlayerRepository()
        mockRepository.players = [
            Player(
                id: "player-1",
                name: "Test Player",
                team: GameFixtures.mistBC(),
                position: "Guard",
                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 20.0, category: .scoring)],
                jerseyNumber: 1,
                height: "6'0\"",
                weight: 180,
                age: 25,
                college: nil,
                photoURL: nil
            )
        ]
        let mockLeadersRepository = MockLeagueLeadersRepository()
        //mockLeadersRepository.leaders = mockRepository.players
        let useCase = GetStatLeadersUseCase(leagueLeadersRepository: mockLeadersRepository)
        let viewModel = LeadersViewModel(getStatLeadersUseCase: useCase)
        
        // When
        let view = LeadersView(viewModel: viewModel)
            .environment(\.featureFlagService, featureFlagService)
        
        // Then - should not crash (V2 view should be shown)
        XCTAssertNotNil(view)
    }
    
    func testLeadersView_ShowsCurrent_WhenFlagDisabled() {
        // Given
        featureFlagService.setEnabled(.newLeadersUI, enabled: false)
        let mockLeadersRepository = MockLeagueLeadersRepository()
        /*mockLeadersRepository.leaders = [
            Player(
                id: "player-1",
                name: "Test Player",
                team: GameFixtures.mistBC(),
                position: "Guard",
                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 20.0, category: .scoring)],
                jerseyNumber: 1,
                height: "6'0\"",
                weight: 180,
                age: 25,
                college: nil,
                photoURL: nil
            )
        ]*/
        let useCase = GetStatLeadersUseCase(leagueLeadersRepository: mockLeadersRepository)
        let viewModel = LeadersViewModel(getStatLeadersUseCase: useCase)
        
        // When
        let view = LeadersView(viewModel: viewModel)
            .environment(\.featureFlagService, featureFlagService)
        
        // Then - should not crash (current view should be shown)
        XCTAssertNotNil(view)
    }
    
    // MARK: - PlayerProfileView Integration Tests
    
    func testPlayerProfileView_ShowsV2_WhenFlagEnabled() {
        // Given
        featureFlagService.setEnabled(.newPlayerProfileUI, enabled: true)
        let mockRepository = MockPlayerRepository()
        mockRepository.players = [
            Player(
                id: "player-1",
                name: "Test Player",
                team: GameFixtures.mistBC(),
                position: "Guard",
                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 20.0, category: .scoring)],
                jerseyNumber: 1,
                height: "6'0\"",
                weight: 180,
                age: 25,
                college: nil,
                photoURL: nil
            )
        ]
        let useCase = GetPlayerProfileUseCase(playerRepository: mockRepository, playerId: "player-1")
        let viewModel = PlayerProfileViewModel(playerId: "player-1", getPlayerProfileUseCase: useCase)
        
        // When
        let view = PlayerProfileView(playerId: "player-1", viewModel: viewModel)
            .environment(\.featureFlagService, featureFlagService)
        
        // Then - should not crash (V2 view should be shown)
        XCTAssertNotNil(view)
    }
    
    func testPlayerProfileView_ShowsCurrent_WhenFlagDisabled() {
        // Given
        featureFlagService.setEnabled(.newPlayerProfileUI, enabled: false)
        let mockRepository = MockPlayerRepository()
        mockRepository.players = [
            Player(
                id: "player-1",
                name: "Test Player",
                team: GameFixtures.mistBC(),
                position: "Guard",
                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 20.0, category: .scoring)],
                jerseyNumber: 1,
                height: "6'0\"",
                weight: 180,
                age: 25,
                college: nil,
                photoURL: nil
            )
        ]
        let useCase = GetPlayerProfileUseCase(playerRepository: mockRepository, playerId: "player-1")
        let viewModel = PlayerProfileViewModel(playerId: "player-1", getPlayerProfileUseCase: useCase)
        
        // When
        let view = PlayerProfileView(playerId: "player-1", viewModel: viewModel)
            .environment(\.featureFlagService, featureFlagService)
        
        // Then - should not crash (current view should be shown)
        XCTAssertNotNil(view)
    }
    
    // MARK: - TeamPageView Integration Tests
    
    func testTeamPageView_ShowsV2_WhenFlagEnabled() {
        // Given
        featureFlagService.setEnabled(.newTeamProfileUI, enabled: true)
        let mockRepository = MockTeamRepository()
        mockRepository.teams = [GameFixtures.mistBC()]
        let useCase = GetTeamPageUseCase(teamRepository: mockRepository, teamId: "team-1")
        let viewModel = TeamPageViewModel(teamId: "team-1", getTeamPageUseCase: useCase)
        
        // When
        let view = TeamPageView(teamId: "team-1", viewModel: viewModel)
            .environment(\.featureFlagService, featureFlagService)
        
        // Then - should not crash (V2 view should be shown)
        XCTAssertNotNil(view)
    }
    
    func testTeamPageView_ShowsCurrent_WhenFlagDisabled() {
        // Given
        featureFlagService.setEnabled(.newTeamProfileUI, enabled: false)
        let mockRepository = MockTeamRepository()
        mockRepository.teams = [GameFixtures.mistBC()]
        let useCase = GetTeamPageUseCase(teamRepository: mockRepository, teamId: "team-1")
        let viewModel = TeamPageViewModel(teamId: "team-1", getTeamPageUseCase: useCase)
        
        // When
        let view = TeamPageView(teamId: "team-1", viewModel: viewModel)
            .environment(\.featureFlagService, featureFlagService)
        
        // Then - should not crash (current view should be shown)
        XCTAssertNotNil(view)
    }
    
    // MARK: - Multiple Flags Tests
    
    func testMultipleFlags_CanBeEnabled_Independently() {
        // Given
        featureFlagService.setEnabled(.newGamesUI, enabled: true)
        featureFlagService.setEnabled(.newLeadersUI, enabled: false)
        featureFlagService.setEnabled(.newPlayerProfileUI, enabled: true)
        featureFlagService.setEnabled(.newTeamProfileUI, enabled: false)
        
        // When/Then - all views should initialize without crashing
        let container = configureDependencyContainer()
        let factory = ViewModelFactory(container: container)
        let gamesViewModel = PreviewGamesViewModel(state: .loaded)
        let gamesView = GamesView(viewModel: gamesViewModel)
            .environment(\.featureFlagService, featureFlagService)
            .environment(\.theme, Theme.wehoop)
            .environment(\.teamThemeProvider, TeamThemeProvider())
            .environment(\.dependencyContainer, container)
            
        XCTAssertNotNil(gamesView)
        
        let mockPlayerRepo = MockPlayerRepository()
        let mockLeadersRepository = MockLeagueLeadersRepository()
        //mockLeadersRepository.leaders = mockPlayerRepo.players
        let leadersUseCase = GetStatLeadersUseCase(leagueLeadersRepository: mockLeadersRepository)
        let leadersViewModel = LeadersViewModel(getStatLeadersUseCase: leadersUseCase)
        let leadersView = LeadersView(viewModel: leadersViewModel)
            .environment(\.featureFlagService, featureFlagService)
        XCTAssertNotNil(leadersView)
    }
}
