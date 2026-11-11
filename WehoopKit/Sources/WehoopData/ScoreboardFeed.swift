import Contracts
import Domain
import Foundation
import Supabase
import Synchronization

/// What a league's scoreboard channel delivers, at the wire level.
public enum ScoreboardMessage: Sendable, Hashable {
    /// The channel joined or rejoined (the first join included).
    case reconnected
    case scores(Scoreboard)
}

/// Subscribes to `league:{code}:scores`.
public protocol ScoreboardTransport: Sendable {
    func messages(league: String) -> AsyncStream<ScoreboardMessage>
}

/// `ScoreboardTransport` over Supabase Realtime: the private channel `league:{code}:scores`
/// as the guest session (receive-only, like `game:{id}`). The backend publishes one
/// `scores` broadcast per league every 5 s listing the games whose row changed since the
/// previous tick (backend plan §5); it never replays, so every join is reported as
/// `.reconnected` and the list re-reads `v_schedule`. Join, rejoin and the end of the
/// stream behave as in `RealtimeTransport`.
public struct RealtimeScoreboardTransport: ScoreboardTransport {
    let client: SupabaseClient
    let auth: AuthSession
    /// Shared by every transport of the client (`SupabaseServices`).
    let topics: TopicGate
    var rejoin = RejoinPolicy()

    /// Why subscriptions of this transport ended early (join refused, sign-in failed).
    public let diagnostics = TransportDiagnostics()

    public func messages(league: String) -> AsyncStream<ScoreboardMessage> {
        GuestChannel(
            realtime: client.realtimeV2, auth: auth, topic: "league:\(league):scores", rejoin: rejoin, diagnostics: diagnostics,
            topics: topics
        )
        .messages(joined: .reconnected, decode: Self.decode)
    }

    /// A broadcast message (`{event, payload, type}`) as a scoreboard message; nil for an
    /// event this build does not handle or a payload that does not decode.
    static func decode(_ message: JSONObject) -> ScoreboardMessage? {
        guard case .string(let event)? = message["event"], let payload = message["payload"],
              let data = try? JSONEncoder().encode(payload) else { return nil }
        return decode(event: event, payload: data)
    }

    /// One broadcast event's payload as a scoreboard message.
    static func decode(event: String, payload data: Data) -> ScoreboardMessage? {
        guard event == "scores", let board = try? APIClient.decoder.decode(Scoreboard.self, from: data) else { return nil }
        return .scores(board)
    }
}

/// One upstream subscription per league however many follow it (two iPad windows on the
/// same league's Scores), as `GameSyncRegistry` does for games. Without it the second
/// follower of a topic would wait on `TopicGate` until the first left.
///
/// The first follower of a league starts the upstream subscription; every follower gets
/// each message; a follower that arrives after the channel joined gets `.reconnected` at
/// once, so it re-reads like any joiner. When the last follower leaves, the upstream
/// subscription is cancelled (the channel is removed). When the upstream ends (the channel
/// was lost for good), every follower's stream finishes; the next follower starts afresh.
public final class SharedScoreboardTransport: ScoreboardTransport {
    private struct Entry {
        let id = UUID()
        var followers: [UUID: AsyncStream<ScoreboardMessage>.Continuation] = [:]
        var joined = false
        var pump: Task<Void, Never>?
    }

    private let upstream: any ScoreboardTransport
    private let entries = Mutex<[String: Entry]>([:])

    public init(upstream: any ScoreboardTransport) {
        self.upstream = upstream
    }

    /// Leagues with an upstream subscription now (tests).
    var activeLeagues: [String] { entries.withLock { $0.keys.sorted() } }

    public func messages(league: String) -> AsyncStream<ScoreboardMessage> {
        let (stream, continuation) = AsyncStream.makeStream(of: ScoreboardMessage.self)
        let token = UUID()
        continuation.onTermination = { [weak self] _ in self?.unfollow(league, token) }
        entries.withLock { entries in
            var entry = entries[league] ?? Entry()
            entry.followers[token] = continuation
            if entry.joined { continuation.yield(.reconnected) }
            if entry.pump == nil { entry.pump = pump(league, entryId: entry.id) }
            entries[league] = entry
        }
        return stream
    }

    private func pump(_ league: String, entryId: UUID) -> Task<Void, Never> {
        let messages = upstream.messages(league: league)
        return Task { [weak self] in
            for await message in messages {
                self?.entries.withLock { entries in
                    guard var entry = entries[league], entry.id == entryId else { return }
                    if message == .reconnected { entry.joined = true }
                    entry.followers.values.forEach { $0.yield(message) }
                    entries[league] = entry
                }
            }
            let ended = self?.entries.withLock { entries -> [AsyncStream<ScoreboardMessage>.Continuation] in
                guard let entry = entries[league], entry.id == entryId else { return [] }
                entries[league] = nil
                return Array(entry.followers.values)
            }
            ended?.forEach { $0.finish() }
        }
    }

    private func unfollow(_ league: String, _ token: UUID) {
        let stop = entries.withLock { entries -> Task<Void, Never>? in
            guard var entry = entries[league], entry.followers.removeValue(forKey: token) != nil else { return nil }
            if entry.followers.isEmpty {
                entries[league] = nil
                return entry.pump
            }
            entries[league] = entry
            return nil
        }
        stop?.cancel()
    }
}

/// Domain's `LiveScoresSource` over a scoreboard transport: joins become `.subscribed`,
/// each message's deltas become `ScoreUpdate`s. A message for another league, or of a type
/// other than `scores`, is dropped here; which games a list shows is the list's business.
public struct ScoreboardFeed: LiveScoresSource {
    let transport: any ScoreboardTransport

    public init(transport: any ScoreboardTransport) {
        self.transport = transport
    }

    public func scores(league: League.Code) -> AsyncStream<LiveScoresEvent> {
        let upstream = transport.messages(league: league.rawValue)
        let (stream, continuation) = AsyncStream.makeStream(of: LiveScoresEvent.self)
        let task = Task {
            for await message in upstream {
                if let event = Self.event(message, league: league) { continuation.yield(event) }
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    static func event(_ message: ScoreboardMessage, league: League.Code) -> LiveScoresEvent? {
        switch message {
        case .reconnected:
            return .subscribed
        case .scores(let board):
            guard board.type == "scores", board.league.rawValue == league.rawValue, !board.deltas.isEmpty else { return nil }
            return .updates(board.deltas.map(Mapping.scoreUpdate))
        }
    }
}
