//
//  URLSessionNetworkService.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// URLSession-based implementation of NetworkService with API key support and TLS 1.2+ requirement
class URLSessionNetworkService: NetworkService {
    private let session: URLSession
    private let apiConfiguration: APIConfiguration?
    
    /// Initialize with optional API configuration
    /// - Parameters:
    ///   - apiConfiguration: Optional API configuration for automatic header injection and URL building
    ///   - session: Custom URLSession (defaults to shared session with TLS 1.2+ configuration)
    init(
        apiConfiguration: APIConfiguration? = nil,
        session: URLSession? = nil
    ) {
        self.apiConfiguration = apiConfiguration
        
        // Configure session with TLS 1.2+ requirement
        if let session = session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            // Ensure TLS 1.2+ support (default on iOS 13+, but explicitly set for clarity)
            configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
            // Set reasonable timeout values
            configuration.timeoutIntervalForRequest = 30.0
            configuration.timeoutIntervalForResource = 60.0
            // Allow cellular access
            configuration.allowsCellularAccess = true
            self.session = URLSession(configuration: configuration)
        }
    }
    
    // MARK: - NetworkService Protocol Implementation
    
    func request<T: Decodable>(_ endpoint: String, headers: [String: String]? = nil) async throws -> T {
        let data = try await request(endpoint, headers: headers)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    func request(_ endpoint: String, headers: [String: String]? = nil) async throws -> Data {
        // Build URL - use API configuration if available, otherwise use endpoint as-is
        let urlString: String
        if let config = apiConfiguration {
            // If endpoint is a full URL, use it; otherwise build from base URL
            if endpoint.hasPrefix("http://") || endpoint.hasPrefix("https://") {
                urlString = endpoint
            } else {
                urlString = config.url(for: endpoint)
            }
        } else {
            urlString = endpoint
        }
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL(urlString)
        }
        
        // Build request with headers
        var request = URLRequest(url: url)
        
        // Add API key header from configuration if available
        if let config = apiConfiguration {
            let apiHeaders = config.apiKeyHeader()
            for (key, value) in apiHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add custom headers
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Make request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Check status code
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return data
    }
    
    // MARK: - Legacy Methods (Backward Compatibility)
    
    func request<T: Decodable>(_ endpoint: String) async throws -> T {
        return try await request(endpoint, headers: nil)
    }
    
    func request(_ endpoint: String) async throws -> Data {
        return try await request(endpoint, headers: nil)
    }
}

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse:
            return "Invalid HTTP response"
        case .httpError(let statusCode, let data):
            let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No error details"
            return "HTTP error \(statusCode): \(message)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
    
    var statusCode: Int? {
        if case .httpError(let code, _) = self {
            return code
        }
        return nil
    }
}
