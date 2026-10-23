//
//  StorageService.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Protocol for storage operations
protocol StorageService {
    func save<T: Codable>(_ value: T, forKey key: String) throws
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    func remove(forKey key: String)
    func clear()
}
