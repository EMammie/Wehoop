import Contracts
import Foundation
import LiveEngine
import Supabase
import Synchronization

/// `GameTransport` over Supabase Realtime: the private channel `game:{id}` as the guest
/// session (receive-only; backend plan §2). Broadcast events `change` and `pulse` decode
/// into Contracts types; anything else on the channel is ignored.
///
/// Every transition into `subscribed`, the first join included, is reported as
/// `.reconnected`: `GameSync` may read its snapshot before the join completes, and the
/// catch-up a `.reconnected` triggers closes that window as it closes a reconnect's.
///
/// A channel that leaves `subscribed` (a `phx_error` on a refused token or policy) is
/// rejoined only after a socket reconnect, so the transport rejoins it itself: when the
/// channel is still unsubscribed after `rejoinGrace`, it resubscribes with doubling backoff
/// and, if every attempt fails, finishes the stream. `GameSync` then throws
/// `.transportEnded` instead of waiting forever on a silent channel.
public struct RealtimeTransport: GameTransport {
    let client: SupabaseClient
    let auth: AuthSession
    /// Shared by every transport of the client (`SupabaseServices`).
    let topics: TopicGate
    var rejoin = RejoinPolicy()

    /// Why subscriptions of this transport ended early (join refused, sign-in failed).
    public let diagnostics = TransportDiagnostics()

    public func messages(gameId: String) -> AsyncStream<TransportMessage> {
        GuestChannel(
            realtime: client.realtimeV2, auth: auth, topic: "game:\(gameId)", rejoin: rejoin, diagnostics: diagnostics,
            topics: topics
        )
        .messages(joined: .reconnected, decode: Self.decode)
    }

    /// A broadcast message (`{event, payload, type}`) as a transport message; nil for an
    /// event this build does not handle or a payload that does not decode.
    static func decode(_ message: JSONObject) -> TransportMessage? {
        guard case .string(let event)? = message["event"], let payload = message["payload"],
              let data = try? JSONEncoder().encode(payload) else { return nil }
        return decode(event: event, payload: data)
    }

    /// One broadcast event's payload as a transport message.
    static func decode(event: String, payload data: Data) -> TransportMessage? {
        switch event {
        case "change": return (try? APIClient.decoder.decode(GameChange.self, from: data)).map(TransportMessage.change)
        case "pulse": return (try? APIClient.decoder.decode(Pulse.self, from: data)).map(TransportMessage.pulse)
        default: return nil
        }
    }
}

/// One private broadcast channel followed as the guest session: sign in, join, decode
/// every broadcast with `decode`, yield `joined` on every transition into `subscribed`, and
/// rejoin a lost channel with `rejoin` (the stream finishes when that fails). Shared by
/// the game channels (`RealtimeTransport`) and the league scoreboards (`RealtimeScoreboardTransport`).
///
/// Subscriptions of one topic are serialized through `topics`: supabase-swift hands out
/// one channel instance per topic and drops it from its map only after `removeChannel`'s
/// unsubscribe finishes, so a join that started while the previous subscription of the
/// topic was still leaving would get the leaving instance and not rejoin for 30-40 s.
struct GuestChannel {
    let realtime: RealtimeClientV2
    let auth: AuthSession
    let topic: String
    let rejoin: RejoinPolicy
    let diagnostics: TransportDiagnostics
    let topics: TopicGate

