//
//  GetStatLeadersUseCaseTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class GetStatLeadersUseCaseTests: XCTestCase {
    var sut: GetStatLeadersUseCase!
    var mockRepository: MockLeagueLeadersRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockLeagueLeadersRepository()
        sut = GetStatLeadersUseCase(leagueLeadersRepository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Success Cases
    
    func testExecute_ReturnsLeaders_WhenRepositorySucceeds() async throws {
        // Given
        let expectedLeaders = [
            TestDataFactory.makePlayer(
                id: "player1",
                name: "Top Scorer",
//                statistics: [TestDataFactory.makeStatistic(id: "stat1", name: "Points Per Game", value: 25.0, category: .scoring)]
            ),
            TestDataFactory.makePlayer(
                id: "player2",
                name: "Second Scorer",
//                statistics: [TestDataFactory.makeStatistic(id: "stat2", name: "Points Per Game", value: 23.0, category: .scoring)]
            )
        ]
        mockRepository.customLeaders = expectedLeaders
        
        // When
        let result = try await sut.execute(category: .scoring, limit: 10)
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "player1")
        XCTAssertEqual(result[1].id, "player2")
        XCTAssertEqual(mockRepository.getLeagueLeadersCallCount, 1)
        XCTAssertEqual(mockRepository.lastCategory, .scoring)
        XCTAssertEqual(mockRepository.lastLimit, 10)
    }
    
    func testExecute_ThrowsError_WhenRepositoryFails() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Repository error"])
        mockRepository.getLeagueLeadersError = expectedError
        
        // When/Then
        do {
            _ = try await sut.execute(category: .scoring, limit: 10)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 500)
            XCTAssertEqual(mockRepository.getLeagueLeadersCallCount, 1)
        }
    }
    
    func testExecute_ReturnsEmptyArray_WhenNoLeaders() async throws {
        // Given
      mockRepository.customLeaders = []

        // When
        let result = try await sut.execute(category: .scoring, limit: 10)
        
        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(mockRepository.getLeagueLeadersCallCount, 1)
    }
    
    func testExecute_UsesDefaultLimit_WhenNotSpecified() async throws {
        // Given
        let expectedLeaders = [
            TestDataFactory.makePlayer(
                id: "player1",
                name: "Player 1",
//                statistics: [TestDataFactory.makeStatistic(id: "stat1", name: "Points Per Game", value: 25.0, category: .scoring)]
            )
        ]
        mockRepository.customLeaders = expectedLeaders
        
        // When
        let result = try await sut.execute(category: .scoring)
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockRepository.lastLimit, 10) // Default limit
    }
    
    func testExecute_RespectsCustomLimit() async throws {
        // Given
        let expectedLeaders = (1...15).map { index in
            TestDataFactory.makePlayer(
                id: "player\(index)",
                name: "Player \(index)",
//                statistics: [TestDataFactory.makeStatistic(id: "stat\(index)", name: "Points Per Game", value: Double(30 - index), category: .scoring)]
            )
        }
        mockRepository.customLeaders = expectedLeaders
        
        // When
        let result = try await sut.execute(category: .scoring, limit: 5)
        
        // Then
        XCTAssertLessThanOrEqual(result.count, 5)
        XCTAssertEqual(mockRepository.lastLimit, 5)
    }
    
    // MARK: - Category Tests
    
    func testExecute_WithScoringCategory_CallsRepositoryWithScoring() async throws {
        // Given
        mockRepository.customLeaders = []
        
        // When
        _ = try await sut.execute(category: .scoring, limit: 10)
        
        // Then
        XCTAssertEqual(mockRepository.lastCategory, .scoring)
    }
    
    func testExecute_WithReboundingCategory_CallsRepositoryWithRebounding() async throws {
        // Given
        mockRepository.customLeaders = []

        // When
        _ = try await sut.execute(category: .rebounding, limit: 10)
        
        // Then
        XCTAssertEqual(mockRepository.lastCategory, .rebounding)
    }
    
    func testExecute_WithAssistsCategory_CallsRepositoryWithAssists() async throws {
        // Given
        mockRepository.customLeaders = []

        // When
        _ = try await sut.execute(category: .assists, limit: 10)
        
        // Then
        XCTAssertEqual(mockRepository.lastCategory, .assists)
    }
    
    func testExecute_WithDefenseCategory_CallsRepositoryWithDefense() async throws {
        // Given
        mockRepository.customLeaders = []

        // When
        _ = try await sut.execute(category: .defense, limit: 10)
        
        // Then
        XCTAssertEqual(mockRepository.lastCategory, .defense)
    }
    
    func testExecute_WithShootingCategory_CallsRepositoryWithShooting() async throws {
        // Given
        mockRepository.customLeaders = []
        
        // When
        _ = try await sut.execute(category: .shooting, limit: 10)
        
        // Then
        XCTAssertEqual(mockRepository.lastCategory, .shooting)
    }
    
    func testExecute_WithEfficiencyCategory_CallsRepositoryWithEfficiency() async throws {
        // Given
        mockRepository.customLeaders = []

        // When
        _ = try await sut.execute(category: .efficiency, limit: 10)
        
        // Then
        XCTAssertEqual(mockRepository.lastCategory, .efficiency)
    }
    
    func testExecute_WithTurnoversCategory_CallsRepositoryWithTurnovers() async throws {
        // Given
        mockRepository.customLeaders = []

        // When
        _ = try await sut.execute(category: .turnovers, limit: 10)
        
        // Then
        XCTAssertEqual(mockRepository.lastCategory, .turnovers)
    }
}
