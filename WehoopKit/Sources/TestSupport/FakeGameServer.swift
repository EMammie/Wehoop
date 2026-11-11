import Contracts
import Foundation
import LiveEngine

/// How the fake transport mangles delivery. The server always publishes every change in
/// seq order (its `/changes` is complete up to what it has published); faults change only
/// what the subscription delivers, as Realtime can.
public struct DeliveryFaults: Sendable, Equatable {
    /// Published but never delivered.
    public var drop: Set<Int> = []
    /// Delivered twice in a row.
    public var duplicate: Set<Int> = []
    /// Held back and delivered right after the next delivered change (a reorder).
    public var delayOne: Set<Int> = []
    /// A `.reconnected` is delivered right after this seq is published.
    public var reconnectAfter: Set<Int> = []
    /// Deliver the golden pulse (status closed, `latestSeq` = the last seq) after the last change.
    public var finalPulse = true

    public init(
        drop: Set<Int> = [], duplicate: Set<Int> = [], delayOne: Set<Int> = [],
        reconnectAfter: Set<Int> = [], finalPulse: Bool = true
    ) {
        self.drop = drop
        self.duplicate = duplicate
        self.delayOne = delayOne
        self.reconnectAfter = reconnectAfter
        self.finalPulse = finalPulse
    }

    public static let none = DeliveryFaults()

    /// Deterministic faults over seqs `1...count` (SplitMix64 from `seed`): each seq is
    /// dropped, duplicated or delayed with probability `rate` each, and the stream
    /// reconnects `reconnects` times. The last seq is never delayed (nothing follows it).
    public static func seeded(seed: UInt64, count: Int, rate: Double, reconnects: Int) -> DeliveryFaults {
        var rng = SplitMix64(seed: seed)
        var faults = DeliveryFaults()
        guard count > 0 else { return faults }
        for seq in 1...count {
            let roll = rng.nextUnit()
            if roll < rate {
                faults.drop.insert(seq)
            } else if roll < 2 * rate {
                faults.duplicate.insert(seq)
            } else if roll < 3 * rate, seq < count {
                faults.delayOne.insert(seq)
            }
        }
        for _ in 0..<reconnects { faults.reconnectAfter.insert(1 + Int(rng.nextUnit() * Double(count - 1))) }
        return faults
    }
}

/// SplitMix64: a tiny deterministic generator for reproducible fault plans.
struct SplitMix64 {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func nextUnit() -> Double { Double(next() >> 11) / Double(1 << 53) }
}

/// A wehoop-api stand-in for one golden game: it publishes the captured change stream in
/// seq order as the subscription is read (pull-driven, so tests are deterministic), serves
/// `/changes` up to what it has published, and serves snapshots from the goldens.
public actor FakeGameServer {
    public enum FirstSnapshot: Sendable {
        /// Seq 0: the game before any change (`Golden.pregameSnapshot`).
        case pregame
        /// The final golden snapshot (a closed game, or a snapshot that raced ahead of the buffer).
        case final
    }

    private enum Step: Sendable {
        case publish(Int)
        case deliver(TransportMessage)
    }

    nonisolated public let gameId: String
    private let changes: [GameChange]
    private let pregame: Snapshot
    private let final: Snapshot
    private let pulse: Pulse
    private let firstSnapshot: FirstSnapshot
    private let retainedFrom: Int
    private var steps: [Step] = []
    private var cursor = 0
    private var queued: [TransportMessage] = []

    /// Highest seq the server has published.
    public private(set) var published = 0
    public private(set) var snapshotCalls = 0
    /// The `after` of every `/changes` request, in order.
    public private(set) var changesCalls: [Int] = []
    public private(set) var delivered = 0

    /// - Parameters:
    ///   - prefetch: deliveries queued on the subscription before the first snapshot is
    ///     served (they are buffered by the transport while the snapshot loads).
    ///   - retainedFrom: `/changes` reports history before this seq as expired.
    public init(
        game: GoldenGame,
        faults: DeliveryFaults = .none,
        firstSnapshot: FirstSnapshot = .pregame,
        prefetch: Int = 0,
        retainedFrom: Int = 1
    ) throws {
        final = try Golden.snapshot(game)
        pregame = Golden.pregameSnapshot(of: final)
        changes = try Golden.changes(game)
        pulse = try Golden.pulse(game)
        gameId = final.game.id
        self.firstSnapshot = firstSnapshot
        self.retainedFrom = retainedFrom
        steps = Self.plan(changes: changes, faults: faults, pulse: pulse)
        var queue: [TransportMessage] = []
        var published = 0
        var cursor = 0
        while queue.count < prefetch, cursor < steps.count {
            switch steps[cursor] {
            case .publish(let seq): published = seq
            case .deliver(let message): queue.append(message)
            }
            cursor += 1
        }
        self.queued = queue
        self.published = published
        self.cursor = cursor
    }

    private static func plan(changes: [GameChange], faults: DeliveryFaults, pulse: Pulse) -> [Step] {
        var steps: [Step] = []
        var held: GameChange?
        for change in changes {
            steps.append(.publish(change.seq))
            if faults.reconnectAfter.contains(change.seq) { steps.append(.deliver(.reconnected)) }
            if faults.drop.contains(change.seq) { continue }
            if faults.delayOne.contains(change.seq), held == nil {
                held = change
                continue
            }
            steps.append(.deliver(.change(change)))
            if faults.duplicate.contains(change.seq) { steps.append(.deliver(.change(change))) }
            if let late = held {
                steps.append(.deliver(.change(late)))
                held = nil
            }
        }
        if let late = held { steps.append(.deliver(.change(late))) }
        if faults.finalPulse { steps.append(.deliver(.pulse(pulse))) }
        return steps
    }

    /// The next delivered message (publishing changes on the way), or nil at the end.
    public func nextDelivery() -> TransportMessage? {
        if !queued.isEmpty {
            delivered += 1
            return queued.removeFirst()
        }
        while cursor < steps.count {
            let step = steps[cursor]
            cursor += 1
            switch step {
            case .publish(let seq): published = seq
            case .deliver(let message):
                delivered += 1
                return message
            }
        }
        return nil
    }

    /// Time passes on the server: every remaining change is published (what the closing
    /// settle waits for). Undelivered messages stay on the subscription.
    public func publishAll() {
        published = changes.last?.seq ?? published
    }

    public func snapshot() -> Snapshot {
        snapshotCalls += 1
        if snapshotCalls == 1, firstSnapshot == .pregame { return pregame }
        return final
    }

    public func changesPage(after: Int, limit: Int) -> ChangesPage {
        changesCalls.append(after)
        if after < retainedFrom - 1 {
            return ChangesPage(changes: [], nextAfter: after, latestSeq: published, hasMore: false, retainedFrom: retainedFrom)
        }
        let page = changes.filter { $0.seq > after && $0.seq <= published }.prefix(limit)
        let nextAfter = page.last?.seq ?? after
        return ChangesPage(
            changes: Array(page), nextAfter: nextAfter, latestSeq: published,
            hasMore: nextAfter < published, retainedFrom: retainedFrom
        )
    }
}

