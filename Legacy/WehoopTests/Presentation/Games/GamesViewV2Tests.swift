//
//  GamesViewV2Tests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
import SwiftUI
@testable import Wehoop

@MainActor
final class GamesViewV2Tests: XCTestCase {
    var mockViewModel: PreviewGamesViewModel!
    
    override func setUp() {
        super.setUp()
        mockViewModel = PreviewGamesViewModel(state: .loaded)
    }
    
    override func tearDown() {
        mockViewModel = nil
        super.tearDown()
    }
    
    func testGamesViewV2_Initializes() {
        // When
        let view = GamesViewV2(viewModel: mockViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
    
    func testGamesViewV2_ShowsLoadingState() {
        // Given
        let loadingViewModel = PreviewGamesViewModel(state: .loading)
        
        // When
        let view = GamesViewV2(viewModel: loadingViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
    
    func testGamesViewV2_ShowsErrorState() {
        // Given
        let errorViewModel = PreviewGamesViewModel(state: .error)
        
        // When
        let view = GamesViewV2(viewModel: errorViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
    
    func testGamesViewV2_ShowsEmptyState() {
        // Given
        let emptyViewModel = PreviewGamesViewModel(state: .empty)
        
        // When
        let view = GamesViewV2(viewModel: emptyViewModel)
        
        // Then - should not crash
        XCTAssertNotNil(view)
    }
}

