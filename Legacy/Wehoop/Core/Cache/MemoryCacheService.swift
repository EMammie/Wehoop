//
//  MemoryCacheService.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// In-memory cache implementation
class MemoryCacheService: CacheService {
    private struct CacheEntry {
        let value: Any
        let timestamp: Date
        let expiration: TimeInterval?
    }
    
    private var cacheEntries: [String: CacheEntry] = [:]
    private let lock = NSLock()
    
    func set<T: Codable>(_ value: T, forKey key: String, expiration: TimeInterval?) {
        lock.lock()
        defer { lock.unlock() }
        cacheEntries[key] = CacheEntry(
            value: value,
            timestamp: Date(),
            expiration: expiration
        )
    }
    
    func get<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let entry = cacheEntries[key] else {
            return nil
        }
        
        // Check if entry has expired based on its expiration time
        if let expiration = entry.expiration {
            let age = Date().timeIntervalSince(entry.timestamp)
            if age > expiration {
                // Entry has expired, remove it and return nil
                cacheEntries.removeValue(forKey: key)
                return nil
            }
        }
        
        guard let value = entry.value as? T else {
            return nil
        }
        
        return value
    }
    
    func remove(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        cacheEntries.removeValue(forKey: key)
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        cacheEntries.removeAll()
    }
    
    func isStale(forKey key: String, maxAge: TimeInterval) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        guard let entry = cacheEntries[key] else {
            // Entry doesn't exist, consider it stale
            return true
        }
        
        // Check if entry has expired based on its own expiration time
        if let expiration = entry.expiration {
            let age = Date().timeIntervalSince(entry.timestamp)
            if age > expiration {
                return true
            }
        }
        
        // Check if entry is older than maxAge
        let age = Date().timeIntervalSince(entry.timestamp)
        return age > maxAge
    }
}
