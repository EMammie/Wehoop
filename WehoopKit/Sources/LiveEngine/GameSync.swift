import Contracts
import Foundation

/// What a `game:{id}` subscription delivers. Delivery may drop, repeat or reorder
/// messages; `GameSync` makes the folded state correct regardless.
public enum TransportMessage: Sendable, Hashable {
    case change(GameChange)
    case pulse(Pulse)
    /// The transport re-established a dropped connection: messages may have been lost.
    case reconnected
}

/// The private Realtime channel of one game (Supabase Broadcast in S3; a fake in tests).
public protocol GameTransport: Sendable {
    /// Subscribe to `game:{gameId}`. The sequence buffers what arrives until it is read and
    /// ends when the subscription ends.
    func messages(gameId: String) -> AsyncStream<TransportMessage>
}

/// The two REST reads of the reconnect contract (wehoop-api `/v1/games/:id/…`).
public protocol GameAPI: Sendable {
    func snapshot(gameId: String) async throws -> Snapshot
    func changes(gameId: String, after: Int, limit: Int) async throws -> ChangesPage
}

/// Time, injected so tests run without waiting.
public protocol SyncClock: Sendable {
    func now() -> Date
    func sleep(for duration: Duration) async throws
}

public struct SystemClock: SyncClock {
    public init() {}
    public func now() -> Date { Date() }
    public func sleep(for duration: Duration) async throws { try await Task.sleep(for: duration) }
}

/// One published state and why it changed.
public struct SyncUpdate: Sendable {
    public enum Cause: Sendable, Equatable {
        case snapshot, resnapshot, finalSnapshot, change, pulse, catchUp
    }

    public let state: LiveGameState
    public let cause: Cause
    /// Server time minus local time from the snapshot this state descends from, for `ClockModel`.
    public let serverOffset: TimeInterval
}

/// Why `/changes` was paged.
public enum CatchUpReason: Sendable, Equatable {
    /// A change arrived with a seq beyond `after + 1`.
    case gap(after: Int)
    /// A pulse reported `latestSeq` beyond what was folded (a lost final change).
    case pulseAhead(latestSeq: Int)
    case reconnect
    /// App foreground or a network change (`GameSync.catchUp()`).
    case foreground
    /// After `closed`, before the final snapshot.
    case closing
}

/// Counters for evidence and diagnostics.
public struct SyncStats: Sendable, Equatable {
    public var snapshots = 0
    public var resnapshots = 0
    public var catchUps = 0
    public var pages = 0
    public var received = 0
    public var applied = 0
    public var duplicates = 0
    public var gaps = 0
    public var pulses = 0
    public var stalePulses = 0
    public var reconnects = 0
    public var staleSnapshots = 0
    public var catchUpReasons: [CatchUpReason] = []
}

public enum GameSyncError: Error, Equatable {
    /// The subscription ended before the game closed.
    case transportEnded
    /// The API returned another game's snapshot.
    case foreignSnapshot
    /// `/changes` reported expired history again right after a re-snapshot.
    case historyUnavailable
}

