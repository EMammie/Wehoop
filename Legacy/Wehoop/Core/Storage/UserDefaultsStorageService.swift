//
//  UserDefaultsStorageService.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// UserDefaults-based implementation of StorageService
class UserDefaultsStorageService: StorageService {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        userDefaults.set(data, forKey: key)
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
    
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    func clear() {
        if let suiteName = userDefaults.volatileDomainNames.first(where: { $0.contains("TestDefaults") }) {
            userDefaults.removePersistentDomain(forName: suiteName)
        } else {
            // For standard UserDefaults, remove all keys
            let dictionary = userDefaults.dictionaryRepresentation()
            dictionary.keys.forEach { key in
                userDefaults.removeObject(forKey: key)
            }
        }
    }
}
