//
//  CoreDataStorageService.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import CoreData

/// CoreData-based implementation of StorageService (future implementation)
class CoreDataStorageService: StorageService {
    func save<T: Codable>(_ value: T, forKey key: String) throws {
        // Future implementation
        fatalError("Not yet implemented")
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        // Future implementation
        fatalError("Not yet implemented")
    }
    
    func remove(forKey key: String) {
        // Future implementation
    }
    
    func clear() {
        // Future implementation
    }
}