/// The reconnect contract of the backend plan (§4 "Reconnect contract") for one game:
/// subscribe and buffer; snapshot; fold what the subscription delivered after the
/// snapshot's seq; on a gap or a pulse ahead, page `/changes` until `hasMore` is false;
/// when history before the needed seq has expired, re-snapshot; on reconnect, foreground
/// or a network change, catch up; on `closed`, settle, catch up and take one final
/// snapshot. A game already closed when opened is the snapshot only.
///
/// Messages are handled one at a time under an async lock, so a catch-up completes before
/// the next message is looked at; while the first snapshot loads, the subscription's own
/// sequence is the buffer.
public actor GameSync {
    nonisolated public let gameId: String
    private let transport: any GameTransport
    private let api: any GameAPI
    private let clock: any SyncClock
    private let pageLimit: Int
    private let closingSettle: Duration

    /// Every published state, in order. Finishes when `run()` returns.
    nonisolated public let updates: AsyncStream<SyncUpdate>
    private let continuation: AsyncStream<SyncUpdate>.Continuation

    public private(set) var state: LiveGameState?
    /// Server time minus local time at the last snapshot, for `ClockModel`.
    public private(set) var serverOffset: TimeInterval = 0
    public private(set) var stats = SyncStats()
    /// The state folded from the stream when the game closed, just before the final
    /// snapshot replaced it (the S2 evidence compares the two).
    public private(set) var foldedAtClose: LiveGameState?
    /// The last catch-up or snapshot failure while handling messages (handling continues).
    public private(set) var lastErrorDescription: String?

    private var locked = false
    private var lockWaiters: [CheckedContinuation<Void, Never>] = []
    private var closeSignalled = false
    private var transportEnded = false
    private var closeWaiter: CheckedContinuation<Void, any Error>?

    public init(
        gameId: String,
        transport: any GameTransport,
        api: any GameAPI,
        clock: any SyncClock = SystemClock(),
        pageLimit: Int = 500,
        closingSettle: Duration = .seconds(20)
    ) {
        self.gameId = gameId
        self.transport = transport
        self.api = api
        self.clock = clock
        self.pageLimit = pageLimit
        self.closingSettle = closingSettle
        (updates, continuation) = AsyncStream.makeStream(of: SyncUpdate.self)
    }

    /// The clock display for the current state.
    public func clockModel() -> ClockModel? {
        state?.clockModel(serverOffset: serverOffset)
    }

    /// Run the contract until the game closes and the final snapshot is applied (or the
    /// task is cancelled). Throws when the first snapshot fails or the subscription ends early.
    public func run() async throws {
        defer { continuation.finish() }
        let messages = transport.messages(gameId: gameId)
        let consumer = Task {
            for await message in messages { await self.receive(message) }
            self.subscriptionEnded()
        }
        defer { consumer.cancel() }

        await lock()
        do {
            try await loadSnapshot(.snapshot)
            unlock()
        } catch {
            unlock()
            throw error
        }
        if state?.isClosed == true { return }

        try await waitForClose()
        try await clock.sleep(for: closingSettle)
        await lock()
        defer { unlock() }
        try await pageChanges(.closing)
        foldedAtClose = state
        try await loadSnapshot(.finalSnapshot)
    }

    /// App foreground or a network change: page `/changes` from the last folded seq.
    public func catchUp() async throws {
        await lock()
        defer { unlock() }
        try await pageChanges(.foreground)
    }

    // MARK: Messages

    private func receive(_ message: TransportMessage) async {
        await lock()
        defer { unlock() }
        guard state != nil else { return }
        do {
            try await handle(message)
        } catch {
            lastErrorDescription = String(describing: error)
        }
    }

    private func handle(_ message: TransportMessage) async throws {
        switch message {
        case .change(let change):
            try await handle(change)
        case .pulse(let pulse):
            try await handle(pulse)
        case .reconnected:
            stats.reconnects += 1
            try await pageChanges(.reconnect)
        }
    }

    private func handle(_ change: GameChange) async throws {
        stats.received += 1
        switch state?.apply(change) {
        case .applied:
            stats.applied += 1
            emit(.change)
            if state?.isClosed == true { signalClose() }
        case .duplicate:
            stats.duplicates += 1
        case .gap(let expected, _):
            stats.gaps += 1
            try await pageChanges(.gap(after: expected - 1))
            // The page usually covered it; if not, it is folded now when it is next.
            if case .applied = state?.apply(change) {
                stats.applied += 1
                emit(.change)
            }
        case .foreignGame, nil:
            break
        }
    }

    private func handle(_ pulse: Pulse) async throws {
        stats.pulses += 1
        guard let outcome = state?.apply(pulse) else { return }
        if outcome.applied { emit(.pulse) } else { stats.stalePulses += 1 }
        if outcome.behind { try await pageChanges(.pulseAhead(latestSeq: pulse.latestSeq)) }
        if pulse.status == .closed { signalClose() }
    }

    // MARK: Snapshot and /changes (callers hold the lock)

    private func loadSnapshot(_ cause: SyncUpdate.Cause) async throws {
        let snapshot = try await api.snapshot(gameId: gameId)
        guard snapshot.game.id == gameId else { throw GameSyncError.foreignSnapshot }
        stats.snapshots += 1
        if let current = state, snapshot.seq < current.lastSeq {
            // An older snapshot than what is folded (a cache): keep the fold.
            stats.staleSnapshots += 1
            return
        }
        let receivedAt = clock.now()
        serverOffset = (ISODate.parse(snapshot.serverTime) ?? receivedAt).timeIntervalSince(receivedAt)
        state = LiveGameState(snapshot: snapshot)
        emit(cause)
        if state?.isClosed == true { signalClose() }
    }

    private func pageChanges(_ reason: CatchUpReason) async throws {
        guard state != nil else { return }
        stats.catchUps += 1
        stats.catchUpReasons.append(reason)
        var appliedHere = 0
        var resnapshotted = false
        while let lastSeq = state?.lastSeq {
            let page = try await api.changes(gameId: gameId, after: lastSeq, limit: pageLimit)
            stats.pages += 1
            if page.retainedFrom > lastSeq + 1 {
                // History before the next seq expired: only a snapshot can bridge it.
                guard !resnapshotted else { throw GameSyncError.historyUnavailable }
                resnapshotted = true
                stats.resnapshots += 1
                try await loadSnapshot(.resnapshot)
                continue
            }
            appliedHere += fold(page.changes)
            if !page.hasMore || page.changes.isEmpty { break }
        }
        stats.applied += appliedHere
        if appliedHere > 0 { emit(.catchUp) }
        if state?.isClosed == true { signalClose() }
    }

    /// Folds a page in order; returns how many changes it applied.
    private func fold(_ changes: [GameChange]) -> Int {
        var applied = 0
        for change in changes {
            switch state?.apply(change) {
            case .applied: applied += 1
            case .duplicate: stats.duplicates += 1
            default: break
            }
        }
        return applied
    }

    private func emit(_ cause: SyncUpdate.Cause) {
        guard let state else { return }
        continuation.yield(SyncUpdate(state: state, cause: cause, serverOffset: serverOffset))
    }

    // MARK: Closing

    private func signalClose() {
        closeSignalled = true
        closeWaiter?.resume()
        closeWaiter = nil
    }

    private func subscriptionEnded() {
        transportEnded = true
        if !closeSignalled {
            closeWaiter?.resume(throwing: GameSyncError.transportEnded)
            closeWaiter = nil
        }
    }

    private func cancelWait() {
        closeWaiter?.resume(throwing: CancellationError())
        closeWaiter = nil
    }

    private func waitForClose() async throws {
        if closeSignalled { return }
        if transportEnded { throw GameSyncError.transportEnded }
        try Task.checkCancellation()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { closeWaiter = $0 }
        } onCancel: {
            Task { await self.cancelWait() }
        }
    }

    // MARK: Lock

    private func lock() async {
        if !locked {
            locked = true
            return
        }
        await withCheckedContinuation { lockWaiters.append($0) }
    }

    /// Hands the lock to the next waiter, if any (it stays locked), else releases it.
    private func unlock() {
        if lockWaiters.isEmpty {
            locked = false
        } else {
            lockWaiters.removeFirst().resume()
        }
    }
}
