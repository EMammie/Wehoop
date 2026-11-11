import Domain
import Foundation
import LiveEngine

/// Everything the app's live mode reads, built once from a configuration: the guest
/// session, wehoop-api, the keyed live-game owner and the repositories over PostgREST.
/// The app's composition root holds one; features see only the Domain protocols.
public final class LiveBackend: Sendable {
    public let configuration: BackendConfiguration
    public let liveGames: GameSyncRegistry
    public let leagues: any LeagueRepository
    public let schedule: any ScheduleRepository
    /// `league:{code}:scores`, for the Scores list.
    public let liveScores: any LiveScoresSource
    public let players: any PlayerRepository
    public let favorites: FavoritesStore

    /// - Parameters:
    ///   - cacheDirectory: the cache's disk tier; nil keeps it in memory.
    public init(
        configuration: BackendConfiguration,
        sessionStorage: SessionStorage = .keychain,
        cacheDirectory: URL? = LiveBackend.defaultCacheDirectory,
        store: any KeyValueStore = UserDefaultsStore()
    ) {
        self.configuration = configuration
        let services = SupabaseServices(configuration: configuration, sessionStorage: sessionStorage)
        let api = APIClient(baseURL: configuration.apiBaseURL)
        let cache = Cache(directory: cacheDirectory)
        liveGames = GameSyncRegistry(transport: services.transport, api: api)
        leagues = LeagueRepositoryImpl(rows: services.reader, cache: cache)
        schedule = ScheduleRepositoryImpl(rows: services.reader, cache: cache)
        // One channel per league however many windows show it.
        liveScores = ScoreboardFeed(transport: SharedScoreboardTransport(upstream: services.scoreboardTransport))
        players = PlayerRepositoryImpl(api: api)
        favorites = FavoritesStore(store: store)
    }

    /// `Caches/wehoop-data`.
    public static var defaultCacheDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appending(path: "wehoop-data", directoryHint: .isDirectory)
    }

    /// Foreground or a network change: every followed game pages `/changes`. Returns the
    /// games whose catch-up failed, with the error.
    public func catchUp() async -> [String: String] {
        await liveGames.catchUpAll()
    }
}
