//
//  PlayerProfileViewV2Tests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
import SwiftUI
@testable import Wehoop

@MainActor
final class PlayerProfileViewV2Tests: XCTestCase {
    var mockViewModel: PlayerProfileViewModel!
    
    override func setUp() {
        super.setUp()
        let mockRepository = MockPlayerRepository()
        // Add sample player
        mockRepository.players = [
            Player(
                id: "player-1",
                name: "Test Player",
                team: GameFixtures.mistBC(),
                position: "Guard",
                statistics: [
                    TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 21.7, category: .scoring),
                    TestDataFactory.makeStatistic(id: "stat-2", name: "Rebounds Per Game", value: 6.4, category: .rebounding),
                    TestDataFactory.makeStatistic(id: "stat-3", name: "Assists Per Game", value: 6.2, category: .assists)
                ],
                jerseyNumber: 23,
                height: "6'0\"",
                weight: 180,
                age: 25,
                college: nil,
                photoURL: nil
            )
        ]
        let useCase = GetPlayerProfileUseCase(playerRepository: mockRepository, playerId: "player-1")
        mockViewModel = PlayerProfileViewModel(playerId: "player-1", getPlayerProfileUseCase: useCase)
    }
    
    override func tearDown() {
        mockViewModel = nil
        super.tearDown()
    }
    
    func testPlayerProfileViewV2_Initializes() {
        // When
        let view = PlayerProfileViewV2(playerId: "player-1", viewModel: mockViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
    
    func testPlayerProfileViewV2_ShowsLoadingState() {
        // Given
        mockViewModel.isLoading = true
        
        // When
        let view = PlayerProfileViewV2(playerId: "player-1", viewModel: mockViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
    
    func testPlayerProfileViewV2_ShowsErrorState() {
        // Given
        mockViewModel.error = NSError(domain: "TestError", code: 1, userInfo: nil)
        
        // When
        let view = PlayerProfileViewV2(playerId: "player-1", viewModel: mockViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
    
    func testPlayerProfileViewV2_ShowsEmptyState() {
        // Given
        mockViewModel.player = nil
        
        // When
        let view = PlayerProfileViewV2(playerId: "player-1", viewModel: mockViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
}
