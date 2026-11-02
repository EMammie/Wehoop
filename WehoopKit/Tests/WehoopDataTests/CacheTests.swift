import Foundation
import Synchronization
import Testing
@testable import WehoopData

struct CacheTests {
    private final class Counter: Sendable {
        let value = Mutex(0)
        func next() -> Int { value.withLock { $0 += 1; return $0 } }
        var count: Int { value.withLock { $0 } }
    }

    private final class Now: Sendable {
        let date = Mutex(Date(timeIntervalSince1970: 1_800_000_000))
        func advance(_ seconds: TimeInterval) { date.withLock { $0 += seconds } }
        var value: Date { date.withLock { $0 } }
    }

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "wehoop-cache-\(UUID().uuidString)")
    }

    @Test("A value younger than maxAge is served without loading; an older one is reloaded")
    func freshness() async throws {
        let now = Now()
        let cache = Cache(directory: nil, now: { now.value })
        let loads = Counter()
        let first = try await cache.value(Int.self, key: "k", maxAge: 30) { loads.next() }
        now.advance(29)
        let second = try await cache.value(Int.self, key: "k", maxAge: 30) { loads.next() }
        now.advance(2)
        let third = try await cache.value(Int.self, key: "k", maxAge: 30) { loads.next() }
        #expect([first, second, third] == [Int](arrayLiteral: 1, 1, 2))
    }

    @Test("Concurrent loads of one key share one request")
    func coalescing() async throws {
        let cache = Cache(directory: nil)
        let loads = Counter()
        let gate = AsyncStream<Void>.makeStream()
        async let a = cache.value(Int.self, key: "k", maxAge: 60) {
            for await _ in gate.stream { break }
            return loads.next()
        }
        async let b = cache.value(Int.self, key: "k", maxAge: 60) { loads.next() }
        try await Task.sleep(for: .milliseconds(50))
        gate.continuation.yield()
        let (x, y) = try await (a, b)
        #expect(x == 1 && y == 1 && loads.count == 1)
    }

    @Test("With .onFailure a failed reload returns the stored value; with .never it throws")
    func staleOnFailure() async throws {
        let now = Now()
        let cache = Cache(directory: nil, now: { now.value })
        _ = try await cache.value(Int.self, key: "k", maxAge: 1) { 7 }
        now.advance(10)
        struct Down: Error {}
        let stale = try await cache.value(Int.self, key: "k", maxAge: 1, stale: .onFailure) { throw Down() }
        #expect(stale == 7)
        await #expect(throws: Down.self) {
            try await cache.value(Int.self, key: "k", maxAge: 1, stale: .never) { throw Down() }
        }
    }

    @Test("The disk tier survives a new Cache (a relaunch), and a key with slashes stays inside its directory")
    func diskTier() async throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        _ = try await Cache(directory: dir).value([String].self, key: "../schedule:wnba/2026", maxAge: 60) { ["a", "b"] }
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(files.count == 1 && !files[0].contains("/"))
        struct Offline: Error {}
        let relaunched = try await Cache(directory: dir).value([String].self, key: "../schedule:wnba/2026", maxAge: 60) { throw Offline() }
        #expect(relaunched == ["a", "b"])
    }

    @Test("Disk entries older than diskMaxAge are pruned on a later write; memory keeps at most maxEntries")
    func pruning() async throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let now = Now()
        let cache = Cache(directory: dir, maxEntries: 2, diskMaxAge: 7 * 24 * 3600, now: { now.value })
        _ = try await cache.value(Int.self, key: "old", maxAge: 60) { 1 }
        now.advance(8 * 24 * 3600)
        _ = try await cache.value(Int.self, key: "new", maxAge: 60) { 2 }
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(files == ["new.json"])
        let memoryOnly = Cache(directory: nil, maxEntries: 2, now: { now.value })
        let loads = Counter()
        for key in ["a", "b", "c"] {
            now.advance(1)
            _ = try await memoryOnly.value(Int.self, key: key, maxAge: 3600) { loads.next() }
        }
        _ = try await memoryOnly.value(Int.self, key: "a", maxAge: 3600) { loads.next() }
        #expect(loads.count == 4, "the oldest entry was evicted and reloaded")
    }
}
