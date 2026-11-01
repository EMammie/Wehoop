import Contracts
import Foundation
import Testing
@testable import LiveEngine
import TestSupport

/// M5 S2 acceptance: the reconnect contract over a fake server that publishes the golden
/// stream in seq order while the subscription drops, repeats and reorders deliveries.
struct GameSyncTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func sync(_ server: FakeGameServer) async -> GameSync {
        GameSync(
            gameId: server.gameId, transport: FakeTransport(server: server), api: FakeGameAPI(server: server),
            clock: FakeClock(now: now, onSleep: { await server.publishAll() }), closingSettle: .zero
        )
    }

    private func expectFoldEqualsFinal(_ sync: GameSync, _ game: GoldenGame) async throws {
        let final = try Golden.snapshot(game)
        let expected = LiveGameState(snapshot: final)
        let folded = try #require(await sync.foldedAtClose)
        #expect(folded.lastSeq == final.seq)
        #expect(folded.game == expected.game, "\(game): folded durable state differs from the final snapshot")
        #expect(folded.clock == expected.clock, "\(game): the final pulse's clock equals the snapshot's")
        #expect(folded.game.events.map(\.providerEventId) == final.events.map(\.providerEventId))
        #expect(await sync.state?.game == expected.game)
    }

    @Test("Drops, duplicates, reorders and reconnects fold to the final snapshot (decoded-equal)", arguments: GoldenGame.allCases)
    func faultyReplay(game: GoldenGame) async throws {
        let count = try Golden.changes(game).count
        let faults = DeliveryFaults.seeded(seed: 0x5EED_0002, count: count, rate: 0.04, reconnects: 2)
        let server = try FakeGameServer(game: game, faults: faults)
        let sync = await sync(server)
        try await sync.run()
        try await expectFoldEqualsFinal(sync, game)
        let stats = await sync.stats
        #expect(stats.snapshots == 2) // first + final
        #expect(stats.resnapshots == 0)
        if game == .wnba {
            #expect(faults.drop.count > 20 && faults.duplicate.count > 20 && faults.delayOne.count > 20)
            #expect(stats.gaps > 0 && stats.duplicates > 0 && stats.reconnects == 2)
            #expect(stats.catchUpReasons.contains(.reconnect))
        }
    }

    @Test("Stats that arrive after closed (the extended game's finals, seq 70-102) are folded before the final snapshot")
    func closingStatsFolded() async throws {
        let server = try FakeGameServer(game: .ncaawbExtended)
        let sync = await sync(server)
        try await sync.run()
        let folded = try #require(await sync.foldedAtClose)
        let final = try Golden.snapshot(.ncaawbExtended)
        #expect(folded.lastSeq == 102 && !folded.game.playerStats.isEmpty)
        #expect(folded.game.playerStats == LiveGameState(snapshot: final).game.playerStats)
        #expect(await sync.stats.catchUpReasons.contains(.closing))
    }

    @Test("A gap pages /changes from the last folded seq")
    func gapPagesChanges() async throws {
        let server = try FakeGameServer(game: .wnba, faults: DeliveryFaults(drop: [10, 11, 12]))
        let sync = await sync(server)
        try await sync.run()
        let calls = await server.changesCalls
        #expect(calls.first == 9) // seq 13 arrived after 9: page from 9
        #expect(await sync.stats.catchUpReasons.first == .gap(after: 9))
        try await expectFoldEqualsFinal(sync, .wnba)
    }

    @Test("Expired history re-snapshots instead of paging what is gone")
    func expiredHistoryResnapshots() async throws {
        let server = try FakeGameServer(game: .wnba, faults: DeliveryFaults(drop: Set(2...700)), retainedFrom: 600)
        let sync = await sync(server)
        try await sync.run()
        let stats = await sync.stats
        #expect(stats.resnapshots == 1)
        #expect(await server.changesCalls.first == 1)
        #expect(await server.snapshotCalls == 3) // first, re-snapshot, final
        #expect(await sync.state?.game == LiveGameState(snapshot: try Golden.snapshot(.wnba)).game)
    }

    @Test("A pulse ahead of the fold catches up: the lost final change is recovered", arguments: GoldenGame.allCases)
    func pulseAheadCatchesUp(game: GoldenGame) async throws {
        let count = try Golden.changes(game).count
        let server = try FakeGameServer(game: game, faults: DeliveryFaults(drop: [count]))
        let sync = await sync(server)
        try await sync.run()
        #expect(await sync.stats.catchUpReasons.first == .pulseAhead(latestSeq: count))
        try await expectFoldEqualsFinal(sync, game)
    }

    @Test("A reconnect catches up the changes lost while disconnected")
    func reconnectCatchesUp() async throws {
        let server = try FakeGameServer(
            game: .wnba, faults: DeliveryFaults(drop: Set(101...140), reconnectAfter: [140])
        )
        let sync = await sync(server)
        try await sync.run()
        let stats = await sync.stats
        #expect(stats.catchUpReasons.first == .reconnect && stats.gaps == 0)
        #expect(await server.changesCalls.first == 100)
        try await expectFoldEqualsFinal(sync, .wnba)
    }

    @Test("Changes buffered while the first snapshot loads are folded after it")
    func bufferedBeforeSnapshot() async throws {
        let server = try FakeGameServer(game: .wnba, prefetch: 50)
        let sync = await sync(server)
        try await sync.run()
        let stats = await sync.stats
        #expect(stats.duplicates == 0 && stats.gaps == 0)
        #expect(await server.changesCalls == [1233]) // only the closing catch-up
        try await expectFoldEqualsFinal(sync, .wnba)
    }

    @Test("Buffered changes at or below the snapshot's seq are dropped as duplicates")
    func bufferedBehindSnapshot() async throws {
        let server = try FakeGameServer(game: .ncaawb, firstSnapshot: .final, prefetch: 30)
        let sync = await sync(server)
        try await sync.run()
        #expect(await sync.stats.applied == 0)
        #expect(await sync.state?.game == LiveGameState(snapshot: try Golden.snapshot(.ncaawb)).game)
    }

    @Test("A game already closed when opened is the snapshot only")
    func closedAtOpen() async throws {
        let server = try FakeGameServer(game: .unrivaledElam, firstSnapshot: .final)
        let sync = await sync(server)
        try await sync.run()
        #expect(await server.snapshotCalls == 1)
        #expect(await server.changesCalls.isEmpty)
        #expect(await sync.state?.isClosed == true)
    }

    @Test("Foreground catch-up pages from the last folded seq")
    func foregroundCatchUp() async throws {
        let server = try FakeGameServer(game: .unrivaledElam, firstSnapshot: .final)
        let sync = await sync(server)
        try await sync.run()
        try await sync.catchUp()
        #expect(await server.changesCalls == [12])
        #expect(await sync.stats.catchUpReasons == [.foreground])
    }

    @Test("Updates are published in order and end with the final snapshot")
    func updates() async throws {
        let server = try FakeGameServer(game: .unrivaledElam)
        let sync = await sync(server)
        async let causes: [SyncUpdate.Cause] = sync.updates.reduce(into: []) { $0.append($1.cause) }
        try await sync.run()
        let all = await causes
        #expect(all.first == .snapshot && all.last == .finalSnapshot)
        #expect(all.filter { $0 == .change }.count == 12)
    }

    @Test("The clock model uses the snapshot's server time as the offset")
    func clockOffset() async throws {
        let server = try FakeGameServer(game: .wnba, firstSnapshot: .final)
        let sync = await sync(server)
        try await sync.run()
        let final = try Golden.snapshot(.wnba)
        let serverTime = try #require(ISODate.parse(final.serverTime))
        #expect(await sync.serverOffset == serverTime.timeIntervalSince(now))
        #expect(await sync.clockModel()?.display(at: now) == "0.0")
    }
}
