import Contracts
import Domain
import Foundation
import LiveEngine
import TestSupport
import WehoopData

/// Fixture mode (`-WehoopFixtures`): the committed golden games, replayed through the same
/// `GameSyncRegistry` and repositories as live mode, with no network. A golden game plays
/// out at `interval` per message; open one with `wehoop://game/<id>` (ids in `gameIds`).
final class FixtureBackend: Sendable {
    let liveGames: GameSyncRegistry
    let leagues: any LeagueRepository
    let schedule: any ScheduleRepository

    init(interval: Duration = .milliseconds(120)) {
        let games = Self.goldenIds()
        liveGames = GameSyncRegistry { gameId in
            guard let golden = games[gameId], let server = try? FakeGameServer(game: golden) else {
                return GameSync(gameId: gameId, transport: EmptyTransport(), api: UnavailableAPI())
            }
            return GameSync(
                gameId: gameId,
                transport: PacedTransport(inner: FakeTransport(server: server), interval: interval),
                api: FakeGameAPI(server: server),
                closingSettle: .seconds(1)
            )
        }
        let cache = Cache(directory: nil)
        leagues = LeagueRepositoryImpl(rows: FixtureRows(), cache: cache)
        schedule = ScheduleRepositoryImpl(rows: FixtureRows(), cache: cache)
    }

    /// Game id → golden game, for every golden game whose snapshot decodes.
    static func goldenIds() -> [String: GoldenGame] {
        var ids: [String: GoldenGame] = [:]
        for game in GoldenGame.allCases {
            if let snapshot = try? Golden.snapshot(game) { ids[snapshot.game.id] = game }
        }
        return ids
    }
}

/// The golden schedule and leagues rows.
struct FixtureRows: RowSource {
    func schedule(league: String, from: Date, to: Date) async throws -> [ScheduleRow] {
        try Golden.schedule(LeagueCode(rawValue: league))
    }

    func scheduleRow(id: String) async throws -> ScheduleRow? {
        for league in LeagueCode.known {
            if let row = try Golden.schedule(league).first(where: { $0.id == id }) { return row }
        }
        return nil
    }

    func leagues() async throws -> [LeagueRow] {
        try Golden.leagues()
    }
}

/// Delivers another transport's messages `interval` apart, so a golden game plays out.
struct PacedTransport: GameTransport {
    let inner: any GameTransport
    let interval: Duration

    func messages(gameId: String) -> AsyncStream<TransportMessage> {
        let upstream = inner.messages(gameId: gameId)
        let interval = interval
        return AsyncStream { continuation in
            let task = Task {
                for await message in upstream {
                    guard (try? await Task.sleep(for: interval)) != nil else { break }
                    continuation.yield(message)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// For an id fixture mode does not know: the screen shows its failed state.
struct EmptyTransport: GameTransport {
    func messages(gameId: String) -> AsyncStream<TransportMessage> { AsyncStream { $0.finish() } }
}

struct UnavailableAPI: GameAPI {
    func snapshot(gameId: String) async throws -> Snapshot { throw URLError(.resourceUnavailable) }
    func changes(gameId: String, after: Int, limit: Int) async throws -> ChangesPage { throw URLError(.resourceUnavailable) }
}
