import Foundation
import Supabase

/// Where the anonymous session is kept between launches.
public enum SessionStorage: Sendable {
    /// The Keychain (the app).
    case keychain
    /// Memory only (tests and previews): every process starts signed out.
    case memory
}

/// The one `SupabaseClient` of the app. The client hands the session's access token to
/// PostgREST and Realtime itself (and refreshes it); nothing outside WehoopData sees it.
public struct SupabaseServices: Sendable {
    let client: SupabaseClient
    public let auth: AuthSession

    public init(configuration: BackendConfiguration, sessionStorage: SessionStorage = .keychain) {
        let authOptions: SupabaseClientOptions.AuthOptions = switch sessionStorage {
        case .keychain: .init(emitLocalSessionAsInitialSession: true)
        case .memory: .init(storage: InMemoryAuthStorage(), emitLocalSessionAsInitialSession: true)
        }
        client = SupabaseClient(
            supabaseURL: configuration.supabaseURL,
            supabaseKey: configuration.anonKey,
            options: SupabaseClientOptions(auth: authOptions)
        )
        auth = AuthSession(client: client)
    }

    public var reader: PostgRESTReader { PostgRESTReader(client: client, auth: auth) }
    public var transport: RealtimeTransport { RealtimeTransport(client: client, auth: auth) }
    public var scoreboardTransport: RealtimeScoreboardTransport { RealtimeScoreboardTransport(client: client, auth: auth) }
}

/// Session storage for tests: a locked dictionary.
final class InMemoryAuthStorage: AuthLocalStorage {
    private let values = Mutex<[String: Data]>([:])
    func store(key: String, value: Data) throws { values.withLock { $0[key] = value } }
    func retrieve(key: String) throws -> Data? { values.withLock { $0[key] } }
    func remove(key: String) throws { _ = values.withLock { $0.removeValue(forKey: key) } }
}

import Synchronization
