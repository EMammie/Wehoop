import Domain
import Foundation
import LiveEngine

/// The keyed owner of live games (M5 plan decision 7): one `GameSync` per game however many
/// views follow it. Game(g1) → Player → Team → Game(g1) reuses one subscription and one
/// folded state instead of resubscribing and re-snapshotting. A game nobody follows any more
/// is kept for `grace` and then stopped. A late follower gets the latest state at once.
public actor GameSyncRegistry: LiveGameSource {
    public typealias MakeSync = @Sendable (_ gameId: String) -> GameSync

    private final class Entry {
        let sync: GameSync
        var run: Task<Void, Never>?
        var pump: Task<Void, Never>?
        var followers: [UUID: AsyncThrowingStream<LiveGameUpdate, any Error>.Continuation] = [:]
        var latest: LiveGameUpdate?
        /// Set when the game's run ended: nil = finished normally, else the error.
        var ended: (any Error)??
        var expiry: Task<Void, Never>?
        init(sync: GameSync) { self.sync = sync }
    }

    private let makeSync: MakeSync
    private let grace: Duration
    private let clock: any SyncClock
    private var entries: [String: Entry] = [:]
    /// Followers whose `follow` has run; each stream's termination removes its token once.
    private var followed: Set<UUID> = []
    /// Followers whose stream ended before their `follow` ran (the two hops race).
    private var endedEarly: Set<UUID> = []

    /// Games started since launch (each start is one subscription and one first snapshot).
    public private(set) var started = 0

    public init(grace: Duration = .seconds(30), clock: any SyncClock = SystemClock(), makeSync: @escaping MakeSync) {
        self.grace = grace
        self.clock = clock
        self.makeSync = makeSync
    }

    /// Wires the registry to a transport and an API (the app's case).
    public init(transport: any GameTransport, api: any GameAPI, grace: Duration = .seconds(30), clock: any SyncClock = SystemClock()) {
        self.init(grace: grace, clock: clock) { gameId in
            GameSync(gameId: gameId, transport: transport, api: api, clock: clock)
        }
    }

    nonisolated public func updates(gameId: Game.ID) -> AsyncThrowingStream<LiveGameUpdate, any Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: LiveGameUpdate.self)
        let token = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.unfollow(gameId.rawValue, token: token) }
        }
        Task { await self.follow(gameId.rawValue, token: token, continuation: continuation) }
        return stream
    }

    /// Foreground or a network change: every followed game pages `/changes`.
    public func catchUpAll() async {
        for entry in entries.values where entry.ended == nil {
            try? await entry.sync.catchUp()
        }
    }

    /// Games currently owned (followed, or inside their grace period).
    public var activeGameIds: [String] { entries.keys.sorted() }

    // MARK: Followers

    private func follow(_ gameId: String, token: UUID, continuation: AsyncThrowingStream<LiveGameUpdate, any Error>.Continuation) {
        if endedEarly.remove(token) != nil { return }
        followed.insert(token)
        let entry = entries[gameId] ?? start(gameId)
        entry.expiry?.cancel()
        entry.expiry = nil
        if let latest = entry.latest { continuation.yield(latest) }
        if let ended = entry.ended {
            continuation.finish(throwing: ended)
            scheduleExpiry(gameId, entry)
            return
        }
        entry.followers[token] = continuation
    }

    private func unfollow(_ gameId: String, token: UUID) {
        guard followed.remove(token) != nil else {
            // `follow` has not run yet: it must not start the game when it does.
            endedEarly.insert(token)
            return
        }
        guard let entry = entries[gameId], entry.followers.removeValue(forKey: token) != nil else { return }
        if entry.followers.isEmpty { scheduleExpiry(gameId, entry) }
    }

    private func scheduleExpiry(_ gameId: String, _ entry: Entry) {
        entry.expiry?.cancel()
        entry.expiry = Task { [clock, grace] in
            try? await clock.sleep(for: grace)
            guard !Task.isCancelled else { return }
            self.expire(gameId, entry)
        }
    }

    private func expire(_ gameId: String, _ entry: Entry) {
        guard entries[gameId] === entry, entry.followers.isEmpty else { return }
        entry.run?.cancel()
        entry.pump?.cancel()
        entries[gameId] = nil
    }

    // MARK: Running a game

    private func start(_ gameId: String) -> Entry {
        let entry = Entry(sync: makeSync(gameId))
        entries[gameId] = entry
        started += 1
        let sync = entry.sync
        entry.pump = Task {
            for await update in sync.updates {
                let offset = await sync.serverOffset
                let mapped = LiveGameUpdate(game: Mapping.liveGame(update.state, serverOffset: offset), cause: Mapping.cause(update.cause))
                self.publish(mapped, to: entry)
            }
        }
        entry.run = Task {
            let outcome: (any Error)?
            do {
                try await sync.run()
                outcome = nil
            } catch {
                outcome = error
            }
            // Every update `run()` published is delivered before the followers finish.
            await entry.pump?.value
            self.finish(entry, gameId: gameId, error: outcome)
        }
        return entry
    }

    private func publish(_ update: LiveGameUpdate, to entry: Entry) {
        entry.latest = update
        for continuation in entry.followers.values { continuation.yield(update) }
    }

    private func finish(_ entry: Entry, gameId: String, error: (any Error)?) {
        guard entries[gameId] === entry else { return }
        entry.ended = .some(error)
        for continuation in entry.followers.values { continuation.finish(throwing: error) }
        entry.followers = [:]
        if error != nil {
            // A failed game is not kept: the next follower starts it afresh.
            entries[gameId] = nil
        } else {
            scheduleExpiry(gameId, entry)
        }
    }
}
