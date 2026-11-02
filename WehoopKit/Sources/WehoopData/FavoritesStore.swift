import Domain
import Foundation

/// The user's favorite players by canonical id, persisted in a `KeyValueStore`, with the
/// one-time migration of the old app's favorites.
///
/// The old app stored `favorite_player_ids`: a JSON array of Sportradar **Unrivaled** player
/// ids (it spoke only to the Unrivaled API) in `UserDefaults.standard`. The migration moves
/// them into a pending list first, then resolves each through `/v1/players/unrivaled:<id>`.
/// An id the backend does not know yet (404) or cannot answer for now (network) stays
/// pending and is tried again on the next launch; nothing the user chose is dropped.
public actor FavoritesStore: FavoritesRepository {
    public static let favoritesKey = "wehoop.favorites.v2"
    public static let pendingKey = "wehoop.favorites.legacyPending"
    public static let legacyKey = "favorite_player_ids"
    /// The league whose provider ids the old app stored.
    public static let legacyLeague = "unrivaled"

    public struct MigrationReport: Sendable, Equatable {
        public let migrated: Int
        public let stillPending: Int
    }

    private let store: any KeyValueStore

    public init(store: any KeyValueStore) {
        self.store = store
    }

    public func favorites() -> [PlayerSummary.ID] {
        read(Self.favoritesKey).map { PlayerSummary.ID($0) }
    }

    public func add(_ id: PlayerSummary.ID) {
        var ids = read(Self.favoritesKey)
        guard !ids.contains(id.rawValue) else { return }
        ids.append(id.rawValue)
        write(ids, Self.favoritesKey)
    }

    public func remove(_ id: PlayerSummary.ID) {
        write(read(Self.favoritesKey).filter { $0 != id.rawValue }, Self.favoritesKey)
    }

    public func contains(_ id: PlayerSummary.ID) -> Bool {
        read(Self.favoritesKey).contains(id.rawValue)
    }

    /// Legacy ids not resolved yet.
    public func pendingLegacyIds() -> [String] { read(Self.pendingKey) }

    /// Resolves every pending legacy id. `resolve` returns the canonical id, nil when the
    /// backend has no such player, or throws when it cannot answer (both stay pending).
    @discardableResult
    public func migrateLegacyFavorites(
        resolve: @Sendable (_ reference: String) async throws -> PlayerSummary.ID?
    ) async -> MigrationReport {
        var pending = read(Self.pendingKey)
        // A legacy value that does not decode is left where it is, never deleted.
        if let data = store.data(forKey: Self.legacyKey), let legacy = try? JSONDecoder().decode([String].self, from: data) {
            for id in legacy where !pending.contains(id) { pending.append(id) }
            // Pending is written before the legacy key goes, so a crash in between loses nothing.
            write(pending, Self.pendingKey)
            store.set(nil, forKey: Self.legacyKey)
        }
        var still: [String] = []
        var migrated = 0
        for legacyId in pending {
            if let canonical = try? await resolve("\(Self.legacyLeague):\(legacyId)") {
                add(canonical)
                migrated += 1
            } else {
                still.append(legacyId)
            }
        }
        write(still, Self.pendingKey)
        return MigrationReport(migrated: migrated, stillPending: still.count)
    }

    private func read(_ key: String) -> [String] {
        guard let data = store.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private func write(_ ids: [String], _ key: String) {
        store.set(ids.isEmpty ? nil : try? JSONEncoder().encode(ids), forKey: key)
    }
}
