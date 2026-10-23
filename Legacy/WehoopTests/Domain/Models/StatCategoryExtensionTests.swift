//
//  StatCategoryExtensionTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class StatCategoryExtensionTests: XCTestCase {
    
    // MARK: - apiCategoryString Tests
    
    func testApiCategoryString_Scoring_ReturnsPoints() {
        // When
        let result = StatCategory.scoring.apiCategoryString
        
        // Then
        XCTAssertEqual(result, "points")
    }
    
    func testApiCategoryString_Rebounding_ReturnsRebounds() {
        // When
        let result = StatCategory.rebounding.apiCategoryString
        
        // Then
        XCTAssertEqual(result, "rebounds")
    }
    
    func testApiCategoryString_Assists_ReturnsAssists() {
        // When
        let result = StatCategory.assists.apiCategoryString
        
        // Then
        XCTAssertEqual(result, "assists")
    }
    
    func testApiCategoryString_Defense_ReturnsSteals() {
        // When
        let result = StatCategory.defense.apiCategoryString
        
        // Then
        XCTAssertEqual(result, "steals")
    }
    
    func testApiCategoryString_Efficiency_ReturnsEfficiency() {
        // When
        let result = StatCategory.efficiency.apiCategoryString
        
        // Then
        XCTAssertEqual(result, "efficiency")
    }
    
    func testApiCategoryString_Shooting_ReturnsFieldGoalPercentage() {
        // When
        let result = StatCategory.shooting.apiCategoryString
        
        // Then
        XCTAssertEqual(result, "field_goal_percentage")
    }
    
    func testApiCategoryString_Turnovers_ReturnsTurnovers() {
        // When
        let result = StatCategory.turnovers.apiCategoryString
        
        // Then
        XCTAssertEqual(result, "turnovers")
    }
    
    // MARK: - from(apiCategoryString:) Tests
    
    func testFromApiCategoryString_Points_ReturnsScoring() {
        // When
        let result = StatCategory.from(apiCategoryString: "points")
        
        // Then
        XCTAssertEqual(result, .scoring)
    }
    
    func testFromApiCategoryString_Point_ReturnsScoring() {
        // When
        let result = StatCategory.from(apiCategoryString: "point")
        
        // Then
        XCTAssertEqual(result, .scoring)
    }
    
    func testFromApiCategoryString_Rebounds_ReturnsRebounding() {
        // When
        let result = StatCategory.from(apiCategoryString: "rebounds")
        
        // Then
        XCTAssertEqual(result, .rebounding)
    }
    
    func testFromApiCategoryString_Rebound_ReturnsRebounding() {
        // When
        let result = StatCategory.from(apiCategoryString: "rebound")
        
        // Then
        XCTAssertEqual(result, .rebounding)
    }
    
    func testFromApiCategoryString_Assists_ReturnsAssists() {
        // When
        let result = StatCategory.from(apiCategoryString: "assists")
        
        // Then
        XCTAssertEqual(result, .assists)
    }
    
    func testFromApiCategoryString_Assist_ReturnsAssists() {
        // When
        let result = StatCategory.from(apiCategoryString: "assist")
        
        // Then
        XCTAssertEqual(result, .assists)
    }
    
    func testFromApiCategoryString_Steals_ReturnsDefense() {
        // When
        let result = StatCategory.from(apiCategoryString: "steals")
        
        // Then
        XCTAssertEqual(result, .defense)
    }
    
    func testFromApiCategoryString_Steal_ReturnsDefense() {
        // When
        let result = StatCategory.from(apiCategoryString: "steal")
        
        // Then
        XCTAssertEqual(result, .defense)
    }
    
    func testFromApiCategoryString_Efficiency_ReturnsEfficiency() {
        // When
        let result = StatCategory.from(apiCategoryString: "efficiency")
        
        // Then
        XCTAssertEqual(result, .efficiency)
    }
    
    func testFromApiCategoryString_FieldGoalPercentage_ReturnsShooting() {
        // When
        let result = StatCategory.from(apiCategoryString: "field_goal_percentage")
        
        // Then
        XCTAssertEqual(result, .shooting)
    }
    
    func testFromApiCategoryString_FieldGoalPct_ReturnsShooting() {
        // When
        let result = StatCategory.from(apiCategoryString: "field_goal_pct")
        
        // Then
        XCTAssertEqual(result, .shooting)
    }
    
    func testFromApiCategoryString_FgPercentage_ReturnsShooting() {
        // When
        let result = StatCategory.from(apiCategoryString: "fg_percentage")
        
        // Then
        XCTAssertEqual(result, .shooting)
    }
    
    func testFromApiCategoryString_FgPct_ReturnsShooting() {
        // When
        let result = StatCategory.from(apiCategoryString: "fg_pct")
        
        // Then
        XCTAssertEqual(result, .shooting)
    }
    
    func testFromApiCategoryString_Turnovers_ReturnsTurnovers() {
        // When
        let result = StatCategory.from(apiCategoryString: "turnovers")
        
        // Then
        XCTAssertEqual(result, .turnovers)
    }
    
    func testFromApiCategoryString_Turnover_ReturnsTurnovers() {
        // When
        let result = StatCategory.from(apiCategoryString: "turnover")
        
        // Then
        XCTAssertEqual(result, .turnovers)
    }
    
    // MARK: - Case Insensitive Tests
    
    func testFromApiCategoryString_IsCaseInsensitive() {
        // When/Then
        XCTAssertEqual(StatCategory.from(apiCategoryString: "POINTS"), .scoring)
        XCTAssertEqual(StatCategory.from(apiCategoryString: "Points"), .scoring)
        XCTAssertEqual(StatCategory.from(apiCategoryString: "points"), .scoring)
        XCTAssertEqual(StatCategory.from(apiCategoryString: "PoInTs"), .scoring)
    }
    
    // MARK: - Invalid Input Tests
    
    func testFromApiCategoryString_InvalidString_ReturnsNil() {
        // When
        let result = StatCategory.from(apiCategoryString: "invalid_category")
        
        // Then
        XCTAssertNil(result)
    }
    
    func testFromApiCategoryString_EmptyString_ReturnsNil() {
        // When
        let result = StatCategory.from(apiCategoryString: "")
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - Round Trip Tests
    
    func testRoundTrip_Scoring() {
        // Given
        let category = StatCategory.scoring
        
        // When
        let apiString = category.apiCategoryString
        let roundTrip = StatCategory.from(apiCategoryString: apiString)
        
        // Then
        XCTAssertEqual(roundTrip, category)
    }
    
    func testRoundTrip_Rebounding() {
        // Given
        let category = StatCategory.rebounding
        
        // When
        let apiString = category.apiCategoryString
        let roundTrip = StatCategory.from(apiCategoryString: apiString)
        
        // Then
        XCTAssertEqual(roundTrip, category)
    }
    
    func testRoundTrip_Assists() {
        // Given
        let category = StatCategory.assists
        
        // When
        let apiString = category.apiCategoryString
        let roundTrip = StatCategory.from(apiCategoryString: apiString)
        
        // Then
        XCTAssertEqual(roundTrip, category)
    }
    
    func testRoundTrip_Defense() {
        // Given
        let category = StatCategory.defense
        
        // When
        let apiString = category.apiCategoryString
        let roundTrip = StatCategory.from(apiCategoryString: apiString)
        
        // Then
        XCTAssertEqual(roundTrip, category)
    }
    
    func testRoundTrip_Shooting() {
        // Given
        let category = StatCategory.shooting
        
        // When
        let apiString = category.apiCategoryString
        let roundTrip = StatCategory.from(apiCategoryString: apiString)
        
        // Then
        XCTAssertEqual(roundTrip, category)
    }
    
    func testRoundTrip_Efficiency() {
        // Given
        let category = StatCategory.efficiency
        
        // When
        let apiString = category.apiCategoryString
        let roundTrip = StatCategory.from(apiCategoryString: apiString)
        
        // Then
        XCTAssertEqual(roundTrip, category)
    }
    
    func testRoundTrip_Turnovers() {
        // Given
        let category = StatCategory.turnovers
        
        // When
        let apiString = category.apiCategoryString
        let roundTrip = StatCategory.from(apiCategoryString: apiString)
        
        // Then
        XCTAssertEqual(roundTrip, category)
    }
}
