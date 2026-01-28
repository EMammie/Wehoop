//
//  CacheService.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Protocol for cache operations
protocol CacheService {
    func set<T: Codable>(_ value: T, forKey key: String, expiration: TimeInterval?)
    func get<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    func remove(forKey key: String)
    func clear()
    
    /// Check if a cache entry is stale (doesn't exist or is older than maxAge)
    /// - Parameters:
    ///   - key: The cache key to check
    ///   - maxAge: Maximum age in seconds before considering the entry stale
    /// - Returns: `true` if the entry doesn't exist or is older than maxAge, `false` otherwise
    func isStale(forKey key: String, maxAge: TimeInterval) -> Bool
}