/// `GameTransport` over a `FakeGameServer`: each read pulls the next delivery.
public struct FakeTransport: GameTransport {
    public let server: FakeGameServer
    public init(server: FakeGameServer) { self.server = server }

    public func messages(gameId: String) -> AsyncStream<TransportMessage> {
        let server = server
        return AsyncStream(unfolding: { await server.nextDelivery() })
    }
}

/// `GameAPI` over a `FakeGameServer`.
public struct FakeGameAPI: GameAPI {
    public let server: FakeGameServer
    public init(server: FakeGameServer) { self.server = server }

    public func snapshot(gameId: String) async throws -> Snapshot { await server.snapshot() }

    public func changes(gameId: String, after: Int, limit: Int) async throws -> ChangesPage {
        await server.changesPage(after: after, limit: limit)
    }
}

/// A clock frozen at `now` whose sleeps return at once, after running `onSleep` (a test
/// passes `server.publishAll` so the closing settle sees what the server published meanwhile).
public struct FakeClock: SyncClock {
    public let fixed: Date
    private let onSleep: @Sendable () async -> Void

    public init(now: Date, onSleep: @escaping @Sendable () async -> Void = {}) {
        fixed = now
        self.onSleep = onSleep
    }

    public func now() -> Date { fixed }
    public func sleep(for duration: Duration) async throws { await onSleep() }
}

extension Golden {
    /// A golden value as a demo replay would carry it: the same JSON with the `replay` label
    /// set at `path` (backend rev 4.15). The goldens are real games, so the label is added in
    /// the test, never by editing a committed fixture.
    public static func labelled<T: Codable>(_ value: T, replay: Contracts.ReplayKind?, at path: [String] = []) throws -> T {
        var root = try JSONSerialization.jsonObject(with: JSONEncoder().encode(value))
        root = setting(root, path: path, to: replay.map { $0.rawValue as Any } ?? NSNull())
        return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: root))
    }

    private static func setting(_ node: Any, path: [String], to label: Any) -> Any {
        guard var object = node as? [String: Any] else { return node }
        if let key = path.first {
            object[key] = setting(object[key] ?? [String: Any](), path: Array(path.dropFirst()), to: label)
        } else {
            object["replay"] = label
        }
        return object
    }

    /// The game before any durable change, built from the final snapshot's identity:
    /// seq 0, scheduled, 0–0, no period, clock or target, no line score, stats or plays
    /// (the replay label is identity and is kept).
    /// Folding the whole golden stream onto it must reproduce the final snapshot.
    public static func pregameSnapshot(of final: Snapshot) -> Snapshot {
        let g = final.game
        return Snapshot(
            game: .init(
                id: g.id, league: g.league, providerGameId: g.providerGameId, status: .scheduled,
                scheduledAt: g.scheduledAt, coverage: g.coverage, homeTeamId: g.homeTeamId,
                awayTeamId: g.awayTeamId, score: Score(home: 0, away: 0), period: nil, clock: nil,
                clockDecimal: nil, clockRunning: nil, clockAsOf: nil, observedAt: nil, elamTargetScore: nil,
                replay: g.replay
            ),
            periods: [], teamStats: [], playerStats: [], events: [],
            seq: 0, retainedFrom: 1, coverage: final.coverage, serverTime: final.serverTime
        )
    }
}
