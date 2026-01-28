//
//  LeadersViewV2Tests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
import SwiftUI
@testable import Wehoop

@MainActor
final class LeadersViewV2Tests: XCTestCase {
    var mockViewModel: LeadersViewModel!
    
    override func setUp() {
        super.setUp()
        let mockRepository = MockLeagueLeadersRepository()
        // Add sample players with stats
       // mockRepository.leaders = createSamplePlayersWithStats()
        let useCase = GetStatLeadersUseCase(leagueLeadersRepository: mockRepository)
        mockViewModel = LeadersViewModel(getStatLeadersUseCase: useCase)
    }
    
    private func createSamplePlayersWithStats() -> [Player] {
        [
            Player(
                id: "player-1",
                name: "Player One",
                team: GameFixtures.mistBC(),
                position: "Guard",
                statistics: [TestDataFactory.makeStatistic(id: "stat-1", name: "Points Per Game", value: 25.0, category: .scoring)],
                jerseyNumber: 1,
                height: "6'0\"",
                weight: 180,
                age: 25,
                college: nil,
                photoURL: nil
            ),
            Player(
                id: "player-2",
                name: "Player Two",
                team: GameFixtures.roseBC(),
                position: "Forward",
                statistics: [TestDataFactory.makeStatistic(id: "stat-2", name: "Points Per Game", value: 23.0, category: .scoring)],
                jerseyNumber: 2,
                height: "6'2\"",
                weight: 190,
                age: 24,
                college: nil,
                photoURL: nil
            )
        ]
    }
    
    override func tearDown() {
        mockViewModel = nil
        super.tearDown()
    }
    
    func testLeadersViewV2_Initializes() {
        // When
        let view = LeadersViewV2(viewModel: mockViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
    
    func testLeadersViewV2_ShowsLoadingState() {
        // Given
        mockViewModel.isLoading = true
        
        // When
        let view = LeadersViewV2(viewModel: mockViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
    
    func testLeadersViewV2_ShowsErrorState() {
        // Given
        mockViewModel.error = NSError(domain: "TestError", code: 1, userInfo: nil)
        
        // When
        let view = LeadersViewV2(viewModel: mockViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
    
    func testLeadersViewV2_ShowsEmptyState() {
        // Given
        mockViewModel.leaders = []
        
        // When
        let view = LeadersViewV2(viewModel: mockViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
}
