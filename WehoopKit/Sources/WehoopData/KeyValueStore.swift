import Foundation
import Synchronization

/// Small persisted values (favorites). `UserDefaults` in the app, memory in tests.
public protocol KeyValueStore: Sendable {
    func data(forKey key: String) -> Data?
    func set(_ data: Data?, forKey key: String)
}

/// `UserDefaults` as a `KeyValueStore`.
public struct UserDefaultsStore: KeyValueStore {
    /// The suite name (nil = standard). Stored instead of the `UserDefaults` instance, which
    /// is not `Sendable`; `UserDefaults(suiteName:)` returns the shared object for a suite.
    private let suiteName: String?

    public init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults { suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard }

    public func data(forKey key: String) -> Data? { defaults.data(forKey: key) }

    public func set(_ data: Data?, forKey key: String) {
        if let data { defaults.set(data, forKey: key) } else { defaults.removeObject(forKey: key) }
    }
}

/// A `KeyValueStore` in memory.
public final class MemoryStore: KeyValueStore {
    private let values: Mutex<[String: Data]>
    public init(_ values: [String: Data] = [:]) { self.values = Mutex(values) }
    public func data(forKey key: String) -> Data? { values.withLock { $0[key] } }
    public func set(_ data: Data?, forKey key: String) { values.withLock { $0[key] = data } }
}