    func messages<Message: Sendable>(
        joined: Message, decode: @escaping @Sendable (JSONObject) -> Message?
    ) -> AsyncStream<Message> {
        let (stream, continuation) = AsyncStream.makeStream(of: Message.self)
        let task = Task {
            do {
                try await auth.ensureSignedIn()
            } catch {
                diagnostics.record("sign-in: \(error)")
                continuation.finish()
                return
            }
            await topics.serialized(topic) {
                guard !Task.isCancelled else { return }
                await follow(joined: joined, decode: decode, continuation: continuation)
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    /// Join, deliver until cancelled, and remove the channel (always, before returning).
    private func follow<Message: Sendable>(
        joined: Message, decode: @escaping @Sendable (JSONObject) -> Message?,
        continuation: AsyncStream<Message>.Continuation
    ) async {
        let channel = realtime.channel(topic) { $0.isPrivate = true }
        let broadcasts = channel.broadcastStream(event: "*")
        let watcher = watch(channel) {
            continuation.yield(joined)
        } onEnd: {
            continuation.finish()
        }
        defer { watcher.cancel() }
        do {
            try await channel.subscribeWithError()
        } catch {
            diagnostics.record("join \(topic): \(error)")
            await realtime.removeChannel(channel)
            return
        }
        for await message in broadcasts {
            if Task.isCancelled { break }
            if let decoded = decode(message) { continuation.yield(decoded) }
        }
        await realtime.removeChannel(channel)
    }

    /// Follows the channel's status: a join calls `onJoin`; a loss starts the rejoin, and a
    /// rejoin that fails calls `onEnd`.
    private func watch(
        _ channel: RealtimeChannelV2, onJoin: @escaping @Sendable () -> Void, onEnd: @escaping @Sendable () -> Void
    ) -> Task<Void, Never> {
        let (topic, rejoin, diagnostics) = (topic, rejoin, diagnostics)
        return Task {
            var watch = ChannelWatch()
            var recovery: Task<Void, Never>?
            for await status in channel.statusChange {
                switch watch.observe(status) {
                case .joined:
                    recovery?.cancel()
                    recovery = nil
                    onJoin()
                case .lost:
                    recovery?.cancel()
                    recovery = Task {
                        let rejoined = await rejoin.run(
                            isRecovering: { [.subscribing, .subscribed].contains(channel.status) },
                            subscribe: { try await channel.subscribeWithError() }
                        )
                        if !rejoined, !Task.isCancelled {
                            diagnostics.record("\(topic) left and could not rejoin")
                            onEnd()
                        }
                    }
                case nil:
                    break
                }
            }
            recovery?.cancel()
        }
    }
}

/// One subscription at a time per topic: a subscription of a topic starts only once the
/// previous one has removed its channel. A waiting subscription that is cancelled stops
/// waiting.
actor TopicGate {
    private var held: Set<String> = []
    private var waiters: [String: [UUID: CheckedContinuation<Void, Never>]] = [:]

    init() {}

    /// Runs `body` holding `topic`, after any earlier holder has finished.
    nonisolated func serialized(_ topic: String, _ body: @Sendable () async -> Void) async {
        guard await acquire(topic) else { return }
        await body()
        await release(topic)
    }

    /// True once `topic` is held by the caller; false when the caller was cancelled while waiting.
    private func acquire(_ topic: String) async -> Bool {
        while held.contains(topic) {
            if Task.isCancelled { return false }
            let id = UUID()
            await withTaskCancellationHandler {
                await withCheckedContinuation { continuation in
                    waiters[topic, default: [:]][id] = continuation
                }
            } onCancel: {
                Task { await self.wake(topic, id) }
            }
        }
        if Task.isCancelled { return false }
        held.insert(topic)
        return true
    }

    private func release(_ topic: String) {
        held.remove(topic)
        let all = waiters.removeValue(forKey: topic) ?? [:]
        all.values.forEach { $0.resume() }
    }

    private func wake(_ topic: String, _ id: UUID) {
        waiters[topic]?.removeValue(forKey: id)?.resume()
    }

    /// Topics held now (tests).
    var heldTopics: Set<String> { held }
}

/// The last reason a transport's subscription ended early.
public final class TransportDiagnostics: Sendable {
    private let last = Mutex<String?>(nil)
    public var lastFailure: String? { last.withLock { $0 } }
    func record(_ failure: String) { last.withLock { $0 = failure } }
}

/// What a channel status means to `GameSync`: entering `subscribed` is a join, leaving it is a loss.
struct ChannelWatch {
    enum Event: Equatable { case joined, lost }
    private var subscribed = false

    mutating func observe(_ status: RealtimeChannelStatus) -> Event? {
        let now = status == .subscribed
        defer { subscribed = now }
        if now, !subscribed { return .joined }
        if !now, subscribed { return .lost }
        return nil
    }
}

/// How a lost channel is rejoined.
struct RejoinPolicy: Sendable {
    /// How long the client's own rejoin (after a socket reconnect) is given first.
    var grace: Duration = .seconds(5)
    var attempts = 3
    var baseDelay: Duration = .seconds(1)
    var sleep: @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }

    /// True when the channel recovered (by itself or by a resubscribe); false when every
    /// attempt failed or the task was cancelled.
    func run(isRecovering: @Sendable () -> Bool, subscribe: @Sendable () async throws -> Void) async -> Bool {
        do { try await sleep(grace) } catch { return false }
        if isRecovering() { return true }
        var delay = baseDelay
        for attempt in 1...max(1, attempts) {
            do {
                try await subscribe()
                return true
            } catch {
                if attempt == attempts { break }
                do { try await sleep(delay) } catch { return false }
                delay *= 2
            }
        }
        return false
    }
}
