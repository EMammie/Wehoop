import Foundation

/// A small cache of encoded values: memory, plus an optional disk tier (the schedule and
/// teams survive a relaunch). Concurrent loads of one key share one request.
public actor Cache {
    public enum StalePolicy: Sendable {
        /// A failed load throws.
        case never
        /// A failed load returns the last stored value of any age, if there is one.
        case onFailure
    }

    private struct Entry {
        let data: Data
        let storedAt: Date
    }

    private let directory: URL?
    private let now: @Sendable () -> Date
    private var memory: [String: Entry] = [:]
    private var inFlight: [String: Task<Data, any Error>] = [:]

    /// - Parameter directory: where the disk tier lives (created on first write); nil keeps
    ///   everything in memory.
    public init(directory: URL?, now: @escaping @Sendable () -> Date = { Date() }) {
        self.directory = directory
        self.now = now
    }

    /// The value stored under `key` if younger than `maxAge`, else `load()`'s result (stored).
    public func value<Value: Codable & Sendable>(
        _ type: Value.Type = Value.self,
        key: String,
        maxAge: TimeInterval,
        stale: StalePolicy = .never,
        load: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        let decoder = JSONDecoder()
        if let entry = entry(for: key), now().timeIntervalSince(entry.storedAt) < maxAge,
           let value = try? decoder.decode(Value.self, from: entry.data) {
            return value
        }
        let task: Task<Data, any Error>
        if let running = inFlight[key] {
            task = running
        } else {
            task = Task { try JSONEncoder().encode(try await load()) }
            inFlight[key] = task
        }
        do {
            let data = try await task.value
            if inFlight[key] == task {
                inFlight[key] = nil
                store(data, for: key)
            }
            return try decoder.decode(Value.self, from: data)
        } catch {
            if inFlight[key] == task { inFlight[key] = nil }
            if stale == .onFailure, let entry = entry(for: key),
               let value = try? decoder.decode(Value.self, from: entry.data) {
                return value
            }
            throw error
        }
    }

    /// Drops `key` from both tiers.
    public func remove(_ key: String) {
        memory[key] = nil
        if let url = fileURL(for: key) { try? FileManager.default.removeItem(at: url) }
    }

    private func entry(for key: String) -> Entry? {
        if let entry = memory[key] { return entry }
        guard let url = fileURL(for: key), let data = try? Data(contentsOf: url),
              let storedAt = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        else { return nil }
        let entry = Entry(data: data, storedAt: storedAt)
        memory[key] = entry
        return entry
    }

    private func store(_ data: Data, for key: String) {
        let storedAt = now()
        memory[key] = Entry(data: data, storedAt: storedAt)
        guard let directory, let url = fileURL(for: key) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
        try? FileManager.default.setAttributes([.modificationDate: storedAt], ofItemAtPath: url.path)
    }

    /// One file per key; the key is percent-encoded so it cannot leave the directory.
    private func fileURL(for key: String) -> URL? {
        guard let directory, let name = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else { return nil }
        return directory.appending(path: name + ".json")
    }
}
