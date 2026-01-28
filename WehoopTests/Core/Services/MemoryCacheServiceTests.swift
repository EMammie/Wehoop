//
//  MemoryCacheServiceTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class MemoryCacheServiceTests: XCTestCase {
    var sut: MemoryCacheService!
    
    override func setUp() {
        super.setUp()
        sut = MemoryCacheService()
    }
    
    override func tearDown() {
        sut.clear()
        sut = nil
        super.tearDown()
    }
    
    func testSetAndGet_StringValue() {
        // Given
        let testString = "test value"
        let key = "testKey"
        
        // When
        sut.set(testString, forKey: key, expiration: nil)
        let result: String? = sut.get(String.self, forKey: key)
        
        // Then
        XCTAssertEqual(result, testString)
    }
    
    func testSetAndGet_CodableStruct() {
        // Given
        struct TestStruct: Codable, Equatable {
            let id: String
            let name: String
        }
        let testValue = TestStruct(id: "1", name: "Test")
        let key = "testStruct"
        
        // When
        sut.set(testValue, forKey: key, expiration: nil)
        let result: TestStruct? = sut.get(TestStruct.self, forKey: key)
        
        // Then
        XCTAssertEqual(result, testValue)
    }
    
    func testRemove_RemovesValue() {
        // Given
        let testString = "test value"
        let key = "testKey"
        sut.set(testString, forKey: key, expiration: nil)
        
        // When
        sut.remove(forKey: key)
        let result: String? = sut.get(String.self, forKey: key)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testClear_RemovesAllValues() {
        // Given
        sut.set("value1", forKey: "key1", expiration: nil)
        sut.set("value2", forKey: "key2", expiration: nil)
        
        // When
        sut.clear()
        
        // Then
        let result1: String? = sut.get(String.self, forKey: "key1")
        let result2: String? = sut.get(String.self, forKey: "key2")
        XCTAssertNil(result1)
        XCTAssertNil(result2)
    }
    
    func testGet_ReturnsNil_WhenKeyDoesNotExist() {
        // When
        let result: String? = sut.get(String.self, forKey: "nonexistent")
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - Expiration Tests
    
    func testGet_ReturnsNil_WhenEntryExpired() {
        // Given
        let testString = "test value"
        let key = "testKey"
        let expiration: TimeInterval = 0.1 // 100ms
        
        // When
        sut.set(testString, forKey: key, expiration: expiration)
        
        // Wait for expiration
        let expectation = expectation(description: "Wait for expiration")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let result: String? = sut.get(String.self, forKey: key)
        
        // Then
        XCTAssertNil(result, "Should return nil when entry has expired")
    }
    
    func testGet_ReturnsValue_WhenEntryNotExpired() {
        // Given
        let testString = "test value"
        let key = "testKey"
        let expiration: TimeInterval = 1.0 // 1 second
        
        // When
        sut.set(testString, forKey: key, expiration: expiration)
        let result: String? = sut.get(String.self, forKey: key)
        
        // Then
        XCTAssertEqual(result, testString, "Should return value when entry has not expired")
    }
    
    // MARK: - Staleness Tests
    
    func testIsStale_ReturnsTrue_WhenKeyDoesNotExist() {
        // When
        let result = sut.isStale(forKey: "nonexistent", maxAge: 60)
        
        // Then
        XCTAssertTrue(result, "Should return true when key doesn't exist")
    }
    
    func testIsStale_ReturnsTrue_WhenEntryOlderThanMaxAge() {
        // Given
        let testString = "test value"
        let key = "testKey"
        let maxAge: TimeInterval = 0.1 // 100ms
        
        // When
        sut.set(testString, forKey: key, expiration: nil)
        
        // Wait for maxAge to pass
        let expectation = expectation(description: "Wait for maxAge")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let result = sut.isStale(forKey: key, maxAge: maxAge)
        
        // Then
        XCTAssertTrue(result, "Should return true when entry is older than maxAge")
    }
    
    func testIsStale_ReturnsFalse_WhenEntryNewerThanMaxAge() {
        // Given
        let testString = "test value"
        let key = "testKey"
        let maxAge: TimeInterval = 1.0 // 1 second
        
        // When
        sut.set(testString, forKey: key, expiration: nil)
        let result = sut.isStale(forKey: key, maxAge: maxAge)
        
        // Then
        XCTAssertFalse(result, "Should return false when entry is newer than maxAge")
    }
    
    func testIsStale_ReturnsTrue_WhenEntryExpired() {
        // Given
        let testString = "test value"
        let key = "testKey"
        let expiration: TimeInterval = 0.1 // 100ms
        let maxAge: TimeInterval = 60.0 // 60 seconds (longer than expiration)
        
        // When
        sut.set(testString, forKey: key, expiration: expiration)
        
        // Wait for expiration
        let expectation = expectation(description: "Wait for expiration")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let result = sut.isStale(forKey: key, maxAge: maxAge)
        
        // Then
        XCTAssertTrue(result, "Should return true when entry has expired, even if maxAge is longer")
    }
}
