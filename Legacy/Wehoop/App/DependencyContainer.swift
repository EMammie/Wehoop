//
//  DependencyContainer.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Protocol for dependency injection container
protocol DependencyContainer {
    func resolve<T>() -> T
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T)
    func isRegistered<T>(_ type: T.Type) -> Bool
}

/// Simple implementation of DependencyContainer
class SimpleDependencyContainer: DependencyContainer {
    private struct Registration {
        let factory: () -> Any
        let isSingleton: Bool
    }

    private var registrations: [String: Registration] = [:]
    private var singletons: [String: Any] = [:]
    // Recursive: singleton factories run under the lock and resolve their own dependencies
    private let lock = NSRecursiveLock()

    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        register(type, factory: factory, isSingleton: false)
    }

    /// Register a type whose first resolved instance is memoized and shared by all
    /// subsequent resolves. Use for stateful services (caches, sessions, repositories)
    /// that must be shared across the app.
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        register(type, factory: factory, isSingleton: true)
    }

    private func register<T>(_ type: T.Type, factory: @escaping () -> T, isSingleton: Bool) {
        lock.lock()
        defer { lock.unlock() }
        let key = typeKey(for: type)
        registrations[key] = Registration(factory: factory, isSingleton: isSingleton)
        singletons[key] = nil
    }

    func resolve<T>() -> T {
        let key = typeKey(for: T.self)

        lock.lock()
        defer { lock.unlock() }

        if let instance = singletons[key] as? T {
            return instance
        }

        guard let registration = registrations[key] else {
            let availableTypes = registrations.keys.joined(separator: ", ")
            fatalError("No factory registered for type \(T.self) (key: '\(key)'). Available types: \(availableTypes)")
        }

        // Execute factory first, then cast the result
        // This approach works with protocol types because we cast the concrete result, not the function
        let result = registration.factory()
        guard let typedResult = result as? T else {
            fatalError("Factory for type \(T.self) (key: '\(key)') returned incorrect type. Got: \(type(of: result)), Expected: \(T.self)")
        }

        if registration.isSingleton {
            singletons[key] = typedResult
        }
        return typedResult
    }

    func isRegistered<T>(_ type: T.Type) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let key = typeKey(for: type)
        return registrations[key] != nil
    }

    /// Generate a consistent type key for a type
    private func typeKey<T>(for type: T.Type) -> String {
        // Use the full type name including module for better uniqueness
        return String(describing: type)
    }
}

// Helper extension for NSLock to use withLock
extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}

/// Global function to configure and return a dependency container
func configureDependencyContainer() -> DependencyContainer {
    let container = SimpleDependencyContainer()
    
    // API Configuration (loads from Info.plist/build settings)
    // Register as optional - will be nil if not configured (allows mock data to work)
    let apiConfiguration = APIConfiguration.load()
    
    // Core Services
    container.registerSingleton(NetworkService.self) {
        URLSessionNetworkService(apiConfiguration: apiConfiguration)
    }
    
    container.registerSingleton(StorageService.self) {
        UserDefaultsStorageService()
    }
    
    container.registerSingleton(CacheService.self) {
        MemoryCacheService()
    }
    
    // Real-time Services
    container.registerSingleton(WebSocketService.self) {
        WebSocketManager()
    }
    
    container.registerSingleton(PollingService.self) {
        PollingServiceImpl(networkService: container.resolve())
    }
    
    container.registerSingleton(RealTimeUpdateService.self) {
        RealTimeUpdateServiceCoordinator(
            webSocketService: container.resolve(),
            pollingService: container.resolve(),
            networkService: container.resolve()
        )
    }
    
    // Data Sources
    container.registerSingleton(RemoteDataSource.self) {
        // Use SportradarRemoteDataSource if API configuration is available
        // Otherwise fall back to MockRemoteDataSource for development/testing
        if let apiConfiguration = apiConfiguration {
            let networkService = container.resolve() as NetworkService
            let apiClient = SportradarAPIClient(apiConfiguration: apiConfiguration)
            return SportradarRemoteDataSource(
                networkService: networkService,
                apiClient: apiClient
            ) as RemoteDataSource
        } else {
            // Fallback to mock data source when API configuration is not available
            print("⚠️ API Configuration not available - using MockRemoteDataSource")
            return MockRemoteDataSource() as RemoteDataSource
        }
    }
    
    container.registerSingleton(LocalDataSource.self) {
        InMemoryLocalDataSource()
    }
    
    // Repositories
    container.registerSingleton(GameRepository.self) {
        GameRepositoryImpl(
            remoteDataSource: container.resolve(),
            localDataSource: container.resolve(),
            cacheService: container.resolve()
        )
    }
    
    container.registerSingleton(PlayerRepository.self) {
        PlayerRepositoryImpl(
            remoteDataSource: container.resolve(),
            localDataSource: container.resolve(),
            cacheService: container.resolve()
        )
    }
    
    container.registerSingleton(TeamRepository.self) {
        TeamRepositoryImpl(
            remoteDataSource: container.resolve(),
            localDataSource: container.resolve(),
            cacheService: container.resolve()
        )
    }
    
    container.registerSingleton(FavoriteRepository.self) {
        FavoriteRepositoryImpl(
            storageService: container.resolve()
        )
    }
    
    container.registerSingleton(LeagueLeadersRepository.self) {
        let remoteDataSource = container.resolve() as RemoteDataSource
        // Cast to FullRemoteDataSource - SportradarRemoteDataSource implements it
        guard let fullRemoteDataSource = remoteDataSource as? FullRemoteDataSource else {
            fatalError("RemoteDataSource must implement FullRemoteDataSource for LeagueLeadersRepository")
        }
        return LeagueLeadersRepositoryImpl(
          leagueLeaderDataSource: fullRemoteDataSource,
            localDataSource: container.resolve(),
            cacheService: container.resolve()
        )
    }
    
    // Use Cases
    container.registerSingleton(GetGamesUseCase.self) {
        GetGamesUseCase(gameRepository: container.resolve())
    }
    
    // Note: GetPlayerProfileUseCase and GetTeamPageUseCase are created per-instance
    // via ViewModelFactory since they require playerId/teamId parameters
    
    container.registerSingleton(GetStatLeadersUseCase.self) {
        GetStatLeadersUseCase(leagueLeadersRepository: container.resolve())
    }
    
    container.registerSingleton(ManageFavoritesUseCase.self) {
        ManageFavoritesUseCase(favoriteRepository: container.resolve())
    }
    
    // Feature Flags
    container.registerSingleton(FeatureFlagService.self) {
        UserDefaultsFeatureFlagService()
    }
    
    return container
}
