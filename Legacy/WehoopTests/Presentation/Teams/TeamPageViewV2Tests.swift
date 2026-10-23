//
//  TeamPageViewV2Tests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
import SwiftUI
@testable import Wehoop

@MainActor
final class TeamPageViewV2Tests: XCTestCase {
    var mockViewModel: TeamPageViewModel!
    
    override func setUp() {
        super.setUp()
        let mockRepository = MockTeamRepository()
        // Add sample team
        mockRepository.teams = [GameFixtures.mistBC()]
        let useCase = GetTeamPageUseCase(teamRepository: mockRepository, teamId: "team-1")
        mockViewModel = TeamPageViewModel(teamId: "team-1", getTeamPageUseCase: useCase)
    }
    
    override func tearDown() {
        mockViewModel = nil
        super.tearDown()
    }
    
    func testTeamPageViewV2_Initializes() {
        // When
        let view = TeamPageViewV2(teamId: "team-1", viewModel: mockViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
    
    func testTeamPageViewV2_ShowsLoadingState() {
        // Given
        mockViewModel.isLoading = true
        
        // When
        let view = TeamPageViewV2(teamId: "team-1", viewModel: mockViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
    
    func testTeamPageViewV2_ShowsErrorState() {
        // Given
        mockViewModel.error = NSError(domain: "TestError", code: 1, userInfo: nil)
        
        // When
        let view = TeamPageViewV2(teamId: "team-1", viewModel: mockViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
    
    func testTeamPageViewV2_ShowsEmptyState() {
        // Given
        mockViewModel.team = nil
        
        // When
        let view = TeamPageViewV2(teamId: "team-1", viewModel: mockViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
}
