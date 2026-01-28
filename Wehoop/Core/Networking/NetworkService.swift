//
//  NetworkService.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Protocol for network service operations
protocol NetworkService {
    /// Make a request and decode the response
    /// - Parameters:
    ///   - endpoint: Full URL or endpoint path
    ///   - headers: Optional HTTP headers to include in the request
    /// - Returns: Decoded response object
    func request<T: Decodable>(_ endpoint: String, headers: [String: String]?) async throws -> T
    
    /// Make a request and return raw data
    /// - Parameters:
    ///   - endpoint: Full URL or endpoint path
    ///   - headers: Optional HTTP headers to include in the request
    /// - Returns: Raw response data
    func request(_ endpoint: String, headers: [String: String]?) async throws -> Data
    
    // Legacy methods for backward compatibility
    func request<T: Decodable>(_ endpoint: String) async throws -> T
    func request(_ endpoint: String) async throws -> Data
}
