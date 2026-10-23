//
//  FeatureFlagServiceTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class FeatureFlagServiceTests: XCTestCase {
    var sut: UserDefaultsFeatureFlagService!
    var testUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        let suiteName = "com.wehoop.test.featureflags"
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
        sut = UserDefaultsFeatureFlagService(userDefaults: testUserDefaults)
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
        sut = nil
        testUserDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Default State Tests
    
    func testIsEnabled_ReturnsTrue_ByDefault() {
        // When
        let result = sut.isEnabled(.newGamesUI)
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testIsEnabled_AllFlags_ReturnTrue_ByDefault() {
        // When
        let allFlags = FeatureFlag.allCases
        
        // Then
        for flag in allFlags {
            XCTAssertTrue(sut.isEnabled(flag), "Flag \(flag.rawValue) should be enabled by default")
        }
    }
    
    // MARK: - Enable/Disable Tests
    
    func testSetEnabled_EnablesFlag() {
        // When
        sut.setEnabled(.newGamesUI, enabled: true)
        
        // Then
        XCTAssertTrue(sut.isEnabled(.newGamesUI))
    }
    
    func testSetEnabled_DisablesFlag() {
        // Given
        sut.setEnabled(.newGamesUI, enabled: true)
        
        // When
        sut.setEnabled(.newGamesUI, enabled: false)
        
        // Then
        XCTAssertFalse(sut.isEnabled(.newGamesUI))
    }
    
    func testSetEnabled_MultipleFlags_Independent() {
        // When
        sut.setEnabled(.newGamesUI, enabled: true)
        sut.setEnabled(.newLeadersUI, enabled: false)
        sut.setEnabled(.newPlayerProfileUI, enabled: true)
        sut.setEnabled(.newTeamProfileUI, enabled: false)
        
        // Then
        XCTAssertTrue(sut.isEnabled(.newGamesUI))
        XCTAssertFalse(sut.isEnabled(.newLeadersUI))
        XCTAssertTrue(sut.isEnabled(.newPlayerProfileUI))
        XCTAssertFalse(sut.isEnabled(.newTeamProfileUI))
    }
    
    // MARK: - Reset Tests
    
    func testResetAll_ResetsAllFlagsToDefault() {
        // Given
        sut.setEnabled(.newGamesUI, enabled: false)
        sut.setEnabled(.newLeadersUI, enabled: false)
        sut.setEnabled(.newPlayerProfileUI, enabled: false)
        sut.setEnabled(.newTeamProfileUI, enabled: false)
        
        // When
        sut.resetAll()
        
        // Then - after reset, flags return to default (enabled)
        for flag in FeatureFlag.allCases {
            XCTAssertTrue(sut.isEnabled(flag), "Flag \(flag.rawValue) should be enabled (default) after reset")
        }
    }
    
    func testResetAll_AfterSettingSomeFlags() {
        // Given
        sut.setEnabled(.newGamesUI, enabled: false)
        sut.setEnabled(.newLeadersUI, enabled: false)
        
        // When
        sut.resetAll()
        
        // Then - after reset, flags return to default (enabled)
        XCTAssertTrue(sut.isEnabled(.newGamesUI))
        XCTAssertTrue(sut.isEnabled(.newLeadersUI))
    }
    
    // MARK: - Persistence Tests
    
    func testFlags_PersistAcrossInstances() {
        // Given
        sut.setEnabled(.newGamesUI, enabled: true)
        sut.setEnabled(.newLeadersUI, enabled: true)
        
        // When - create new instance with same UserDefaults
        let newInstance = UserDefaultsFeatureFlagService(userDefaults: testUserDefaults)
        
        // Then
        XCTAssertTrue(newInstance.isEnabled(.newGamesUI))
        XCTAssertTrue(newInstance.isEnabled(.newLeadersUI))
    }
    
    // MARK: - All Flags Tests
    
    func testAllFlags_HaveUniqueRawValues() {
        // Given
        let allRawValues = FeatureFlag.allCases.map { $0.rawValue }
        
        // Then
        let uniqueValues = Set(allRawValues)
        XCTAssertEqual(allRawValues.count, uniqueValues.count, "All flags should have unique raw values")
    }
}
