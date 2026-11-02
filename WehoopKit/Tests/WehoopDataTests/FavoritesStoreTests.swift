import Domain
import Foundation
import Synchronization
import Testing
@testable import WehoopData

struct FavoritesStoreTests {
    private func legacy(_ ids: [String]) throws -> MemoryStore {
        MemoryStore([FavoritesStore.legacyKey: try JSONEncoder().encode(ids)])
    }

    @Test("Add is idempotent, remove removes, order is kept")
    func basics() async {
        let store = FavoritesStore(store: MemoryStore())
        await store.add(PlayerSummary.ID("p1"))
        await store.add(PlayerSummary.ID("p2"))
        await store.add(PlayerSummary.ID("p1"))
        #expect(await store.favorites() == [PlayerSummary.ID("p1"), PlayerSummary.ID("p2")])
        await store.remove(PlayerSummary.ID("p1"))
        #expect(await store.favorites() == [PlayerSummary.ID("p2")])
        #expect(await !store.contains(PlayerSummary.ID("p1")))
    }

    @Test("Legacy Unrivaled ids are resolved through unrivaled:<id>; unknown and unreachable ones stay pending")
    func migration() async throws {
        let kv = try legacy(["sr-a", "sr-b", "sr-c"])
        let store = FavoritesStore(store: kv)
        struct Offline: Error {}
        let asked = Mutex<[String]>([])
        let report = await store.migrateLegacyFavorites { reference in
            asked.withLock { $0.append(reference) }
            switch reference {
            case "unrivaled:sr-a": return PlayerSummary.ID("canon-a")
            case "unrivaled:sr-b": return nil // the backend has no such player yet
            default: throw Offline()
            }
        }
        #expect(asked.withLock { $0 } == ["unrivaled:sr-a", "unrivaled:sr-b", "unrivaled:sr-c"])
        #expect(report == .init(migrated: 1, stillPending: 2))
        #expect(await store.favorites() == [PlayerSummary.ID("canon-a")])
        #expect(await store.pendingLegacyIds() == ["sr-b", "sr-c"])
        #expect(kv.data(forKey: FavoritesStore.legacyKey) == nil, "the legacy key is consumed once pending holds its ids")
    }

    @Test("A later launch resolves what was pending and keeps earlier favorites")
    func retryLater() async throws {
        let kv = try legacy(["sr-a", "sr-b"])
        let store = FavoritesStore(store: kv)
        await store.migrateLegacyFavorites { $0 == "unrivaled:sr-a" ? PlayerSummary.ID("canon-a") : nil }
        let second = await FavoritesStore(store: kv).migrateLegacyFavorites { _ in PlayerSummary.ID("canon-b") }
        #expect(second == .init(migrated: 1, stillPending: 0))
        #expect(await FavoritesStore(store: kv).favorites() == [PlayerSummary.ID("canon-a"), PlayerSummary.ID("canon-b")])
    }

    @Test("Two legacy ids of one merged player become one favorite")
    func mergedLegacyIds() async throws {
        let store = FavoritesStore(store: try legacy(["sr-old", "sr-new"]))
        await store.migrateLegacyFavorites { _ in PlayerSummary.ID("survivor") }
        #expect(await store.favorites() == [PlayerSummary.ID("survivor")])
    }

    @Test("A legacy value that does not decode is left untouched")
    func undecodableLegacy() async {
        let kv = MemoryStore([FavoritesStore.legacyKey: Data("not json".utf8)])
        let report = await FavoritesStore(store: kv).migrateLegacyFavorites { _ in PlayerSummary.ID("x") }
        #expect(report == .init(migrated: 0, stillPending: 0))
        #expect(kv.data(forKey: FavoritesStore.legacyKey) == Data("not json".utf8))
    }
}
