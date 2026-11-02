import Contracts
import Domain
import Foundation

/// Rows the repositories read: PostgREST in the app, fixtures in tests.
public protocol RowSource: Sendable {
    func schedule(league: String, from: Date, to: Date) async throws -> [ScheduleRow]
    func scheduleRow(id: String) async throws -> ScheduleRow?
    func leagues() async throws -> [LeagueRow]
}

extension PostgRESTReader: RowSource {}

/// `leagues`, cached a day on disk (it changes when a league is added).
public struct LeagueRepositoryImpl: LeagueRepository {
    let rows: any RowSource
    let cache: Cache

    public init(rows: any RowSource, cache: Cache) {
        self.rows = rows
        self.cache = cache
    }

    public func leagues() async throws -> [League] {
        let rows = rows
        let fetched = try await cache.value([LeagueRow].self, key: "leagues", maxAge: 24 * 3600, stale: .onFailure) {
            try await rows.leagues()
        }
        // The backend's order for the codes this build knows, then any new code by name.
        let known = LeagueCode.known.map(\.rawValue)
        return fetched.sorted { lhs, rhs in
            let l = known.firstIndex(of: lhs.code.rawValue) ?? Int.max
            let r = known.firstIndex(of: rhs.code.rawValue) ?? Int.max
            return l != r ? l < r : lhs.code.rawValue < rhs.code.rawValue
        }
        .map(Mapping.league)
    }
}

/// `v_schedule`, cached briefly (30 s, the live-score poll interval until M4's scores
/// channel) and kept on disk so a relaunch offline still shows the last schedule.
public struct ScheduleRepositoryImpl: ScheduleRepository {
    let rows: any RowSource
    let cache: Cache
    let maxAge: TimeInterval

    public init(rows: any RowSource, cache: Cache, maxAge: TimeInterval = 30) {
        self.rows = rows
        self.cache = cache
        self.maxAge = maxAge
    }

    public func games(league: League.Code, from: Date, to: Date) async throws -> [Game] {
        let rows = rows
        let key = "schedule:\(league.rawValue):\(ISODate.format(from)):\(ISODate.format(to))"
        let fetched = try await cache.value([ScheduleRow].self, key: key, maxAge: maxAge, stale: .onFailure) {
            try await rows.schedule(league: league.rawValue, from: from, to: to)
        }
        return fetched.compactMap(Mapping.game)
    }

    public func game(id: Game.ID) async throws -> Game? {
        let rows = rows
        let fetched = try await cache.value([ScheduleRow].self, key: "game:\(id.rawValue)", maxAge: maxAge, stale: .onFailure) {
            try await rows.scheduleRow(id: id.rawValue).map { [$0] } ?? []
        }
        return fetched.first.flatMap(Mapping.game)
    }
}

/// `/v1/players/:id`.
public struct PlayerRepositoryImpl: PlayerRepository {
    let api: APIClient

    public init(api: APIClient) {
        self.api = api
    }

    public func player(id: PlayerSummary.ID) async throws -> PlayerSummary {
        Mapping.player(try await api.player(id: id.rawValue))
    }

    /// Resolves `<league>:<providerId>` to the canonical id; nil when the backend has no
    /// such player (the favorites migration keeps it pending).
    public func canonicalId(reference: String) async throws -> PlayerSummary.ID? {
        do {
            return PlayerSummary.ID(try await api.player(id: reference).player.id)
        } catch APIError.notFound {
            return nil
        }
    }
}
