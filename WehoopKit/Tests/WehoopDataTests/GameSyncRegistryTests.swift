import Contracts
import Domain
import Foundation
import LiveEngine
import Synchronization
import Testing
import TestSupport
@testable import WehoopData

/// M5 decision 7's S3 row: one `GameSync` per game however many views follow it.
struct GameSyncRegistryTests {
    /// Delivers the first `limit` messages of the fake server, then stays open (a live game).
    struct OpenTransport: GameTransport {
        let server: FakeGameServer
        let limit: Int
        func messages(gameId: String) -> AsyncStream<TransportMessage> {
            let server = server
            let (stream, continuation) = AsyncStream.makeStream(of: TransportMessage.self)
            let task = Task {
                for _ in 0..<limit {
                    guard let message = await server.nextDelivery() else { break }
                    continuation.yield(message)
                }
                // Stay subscribed until the follower goes away.
                while !Task.isCancelled { try? await Task.sleep(for: .milliseconds(5)) }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
            return stream
        }
    }

    /// Counts subscriptions so a reuse can be told from a resubscribe.
    final class Subscriptions: Sendable {
        let count = Mutex(0)
        var value: Int { count.withLock { $0 } }
    }

    private let fixed = Date(timeIntervalSince1970: 1_800_000_000)

    /// A new fake server for one subscription (the goldens are bundled, so this cannot fail at runtime).
    private static func freshServerOrDie(_ game: GoldenGame) -> FakeGameServer {
        guard let server = try? FakeGameServer(game: game) else { fatalError("golden fixtures for \(game) are missing") }
        return server
    }

    private func registry(
        game: GoldenGame, open limit: Int?, grace: GateClock, subscriptions: Subscriptions = Subscriptions()
    ) throws -> (GameSyncRegistry, Game.ID) {
        let fixed = fixed
        let gameId = try Golden.snapshot(game).game.id
        let registry = GameSyncRegistry(grace: .seconds(30), clock: grace) { id in
            subscriptions.count.withLock { $0 += 1 }
            // A fresh fake server per subscription, as a real resubscribe would be.
            let server = Self.freshServerOrDie(game)
            let transport: any GameTransport = limit.map { OpenTransport(server: server, limit: $0) }
                ?? FakeTransport(server: server)
            return GameSync(
                gameId: id, transport: transport, api: FakeGameAPI(server: server),
                clock: FakeClock(now: fixed, onSleep: { await server.publishAll() }), closingSettle: .zero
            )
        }
        return (registry, Game.ID(gameId))
    }

    /// Follows until an update with `seq >= target` arrives; returns the updates seen.
    private func follow(_ registry: GameSyncRegistry, _ id: Game.ID, until target: Int) async throws -> [LiveGameUpdate] {
        var seen: [LiveGameUpdate] = []
        for try await update in registry.updates(gameId: id) {
            seen.append(update)
            if update.game.seq >= target { break }
        }
        return seen
    }

    @Test("Two views of one live game share one subscription and see the same state")
    func sharedWhileLive() async throws {
        let gate = GateClock()
        let subs = Subscriptions()
        let (registry, id) = try registry(game: .wnba, open: 50, grace: gate, subscriptions: subs)
        async let a = follow(registry, id, until: 40)
        async let b = follow(registry, id, until: 40)
        let (seenA, seenB) = try await (a, b)
        let started = await registry.started
        #expect(subs.value == 1 && started == 1)
        #expect(seenA.last?.game.seq == seenB.last?.game.seq)
    }

    @Test("Game → Player → Team → Game within the grace period reuses the folded state at once")
    func reuseWithinGrace() async throws {
        let gate = GateClock()
        let subs = Subscriptions()
        let (registry, id) = try registry(game: .wnba, open: 50, grace: gate, subscriptions: subs)
        let first = try await follow(registry, id, until: 40)
        let reached = try #require(first.last?.game.seq)
        // The first view went away (the loop broke and its stream ended); the grace timer runs.
        #expect(await eventually { gate.sleeping == 1 })
        let back = try await follow(registry, id, until: reached)
        #expect(back.first?.game.seq ?? 0 >= reached, "the returning view gets the latest state as its first value")
        #expect(subs.value == 1, "no resubscribe, no second first snapshot")
        let active = await registry.activeGameIds
        #expect(active == [id.rawValue])
    }

