//
//  FavoritesViewModelTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
import Combine
@testable import Wehoop

@MainActor
final class FavoritesViewModelTests: XCTestCase {
    var sut: FavoritesViewModel!
    var mockFavoritesUseCase: ManageFavoritesUseCase!
    var mockPlayerRepository: MockPlayerRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
        mockPlayerRepository = MockPlayerRepository()
        let mockFavoriteRepository = MockFavoriteRepository()
        mockFavoritesUseCase = ManageFavoritesUseCase(favoriteRepository: mockFavoriteRepository)
        sut = FavoritesViewModel(manageFavoritesUseCase: mockFavoritesUseCase, playerRepository: mockPlayerRepository)
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockFavoritesUseCase = nil
        mockPlayerRepository = nil
        super.tearDown()
    }
    
    func testInitialState_IsEmpty() {
        // Then
        XCTAssertTrue(sut.favoritePlayers.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
}
