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
    var rejoin = RejoinPolicy()

    /// Why subscriptions of this transport ended early (join refused, sign-in failed).
    public let diagnostics = TransportDiagnostics()

    public func messages(gameId: String) -> AsyncStream<TransportMessage> {
        let (stream, continuation) = AsyncStream.makeStream(of: TransportMessage.self)
        let realtime = client.realtimeV2
        let (auth, rejoin, diagnostics) = (auth, rejoin, diagnostics)
        let task = Task {
            do {
                try await auth.ensureSignedIn()
            } catch {
                diagnostics.record("sign-in: \(error)")
                continuation.finish()
                return
            }
            let channel = realtime.channel("game:\(gameId)") { $0.isPrivate = true }
            let broadcasts = channel.broadcastStream(event: "*")
            let watcher = Self.watch(channel, gameId: gameId, rejoin: rejoin, diagnostics: diagnostics, continuation: continuation)
            defer { watcher.cancel() }
            do {
                try await channel.subscribeWithError()
            } catch {
                diagnostics.record("join game:\(gameId): \(error)")
                await realtime.removeChannel(channel)
                continuation.finish()
                return
            }
            for await message in broadcasts {
                if Task.isCancelled { break }
                if let decoded = Self.decode(message) { continuation.yield(decoded) }
            }
            await realtime.removeChannel(channel)
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    /// Follows the channel's status: a join yields `.reconnected`; a loss starts the rejoin,
    /// and a rejoin that fails finishes the stream.
    private static func watch(
        _ channel: RealtimeChannelV2, gameId: String, rejoin: RejoinPolicy, diagnostics: TransportDiagnostics,
        continuation: AsyncStream<TransportMessage>.Continuation
    ) -> Task<Void, Never> {
        Task {
            var watch = ChannelWatch()
            var recovery: Task<Void, Never>?
            for await status in channel.statusChange {
                switch watch.observe(status) {
                case .joined:
                    recovery?.cancel()
                    recovery = nil
                    continuation.yield(.reconnected)
                case .lost:
                    recovery?.cancel()
                    recovery = Task {
                        let rejoined = await rejoin.run(
                            isRecovering: { [.subscribing, .subscribed].contains(channel.status) },
                            subscribe: { try await channel.subscribeWithError() }
                        )
                        if !rejoined, !Task.isCancelled {
                            diagnostics.record("game:\(gameId) left and could not rejoin")
                            continuation.finish()
                        }
                    }
                case nil:
                    break
                }
            }
            recovery?.cancel()
        }
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
