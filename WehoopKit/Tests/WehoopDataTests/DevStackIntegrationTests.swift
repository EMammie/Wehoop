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
/// `scripts/cloud-reject-test.sh` runs the guest tests against the hosted project, where
/// `WEHOOP_EXPECT_PRIVATE_ONLY=1` also requires a public join of `game:{id}` to be refused.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["WEHOOP_INTEGRATION"] == "1"), .serialized)
struct DevStackIntegrationTests {
    private let env = ProcessInfo.processInfo.environment

    private func services() throws -> (SupabaseServices, BackendConfiguration) {
        let config = try BackendConfiguration.from(environment: env)
        try #require(config.supabaseURL.port != 55321 && config.apiBaseURL.port != 55321, "never the trial stack")
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

    /// A guest's forged broadcasts on `game:{id}` (REST and socket), heard for by a second guest.
    final class Forgery: Sendable {
        let marker = "s3-forged-\(UUID().uuidString)"
        let heard = Mutex<[String]>([])
        let restError = Mutex<String?>(nil)
        /// Why the publisher's join was refused (only a public join is allowed to fail).
        let joinError = Mutex<String?>(nil)
        var forgedHeard: Int { heard.withLock { $0.filter { $0.contains(marker) }.count } }
        var anyHeard: Int { heard.withLock { $0.count } }
    }

    /// Joins `game:{gameId}` as two fresh guests, listens with one (always private) and forges
    /// with the other, on a private channel or, with `publisherIsPrivate: false`, on the same
    /// topic joined as a public channel.
    private func forge(
        on gameId: String, listenFor seconds: Int, publisherIsPrivate: Bool = true
    ) async throws -> Forgery {
        let (publisher, _) = try services()
        let (listener, _) = try services()
        try await listener.auth.ensureSignedIn()
        try await publisher.auth.ensureSignedIn()
        let forgery = Forgery()
        let listening = listener.client.realtimeV2.channel("game:\(gameId)") { $0.isPrivate = true }
        let token = listening.onBroadcast(event: "*") { message in
            forgery.heard.withLock { $0.append(String(describing: message)) }
        }
        try await listening.subscribeWithError()
        let sending = publisher.client.realtimeV2.channel("game:\(gameId)") { $0.isPrivate = publisherIsPrivate }
        var joined = true
        if publisherIsPrivate {
            try await sending.subscribeWithError()
        } else {
            do {
                try await sending.subscribeWithError()
            } catch {
                joined = false
                forgery.joinError.withLock { $0 = String(describing: error) }
            }
        }
        do {
            try await sending.httpSend(event: "change", message: ["marker": forgery.marker])
        } catch {
            forgery.restError.withLock { $0 = error.localizedDescription }
        }
        // The socket path too: a client broadcast on a channel without an insert policy.
        if joined { await sending.broadcast(event: "change", message: ["marker": .string(forgery.marker)]) }
        try await Task.sleep(for: .seconds(seconds))
        _ = token
        await listener.client.realtimeV2.removeChannel(listening)
        await publisher.client.realtimeV2.removeChannel(sending)
        return forgery
    }

    private func isAuthorizationRefusal(_ description: String?) -> Bool {
        guard let text = description?.lowercased() else { return false }
        return text.contains("unauthorized") || text.contains("forbidden")
    }

    @Test("A guest cannot publish on game:{id}: the REST send is refused as unauthorized and a second guest never receives it")
    func publishRejected() async throws {
        let forgery = try await forge(on: UUID().uuidString.lowercased(), listenFor: 3)
        let refusal = forgery.restError.withLock { $0 }
        #expect(isAuthorizationRefusal(refusal), "expected 401/403, got \(refusal ?? "success")")
        #expect(forgery.forgedHeard == 0, "the second guest received a forged message")
        print("S3-EVIDENCE publish restError=\(refusal ?? "none") forgedReceived=\(forgery.forgedHeard)")
    }

    /// The hole a project's "public access" setting can leave: the topic joined as a public
    /// channel, where no `realtime.messages` policy applies. Whatever the join and the REST send
    /// return, the private subscriber must hear nothing; on a private-only project (the cloud
    /// run) the public join itself must be refused.
    @Test("A guest's public-channel forgery on game:{id} never reaches a private subscriber")
    func publicJoinIsolated() async throws {
        let forgery = try await forge(on: UUID().uuidString.lowercased(), listenFor: 3, publisherIsPrivate: false)
        let joinError = forgery.joinError.withLock { $0 }
        let restError = forgery.restError.withLock { $0 }
        #expect(forgery.forgedHeard == 0, "a public-channel message reached the private subscriber")
        if env["WEHOOP_EXPECT_PRIVATE_ONLY"] == "1" {
            #expect(joinError != nil, "the project accepted a public join of game:{id}")
        }
        print("""
            S3-EVIDENCE publicJoin joined=\(joinError == nil) joinError=\(joinError ?? "none") \
            restError=\(restError ?? "none") forgedReceived=\(forgery.forgedHeard)
            """)
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
        // Forged sends on this game's channel while real changes flow: the listening guest
        // hears the real broadcasts (positive control) and never the forged one.
        async let forged = forge(on: id, listenFor: 15)
        let (a, b, forgery) = try await (viewA, viewB, forged)
        let refusal = forgery.restError.withLock { $0 }
        #expect(forgery.anyHeard > 0, "positive control: the listening guest heard no real broadcast")
        #expect(forgery.forgedHeard == 0 && isAuthorizationRefusal(refusal))

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
            S3-EVIDENCE forgery onReplayChannel heardReal=\(forgery.anyHeard) forgedHeard=\(forgery.forgedHeard) \
            restError=\(refusal ?? "none")
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
