import Contracts
import Domain
import Foundation
import LiveEngine
import Realtime
import Supabase
import Synchronization
import Testing
@testable import WehoopData

/// M5 S3 acceptance against the dev stack (never the trial stack): wehoop-api `pnpm dev:api`
/// and a `pnpm dev:worker --replay-file …` replay of a game the stack has not seen.
/// Skipped unless `WEHOOP_INTEGRATION=1`; needs `WEHOOP_API_URL`, `WEHOOP_SUPABASE_URL`,
/// `WEHOOP_SUPABASE_ANON_KEY`, and `WEHOOP_INTEGRATION_PROVIDER_GAME` (the replay's
/// provider game id) for the replay test. Prints `S3-EVIDENCE` lines for the evidence file.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["WEHOOP_INTEGRATION"] == "1"), .serialized)
struct DevStackIntegrationTests {
    private let env = ProcessInfo.processInfo.environment

    private func services() throws -> (SupabaseServices, BackendConfiguration) {
        let config = try BackendConfiguration.from(environment: env)
        #expect(config.supabaseURL.port != 55321, "never the trial stack")
        return (SupabaseServices(configuration: config, sessionStorage: .memory), config)
    }

    /// Records what the subscription delivered, for the equal-shapes check.
    final class Tee: GameTransport {
        let inner: any GameTransport
        let changes = Mutex<[GameChange]>([])
        let pulses = Mutex(0)
        init(_ inner: any GameTransport) { self.inner = inner }
        func messages(gameId: String) -> AsyncStream<TransportMessage> {
            let upstream = inner.messages(gameId: gameId)
            return AsyncStream { continuation in
                let task = Task {
                    for await message in upstream {
                        switch message {
                        case .change(let change): changes.withLock { $0.append(change) }
                        case .pulse: pulses.withLock { $0 += 1 }
                        case .reconnected: break
                        }
                        continuation.yield(message)
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }

    @Test("A guest (anonymous) session signs in and is anonymous")
    func guestSession() async throws {
        let (services, _) = try services()
        try await services.auth.ensureSignedIn()
        #expect(await services.auth.isAnonymous)
        #expect(await services.auth.userId != nil)
        print("S3-EVIDENCE guest anonymous=\(await services.auth.isAnonymous)")
    }

    @Test("A guest cannot publish on game:{id}: the REST send is refused and a second guest never receives it")
    func publishRejected() async throws {
        let (publisher, _) = try services()
        let (listener, _) = try services()
        let gameId = UUID().uuidString.lowercased()
        let marker = "s3-forged-\(UUID().uuidString)"
        try await listener.auth.ensureSignedIn()
        try await publisher.auth.ensureSignedIn()

        let heard = Mutex<[String]>([])
        let listening = listener.client.realtimeV2.channel("game:\(gameId)") { $0.isPrivate = true }
        let token = listening.onBroadcast(event: "*") { message in
            heard.withLock { $0.append(String(describing: message)) }
        }
        try await listening.subscribeWithError()

        let sending = publisher.client.realtimeV2.channel("game:\(gameId)") { $0.isPrivate = true }
        try await sending.subscribeWithError()
        var restRefused = false
        do {
            try await sending.httpSend(event: "change", message: ["marker": marker])
        } catch {
            restRefused = true
            print("S3-EVIDENCE publish REST refused: \(error)")
        }
        // The socket path too: a client broadcast on a private channel without an insert policy.
        await sending.broadcast(event: "change", message: ["marker": .string(marker)])
        try await Task.sleep(for: .seconds(3))
        let received = heard.withLock { $0.filter { $0.contains(marker) } }
        #expect(restRefused, "a guest REST broadcast must be refused")
        #expect(received.isEmpty, "the second guest received a forged message")
        print("S3-EVIDENCE publish restRefused=\(restRefused) forgedReceived=\(received.count)")
        _ = token
        await listener.client.realtimeV2.removeChannel(listening)
        await publisher.client.realtimeV2.removeChannel(sending)
    }

    @Test("A replayed game, two views through the registry: one subscription, broadcasts equal /changes, fold equals final")
    func replayFollowed() async throws {
        let provider = try #require(env["WEHOOP_INTEGRATION_PROVIDER_GAME"], "set WEHOOP_INTEGRATION_PROVIDER_GAME")
        let (services, config) = try services()
        try await services.auth.ensureSignedIn()

        let id = try #require(try await gameId(provider: provider, services), "the replay never created the game")
        print("S3-EVIDENCE game \(id) provider \(provider)")

        let api = APIClient(baseURL: config.apiBaseURL)
        let tee = Tee(services.transport)
        let made = Mutex<[GameSync]>([])
        let registry = GameSyncRegistry(grace: .seconds(5)) { gameId in
            let sync = GameSync(gameId: gameId, transport: tee, api: api, closingSettle: .seconds(20))
            made.withLock { $0.append(sync) }
            return sync
        }
        async let viewA: [LiveGameUpdate] = collect(registry.updates(gameId: Game.ID(id)))
        try await Task.sleep(for: .seconds(2))
        async let viewB: [LiveGameUpdate] = collect(registry.updates(gameId: Game.ID(id)))
        let (a, b) = try await (viewA, viewB)

        let started = await registry.started
        #expect(started == 1 && made.withLock { $0.count } == 1, "two views, one subscription")
        let sync = try #require(made.withLock { $0.first })
        let stats = await sync.stats
        let folded = try #require(await sync.foldedAtClose)
        let final = try await api.snapshot(gameId: id)
        let expected = LiveGameState(snapshot: final)
        #expect(folded.lastSeq == final.seq)
        #expect(folded.game == expected.game, "folded stream differs from the final snapshot")
        #expect(a.last?.cause == .final && b.last?.cause == .final)
        #expect(a.last?.game == b.last?.game && a.last?.game.status == .closed)

        // Equal shapes: every change that arrived by broadcast decodes equal to /changes.
        let served = try await allChanges(api, id)
        let broadcast = tee.changes.withLock { $0 }
        let mismatched = broadcast.filter { served[$0.seq] != $0 }
        #expect(!broadcast.isEmpty, "nothing arrived by broadcast")
        #expect(mismatched.isEmpty)
        let seqs = Set(broadcast.map(\.seq))
        print("""
            S3-EVIDENCE replay seq=\(final.seq) status=\(final.game.status.rawValue) \
            score=\(final.game.score.home)-\(final.game.score.away) \
            broadcastChanges=\(broadcast.count) distinct=\(seqs.count) pulses=\(tee.pulses.withLock { $0 }) \
            mismatched=\(mismatched.count) served=\(served.count) viewA=\(a.count) viewB=\(b.count) started=\(started)
            S3-EVIDENCE sync snapshots=\(stats.snapshots) catchUps=\(stats.catchUps) pages=\(stats.pages) \
            received=\(stats.received) \
            applied=\(stats.applied) duplicates=\(stats.duplicates) gaps=\(stats.gaps) reconnects=\(stats.reconnects) \
            reasons=\(stats.catchUpReasons) foldEqualsFinal=\(folded.game == expected.game)
            """)
    }

    /// The replay creates the games row on its first document; waits up to a minute for it.
    private func gameId(provider: String, _ services: SupabaseServices) async throws -> String? {
        struct Row: Decodable { let id: String }
        for _ in 0..<120 {
            let rows: [Row] = try await services.client.from("games").select("id")
                .eq("provider_game_id", value: provider).execute().value
            if let id = rows.first?.id { return id }
            try await Task.sleep(for: .milliseconds(500))
        }
        return nil
    }

    private func allChanges(_ api: APIClient, _ id: String) async throws -> [Int: GameChange] {
        var served: [Int: GameChange] = [:]
        var after = 0
        while true {
            let page = try await api.changes(gameId: id, after: after, limit: 500)
            for change in page.changes { served[change.seq] = change }
            after = page.nextAfter
            if !page.hasMore { return served }
        }
    }

    private func collect(_ stream: AsyncThrowingStream<LiveGameUpdate, any Error>) async throws -> [LiveGameUpdate] {
        var all: [LiveGameUpdate] = []
        for try await update in stream { all.append(update) }
        return all
    }
}