    @Test("After the grace period with no view the game is stopped; the next view starts it afresh")
    func expiresAfterGrace() async throws {
        let gate = GateClock()
        let subs = Subscriptions()
        let (registry, id) = try registry(game: .wnba, open: 30, grace: gate, subscriptions: subs)
        _ = try await follow(registry, id, until: 20)
        #expect(await eventually { gate.sleeping == 1 })
        gate.release()
        #expect(await eventually { await registry.activeGameIds.isEmpty })
        _ = try await follow(registry, id, until: 20)
        #expect(subs.value == 2)
    }

    @Test("A closed game finishes every view with the final state; a view within the grace gets it without a new run")
    func closedGame() async throws {
        let gate = GateClock()
        let subs = Subscriptions()
        let (registry, id) = try registry(game: .unrivaledElam, open: nil, grace: gate, subscriptions: subs)
        var all: [LiveGameUpdate] = []
        for try await update in registry.updates(gameId: id) { all.append(update) }
        let final = try Golden.snapshot(.unrivaledElam)
        #expect(all.last?.cause == .final && all.last?.game.seq == final.seq && all.last?.game.status == .closed)
        var again: [LiveGameUpdate] = []
        for try await update in registry.updates(gameId: id) { again.append(update) }
        #expect(again.map(\.cause) == [.final] && subs.value == 1)
    }

    @Test("A run that fails ends every view with the error and is not kept")
    func failureNotKept() async throws {
        struct Ends: GameTransport {
            func messages(gameId: String) -> AsyncStream<TransportMessage> { AsyncStream { $0.finish() } }
        }
        let fixed = fixed
        let subs = Subscriptions()
        let registry = GameSyncRegistry(grace: .seconds(30), clock: GateClock()) { id in
            subs.count.withLock { $0 += 1 }
            // A fresh server per run: its first snapshot is the pre-game one, so the run waits for close.
            let server = Self.freshServerOrDie(.wnba)
            return GameSync(
                gameId: id, transport: Ends(), api: FakeGameAPI(server: server), clock: FakeClock(now: fixed), closingSettle: .zero
            )
        }
        let id = Game.ID(try Golden.snapshot(.wnba).game.id)
        await #expect(throws: GameSyncError.transportEnded) {
            for try await _ in registry.updates(gameId: id) {}
        }
        let active = await registry.activeGameIds
        #expect(active.isEmpty)
        await #expect(throws: GameSyncError.transportEnded) {
            for try await _ in registry.updates(gameId: id) {}
        }
        #expect(subs.value == 2)
    }

    @Test("A view that goes away before it is registered never leaves a game running or a token behind")
    func endedBeforeFollow() async throws {
        let gate = GateClock()
        let (registry, id) = try registry(game: .wnba, open: 10, grace: gate)
        for _ in 0..<50 {
            _ = registry.updates(gameId: id) // dropped at once: its termination races its follow
        }
        #expect(await eventually { await registry.trackedTokens == 0 })
        let started = await registry.started
        // A follow that won the race started the game, and its grace timer is waiting.
        if started > 0 { #expect(await eventually { gate.sleeping == 1 }) }
        gate.release()
        #expect(await eventually { await registry.activeGameIds.isEmpty })
    }

    @Test("catchUpAll pages /changes for followed games and skips ended ones")
    func catchUpAll() async throws {
        let gate = GateClock()
        let servers = Mutex<[FakeGameServer]>([])
        let fixed = fixed
        let open = GameSyncRegistry(grace: .seconds(30), clock: gate) { id in
            let server = Self.freshServerOrDie(.wnba)
            servers.withLock { $0.append(server) }
            return GameSync(
                gameId: id, transport: OpenTransport(server: server, limit: 30), api: FakeGameAPI(server: server),
                clock: FakeClock(now: fixed), closingSettle: .zero
            )
        }
        let id = Game.ID(try Golden.snapshot(.wnba).game.id)
        let consumer = Task { for try await _ in open.updates(gameId: id) {} }
        #expect(await eventually { await open.started == 1 })
        let server = try #require(servers.withLock { $0.first })
        #expect(await eventually { await server.delivered >= 30 })
        let before = await server.changesCalls.count
        let failures = await open.catchUpAll()
        #expect(failures.isEmpty)
        #expect(await server.changesCalls.count == before + 1)
        consumer.cancel()

        let (closed, closedId) = try registry(game: .unrivaledElam, open: nil, grace: GateClock())
        for try await _ in closed.updates(gameId: closedId) {}
        #expect(await closed.catchUpAll().isEmpty) // ended: nothing to page, nothing failed
    }
}
