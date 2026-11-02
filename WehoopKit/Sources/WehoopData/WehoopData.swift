/// WehoopData: `APIClient` (Hono `/v1/...`, typed endpoints, one decoder, retry with backoff,
/// host-scoped base URL), `PostgRESTReader`, `RealtimeTransport` and `AuthSession` over
/// supabase-swift (exact pin), the `Cache` actor, `FavoritesStore` with the legacy-favorites
/// migration, the keyed `GameSyncRegistry`, and the repository implementations of Domain's
/// protocols. Never imported by a Feature module. The app ships no provider key, ever.
import Contracts
import Domain
import LiveEngine

/// The backend environments the app can talk to.
public enum BackendEnvironment: String, Sendable, CaseIterable {
    case local
    case hosted
}
