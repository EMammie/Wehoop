//
//  NetworkServiceTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
@testable import Wehoop

final class NetworkServiceTests: XCTestCase {
    
    // MARK: - APIConfiguration Tests
    
    func testAPIConfiguration_LoadsFromBundle() {
        // Given
        let config = APIConfiguration.load()
        
        // Then
        if let config = config {
            XCTAssertFalse(config.baseURL.isEmpty, "Base URL should not be empty")
            XCTAssertFalse(config.apiKey.isEmpty, "API key should not be empty")
            XCTAssertNotEqual(config.apiKey, "YOUR_API_KEY_HERE", "API key should not be placeholder")
            XCTAssertEqual(config.apiVersion, "v8", "API version should be v8")
            XCTAssertEqual(config.apiKeyHeaderName, "x-api-key", "Default header name should be x-api-key")
        } else {
            XCTSkip("APIConfiguration not available. Configure Config.xcconfig to run these tests.")
        }
    }
    
    func testAPIConfiguration_URLBuilding() throws {
        // Given
        guard let config = APIConfiguration.load() else {
            throw XCTSkip("APIConfiguration not available")
        }
        
        // When
        let teamsURL = config.url(for: "teams")
        
        // Then
        XCTAssertTrue(teamsURL.contains("version=v8"), "URL should include version parameter")
        XCTAssertTrue(teamsURL.contains("teams"), "URL should include endpoint path")
        XCTAssertTrue(teamsURL.hasPrefix("https://"), "URL should use HTTPS")
    }
    
    func testAPIConfiguration_URLBuildingWithQueryParameters() throws {
        // Given
        guard let config = APIConfiguration.load() else {
            throw XCTSkip("APIConfiguration not available")
        }
        
        // When
        let scheduleURL = config.url(for: "schedule", queryParameters: ["date": "2024-01-01"])
        
        // Then
        XCTAssertTrue(scheduleURL.contains("version=v8"), "URL should include version parameter")
        XCTAssertTrue(scheduleURL.contains("date=2024-01-01"), "URL should include query parameters")
    }
    
    func testAPIConfiguration_APIKeyHeader() throws {
        // Given
        guard let config = APIConfiguration.load() else {
            throw XCTSkip("APIConfiguration not available")
        }
        
        // When
        let headers = config.apiKeyHeader()
        
        // Then
        XCTAssertEqual(headers.count, 1, "Should have one header")
        XCTAssertNotNil(headers["x-api-key"], "Should have x-api-key header")
        XCTAssertFalse(headers["x-api-key"]?.isEmpty ?? true, "API key should not be empty")
    }
    
    // MARK: - URLSessionNetworkService Unit Tests
    
    func testURLSessionNetworkService_InitializesWithoutConfiguration() {
        // When
        let service = URLSessionNetworkService(apiConfiguration: nil)
        
        // Then
        XCTAssertNotNil(service, "Service should initialize without configuration")
    }
    
    func testURLSessionNetworkService_InitializesWithConfiguration() throws {
        // Given
        guard let config = APIConfiguration.load() else {
            throw XCTSkip("APIConfiguration not available")
        }
        
        // When
        let service = URLSessionNetworkService(apiConfiguration: config)
        
        // Then
        XCTAssertNotNil(service, "Service should initialize with configuration")
    }
    
    // MARK: - NetworkService Protocol Tests (with Mock)
    
    func testNetworkService_BackwardCompatibility_LegacyMethods() async throws {
        // Given
        let mockService = MockNetworkService()
        let testData = "test data".data(using: .utf8)!
        mockService.mockResponseData = testData
        
        // When - Using legacy method (no headers parameter)
        let result = try await mockService.request("test-endpoint")
        
        // Then
        XCTAssertEqual(result, testData, "Should return mock data")
    }
    
    func testNetworkService_NewMethods_WithHeaders() async throws {
        // Given
        let mockService = MockNetworkService()
        let testData = "test data".data(using: .utf8)!
        mockService.mockResponseData = testData
        
        // When - Using new method with headers
        let headers = ["Custom-Header": "value"]
        let result = try await mockService.request("test-endpoint", headers: headers)
        
        // Then
        XCTAssertEqual(result, testData, "Should return mock data even with headers")
    }
    
