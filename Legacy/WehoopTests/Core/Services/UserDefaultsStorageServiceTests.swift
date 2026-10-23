//
//  UserDefaultsStorageServiceTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class UserDefaultsStorageServiceTests: XCTestCase {
    var sut: UserDefaultsStorageService!
    var testUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: "TestDefaults")
        testUserDefaults?.removePersistentDomain(forName: "TestDefaults")
        sut = UserDefaultsStorageService(userDefaults: testUserDefaults!)
    }
    
    override func tearDown() {
        testUserDefaults?.removePersistentDomain(forName: "TestDefaults")
        sut = nil
        testUserDefaults = nil
        super.tearDown()
    }
    
    func testSaveAndLoad_StringValue() throws {
        // Given
        let testString = "test value"
        let key = "testKey"
        
        // When
        try sut.save(testString, forKey: key)
        let result: String? = try sut.load(String.self, forKey: key)
        
        // Then
        XCTAssertEqual(result, testString)
    }
    
    func testSaveAndLoad_CodableStruct() throws {
        // Given
        struct TestStruct: Codable, Equatable {
            let id: String
            let name: String
        }
        let testValue = TestStruct(id: "1", name: "Test")
        let key = "testStruct"
        
        // When
        try sut.save(testValue, forKey: key)
        let result: TestStruct? = try sut.load(TestStruct.self, forKey: key)
        
        // Then
        XCTAssertEqual(result, testValue)
    }
    
    func testRemove_RemovesValue() throws {
        // Given
        let testString = "test value"
        let key = "testKey"
        try sut.save(testString, forKey: key)
        
        // When
        sut.remove(forKey: key)
        let result: String? = try sut.load(String.self, forKey: key)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testClear_RemovesAllValues() throws {
        // Given
        try sut.save("value1", forKey: "key1")
        try sut.save("value2", forKey: "key2")
        
        // When
        sut.clear()
        
        // Then
        let result1: String? = try sut.load(String.self, forKey: "key1")
        let result2: String? = try sut.load(String.self, forKey: "key2")
        XCTAssertNil(result1)
        XCTAssertNil(result2)
    }
}
