import Foundation
import Supabase

/// The guest session (backend plan §2: Supabase anonymous sign-in, no sign-up), so private
/// Realtime channels and row-level security see an `authenticated` JWT. One sign-in at a
/// time: concurrent callers share it.
public actor AuthSession {
    private let client: SupabaseClient
    private var signingIn: Task<Void, any Error>?

    init(client: SupabaseClient) {
        self.client = client
    }

    /// Restores the stored session (refreshing an expired token) or signs in anonymously.
    public func ensureSignedIn() async throws {
        if let signingIn { return try await signingIn.value }
        let task = Task { [client] in
            if client.auth.currentSession == nil {
                _ = try await client.auth.signInAnonymously()
            } else {
                // Refreshes an expired token; a network failure here is thrown, never
                // answered with a second guest user.
                _ = try await client.auth.session
            }
        }
        signingIn = task
        defer { signingIn = nil }
        try await task.value
    }

    /// The signed-in user's id; nil before `ensureSignedIn()`.
    public var userId: String? {
        client.auth.currentSession?.user.id.uuidString.lowercased()
    }

    /// True when the session is anonymous (a guest).
    public var isAnonymous: Bool {
        client.auth.currentSession?.user.isAnonymous ?? false
    }

    public func signOut() async throws {
        try await client.auth.signOut()
    }
}
