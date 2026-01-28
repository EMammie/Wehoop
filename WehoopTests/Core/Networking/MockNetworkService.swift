//
//  MockNetworkService.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import Foundation
@testable import Wehoop

/// Mock implementation of NetworkService for testing
class MockNetworkService: NetworkService {
    private var shouldSucceed = true
    private var responseData: Data?
    private var responseError: Error?
    private var lastEndpoint: String?
    
    var requestShouldSucceed: Bool {
        get { shouldSucceed }
        set { shouldSucceed = newValue }
    }
    
    var mockResponseData: Data? {
        get { responseData }
        set { responseData = newValue }
    }
    
    var mockError: Error? {
        get { responseError }
        set { responseError = newValue }
    }
    
    /// Last endpoint URL that was requested (for testing)
    var lastRequestURL: String? {
        lastEndpoint
    }
    
    // MARK: - NetworkService Protocol Implementation
    
    func request(_ endpoint: String, headers: [String: String]? = nil) async throws -> Data {
        // Store the endpoint for testing
        lastEndpoint = endpoint
        
        // Headers are ignored in mock, but we accept them for protocol conformance
        if shouldSucceed {
            if let data = responseData {
                return data
            }
            return Data()
        } else {
            throw responseError ?? NSError(domain: "MockNetworkError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network request failed"])
        }
    }
    
    func request<T: Decodable>(_ endpoint: String, headers: [String: String]? = nil) async throws -> T {
        // Store the endpoint for testing
        lastEndpoint = endpoint
        
        // Headers are ignored in mock, but we accept them for protocol conformance
        if shouldSucceed {
            guard let data = responseData else {
                throw NSError(domain: "MockNetworkError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No mock response data set"])
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                return decoded
            } catch {
                throw NSError(domain: "MockNetworkError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to decode mock data: \(error)"])
            }
        } else {
            throw responseError ?? NSError(domain: "MockNetworkError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network request failed"])
        }
    }
    
    // MARK: - Legacy Methods (Backward Compatibility)
    
    func request(_ endpoint: String) async throws -> Data {
        return try await request(endpoint, headers: nil)
    }
    
    func request<T: Decodable>(_ endpoint: String) async throws -> T {
        return try await request(endpoint, headers: nil)
    }
}
