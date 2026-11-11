import Contracts
import Domain
import Foundation
import LiveEngine
import TestSupport
import WehoopData

/// Fixture mode (`-WehoopFixtures`): the committed golden games, replayed through the same
/// `GameSyncRegistry`, repositories and scoreboard feed as live mode, with no network.
///
/// - Game screen: a golden game plays out at `interval` per message from its first change;
///   open one with `wehoop://game/<id>` (ids in `goldenIds`).
/// - Scores tab: `ScoreboardScript` lays every league's golden rows out around launch (each
///   league's golden game tips off at launch, one change every `scoreStep`) and the
///   scoreboard channel publishes what moved every `scoreTick` (the backend's 5 s, faster).
///   The list and an opened game are separate replays of the same recording.
/// - Golden games carry the demo label (Replay; Simulated replay for the hand-assembled
///   Unrivaled game), as the demo environment would show them.
final class FixtureBackend: Sendable {
    let liveGames: GameSyncRegistry
    let leagues: any LeagueRepository
    let schedule: any ScheduleRepository
    let liveScores: any LiveScoresSource

    init(
        interval: Duration = .milliseconds(120), start: Date = Date(), scoreStep: TimeInterval = 0.2,
        scoreTick: Duration = .seconds(1)
    ) {
        let games = Self.goldenIds()
        liveGames = GameSyncRegistry { gameId in
            guard let golden = games[gameId],
                  let server = try? FakeGameServer(game: golden, replay: ScoreboardScript.label(for: golden)) else {
                return GameSync(gameId: gameId, transport: EmptyTransport(), api: UnavailableAPI())
            }
            return GameSync(
                gameId: gameId,
                transport: PacedTransport(inner: FakeTransport(server: server), interval: interval),
                api: FakeGameAPI(server: server),
                closingSettle: .seconds(1)
            )
        }
        let script = try? ScoreboardScript(start: start, stepInterval: scoreStep)
        let rows = FixtureRows(script: script)
        let cache = Cache(directory: nil)
        leagues = LeagueRepositoryImpl(rows: rows, cache: cache)
        // The rows are in memory and move with time: never cached.
        schedule = ScheduleRepositoryImpl(rows: rows, cache: cache, maxAge: 0)
        liveScores = ScoreboardFeed(
            transport: SharedScoreboardTransport(upstream: FixtureScoreboardTransport(script: script, tick: scoreTick))
        )
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

/// The golden leagues, and the golden schedule as the script has it now.
struct FixtureRows: RowSource {
    let script: ScoreboardScript?

    func schedule(league: String, from: Date, to: Date) async throws -> [ScheduleRow] {
        guard let script else { throw GoldenError.missing("schedule") }
        return try script.rows(league: LeagueCode(rawValue: league), from: from, to: to, at: Date())
    }

    func scheduleRow(id: String) async throws -> ScheduleRow? {
        try script?.row(id: id, at: Date())
    }

    func leagues() async throws -> [LeagueRow] {
        try Golden.leagues()
    }
}

/// `league:{code}:scores` in fixture mode: a join at once, then every `tick` the script's
/// message for what moved since the previous one (none when nothing did), as the backend's
/// sender publishes. Without a script it joins and stays quiet.
struct FixtureScoreboardTransport: ScoreboardTransport {
    let script: ScoreboardScript?
    let tick: Duration

    func messages(league: String) -> AsyncStream<ScoreboardMessage> {
        let (script, tick, code) = (script, tick, LeagueCode(rawValue: league))
        return AsyncStream { continuation in
            let task = Task {
                continuation.yield(.reconnected)
                var last = Date()
                while (try? await Task.sleep(for: tick)) != nil {
                    let now = Date()
                    if let board = script?.scoreboard(league: code, after: last, through: now) {
                        continuation.yield(.scores(board))
                    }
                    last = now
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
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
