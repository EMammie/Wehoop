//
//  APIConfiguration.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Configuration for API access, loaded from build settings via Info.plist
struct APIConfiguration {
    /// Base URL for the Sportradar API (always includes scheme, e.g. https://)
    let baseURL: String
    
    /// Ensures the base URL has a scheme so built URLs are valid and not double-prefixed by the network layer.
    private static func normalizeBaseURL(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        return "https://\(trimmed)"
    }
    
    /// API key for authentication
    let apiKey: String
    
    /// HTTP header name for API key (Sportradar typically uses "Authorization" or "x-api-key")
    let apiKeyHeaderName: String
    
    /// API version (defaults to v8 for Unrivaled API)
    let apiVersion: String
    
    /// Initialize configuration from Info.plist
    /// - Parameters:
    ///   - bundle: Bundle to read Info.plist from (defaults to .main)
    ///   - apiKeyHeaderName: HTTP header name for API key (defaults to "x-api-key")
    ///   - apiVersion: API version to use (defaults to "v8" for Unrivaled API)
    init(
        bundle: Bundle = .main,
        apiKeyHeaderName: String = "x-api-key",
        apiVersion: String = "v8"
    ) throws {
        guard let infoDictionary = bundle.infoDictionary else {
            throw APIConfigurationError.missingInfoPlist
        }
        
        guard let rawBaseURL = infoDictionary["API_BASE_URL_PLIST_KEY"] as? String,
              !rawBaseURL.isEmpty else {
            throw APIConfigurationError.missingBaseURL
        }
        // Ensure base URL has a scheme so built URLs are valid and not re-processed by the network layer
        let baseURL = APIConfiguration.normalizeBaseURL(rawBaseURL)
        
        guard let apiKey = infoDictionary["API_KEY_PLIST_KEY"] as? String,
              !apiKey.isEmpty,
              apiKey != "YOUR_API_KEY_HERE" else {
            throw APIConfigurationError.missingAPIKey
        }
        
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.apiKeyHeaderName = apiKeyHeaderName
        self.apiVersion = apiVersion
    }
    
    /// Convenience initializer that returns nil instead of throwing
    /// Useful for optional configuration scenarios
    static func load(
        bundle: Bundle = .main,
        apiKeyHeaderName: String = "x-api-key",
        apiVersion: String = "v8"
    ) -> APIConfiguration? {
        try? APIConfiguration(bundle: bundle, apiKeyHeaderName: apiKeyHeaderName, apiVersion: apiVersion)
    }
    
    /// Create API key header value
    /// - Returns: Dictionary with header name and value
    func apiKeyHeader() -> [String: String] {
        [apiKeyHeaderName: apiKey]
    }
    
    /// Build full URL from endpoint path with version parameter
    /// - Parameter path: API endpoint path (e.g., "/teams" or "teams")
    /// - Parameter queryParameters: Optional query parameters to append
    /// - Returns: Full URL string with version parameter
    func url(for path: String, queryParameters: [String: String]? = nil) -> String {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let base = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        
        // Build URL with version parameter
        let urlString = "\(base)/\(cleanPath)"
        
        // Add version parameter
        var queryItems = [URLQueryItem(name: "version", value: apiVersion)]
        
        // Add additional query parameters if provided
        if let queryParameters = queryParameters {
            queryItems.append(contentsOf: queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) })
        }
        
        // Build query string
        var components = URLComponents(string: urlString)
        components?.queryItems = queryItems
        
        return components?.url?.absoluteString ?? urlString
    }
}

// MARK: - Errors

enum APIConfigurationError: LocalizedError {
    case missingInfoPlist
    case missingBaseURL
    case missingAPIKey
    
    var errorDescription: String? {
        switch self {
        case .missingInfoPlist:
            return "Info.plist not found in bundle"
        case .missingBaseURL:
            return "API_BASE_URL_PLIST_KEY not found in Info.plist or is empty. Please configure Config.xcconfig"
        case .missingAPIKey:
            return "API_KEY_PLIST_KEY not found in Info.plist or is empty. Please configure Config.xcconfig with your actual API key"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .missingInfoPlist:
            return "Ensure the app bundle is properly configured"
        case .missingBaseURL, .missingAPIKey:
            return """
            1. Copy Config.example.xcconfig to Config.xcconfig
            2. Update Config.xcconfig with your actual API credentials
            3. Ensure Config.xcconfig is added to your Xcode project
            4. Link Config.xcconfig to your build configurations in Xcode project settings
            5. Add API_BASE_URL_PLIST_KEY and API_KEY_PLIST_KEY to Info.plist with values from $(API_BASE_URL) and $(API_KEY)
            """
        }
    }
}