    func testNetworkService_ErrorHandling() async throws {
        // Given
        let mockService = MockNetworkService()
        mockService.requestShouldSucceed = false
        mockService.mockError = NSError(domain: "TestError", code: 500, userInfo: nil)
        
        // When/Then
        do {
            _ = try await mockService.request("test-endpoint")
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error, "Should throw error when request fails")
        }
    }
    
    // MARK: - Integration Tests (Requires API Configuration)
    
    func testNetworkService_Integration_FetchTeams() async throws {
        // Given
        guard let config = APIConfiguration.load() else {
            throw XCTSkip("APIConfiguration not available. Configure Config.xcconfig to run integration tests.")
        }
        
        let networkService = URLSessionNetworkService(apiConfiguration: config)
        
        // When
        let data = try await networkService.request("teams")
        
        // Then
        XCTAssertFalse(data.isEmpty, "Should receive data from API")
        
        // Verify it's valid JSON
        let json = try JSONSerialization.jsonObject(with: data)
        XCTAssertNotNil(json, "Response should be valid JSON")
        
        print("✅ Integration test passed - Received \(data.count) bytes from teams endpoint")
    }
    
    func testNetworkService_Integration_APIKeyAuthentication() async throws {
        // Given
        guard let config = APIConfiguration.load() else {
            throw XCTSkip("APIConfiguration not available")
        }
        
        let networkService = URLSessionNetworkService(apiConfiguration: config)
        
        // When
        do {
            let data = try await networkService.request("teams")
            
            // Then - If we get data (not 401), authentication worked
            XCTAssertFalse(data.isEmpty, "API key authentication successful")
            print("✅ API key authentication verified")
        } catch let error as NetworkError {
            if case .httpError(let statusCode, _) = error, statusCode == 401 {
                XCTFail("API key authentication failed - check API key in Config.xcconfig")
            } else {
                throw error
            }
        }
    }
    
    func testNetworkService_Integration_VersionParameter() async throws {
        // Given
        guard let config = APIConfiguration.load() else {
            throw XCTSkip("APIConfiguration not available")
        }
        
        // Verify version parameter is in URL
        let url = config.url(for: "teams")
        XCTAssertTrue(url.contains("version=v8"), "URL should include version=v8 parameter")
        
        // When - Make request and verify it works (version is required)
        let networkService = URLSessionNetworkService(apiConfiguration: config)
        let data = try await networkService.request("teams")
        
        // Then
        XCTAssertFalse(data.isEmpty, "Request with version parameter should succeed")
        print("✅ Version parameter test passed")
    }
    
    func testNetworkService_Integration_ErrorHandling_InvalidEndpoint() async throws {
        // Given
        guard let config = APIConfiguration.load() else {
            throw XCTSkip("APIConfiguration not available")
        }
        
        let networkService = URLSessionNetworkService(apiConfiguration: config)
        
        // When
        do {
            _ = try await networkService.request("invalid-endpoint-that-does-not-exist")
            XCTFail("Should throw an error for invalid endpoint")
        } catch let error as NetworkError {
            // Then
            if case .httpError(let statusCode, _) = error {
                XCTAssertTrue([404, 400, 403].contains(statusCode), "Should get HTTP error status code")
                print("✅ Error handling test passed - Got status code: \(statusCode)")
            } else {
                throw error
            }
        }
    }
    
    func testNetworkService_Integration_CustomHeaders() async throws {
        // Given
        guard let config = APIConfiguration.load() else {
            throw XCTSkip("APIConfiguration not available")
        }
        
        let networkService = URLSessionNetworkService(apiConfiguration: config)
        let customHeaders = ["X-Custom-Header": "test-value"]
        
        // When
        let data = try await networkService.request("teams", headers: customHeaders)
        
        // Then
        XCTAssertFalse(data.isEmpty, "Request with custom headers should succeed")
        print("✅ Custom headers test passed")
    }
    
    // MARK: - NetworkError Tests
    
    func testNetworkError_InvalidURL() {
        // Given
        let error = NetworkError.invalidURL("not-a-url")
        
        // Then
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("not-a-url") ?? false)
    }
    
    func testNetworkError_HTTPError() {
        // Given
        let errorData = "Error message".data(using: .utf8)
        let error = NetworkError.httpError(statusCode: 404, data: errorData)
        
        // Then
        XCTAssertEqual(error.statusCode, 404)
        XCTAssertNotNil(error.errorDescription)
    }
    
    // MARK: - TLS Configuration Tests
    
    func testURLSessionNetworkService_TLSConfiguration() throws {
        // Given
        guard let config = APIConfiguration.load() else {
            throw XCTSkip("APIConfiguration not available")
        }
        
        // When
        let service = URLSessionNetworkService(apiConfiguration: config)
        
        // Then - Service should be configured (TLS is handled by URLSessionConfiguration)
        // We can't directly test TLS version, but we can verify HTTPS is used
        let url = config.url(for: "teams")
        XCTAssertTrue(url.hasPrefix("https://"), "Should use HTTPS (TLS required)")
    }
}
