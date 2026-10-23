/// WehoopData: `APIClient` (Hono `/v1/...`, typed endpoints, one decoder, retry with backoff,
/// host-scoped base URL), `PostgRESTReader` and `RealtimeTransport` over supabase-swift
/// (exact pin, added in S3), `AuthSession` (anonymous sign-in), the `Cache` actor,
/// `FavoritesStore` with the legacy-favorites migration, and the repository
/// implementations of Domain's protocols. Never imported by a Feature module.
///
/// S0 placeholder: the clients land in S3. The app ships no provider key, ever.
import Contracts
import Domain
import LiveEngine

/// The backend environments the app can talk to.
public enum BackendEnvironment: String, Sendable, CaseIterable {
    case local
    case hosted
}
