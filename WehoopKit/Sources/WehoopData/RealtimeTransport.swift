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
public struct RealtimeTransport: GameTransport {
    let client: SupabaseClient
    let auth: AuthSession

    /// The last reason a subscription ended early (join refused, sign-in failed).
    public static let lastFailure = Mutex<String?>(nil)

    public func messages(gameId: String) -> AsyncStream<TransportMessage> {
        let (stream, continuation) = AsyncStream.makeStream(of: TransportMessage.self)
        let realtime = client.realtimeV2
        let auth = auth
        let task = Task {
            do {
                try await auth.ensureSignedIn()
            } catch {
                Self.lastFailure.withLock { $0 = "sign-in: \(error)" }
                continuation.finish()
                return
            }
            let channel = realtime.channel("game:\(gameId)") { $0.isPrivate = true }
            let broadcasts = channel.broadcastStream(event: "*")
            let statuses = Task {
                var wasSubscribed = false
                for await status in channel.statusChange {
                    let subscribed = status == .subscribed
                    if subscribed && !wasSubscribed { continuation.yield(.reconnected) }
                    wasSubscribed = subscribed
                }
            }
            defer { statuses.cancel() }
            do {
                try await channel.subscribeWithError()
            } catch {
                Self.lastFailure.withLock { $0 = "join game:\(gameId): \(error)" }
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
