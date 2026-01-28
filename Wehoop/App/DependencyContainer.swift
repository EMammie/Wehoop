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
    func isRegistered<T>(_ type: T.Type) -> Bool
}

/// Simple implementation of DependencyContainer
class SimpleDependencyContainer: DependencyContainer {
    private var factories: [String: () -> Any] = [:]
    private let lock = NSLock()
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        let key = typeKey(for: type)
        factories[key] = factory
    }
    
    func resolve<T>() -> T {
        let key = typeKey(for: T.self)
        
        // Get factory without holding lock during execution
        let factory: (() -> Any)?
        lock.lock()
        factory = factories[key]
        lock.unlock()
        
        guard let factory = factory else {
            let availableTypes = lock.withLock { factories.keys.joined(separator: ", ") }
            fatalError("No factory registered for type \(T.self) (key: '\(key)'). Available types: \(availableTypes)")
        }
        
        // Execute factory first, then cast the result
        // This approach works with protocol types because we cast the concrete result, not the function
        let result = factory()
        guard let typedResult = result as? T else {
            fatalError("Factory for type \(T.self) (key: '\(key)') returned incorrect type. Got: \(type(of: result)), Expected: \(T.self)")
        }
        return typedResult
    }
    
    func isRegistered<T>(_ type: T.Type) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let key = typeKey(for: type)
        return factories[key] != nil
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
    container.register(NetworkService.self) {
        URLSessionNetworkService(apiConfiguration: apiConfiguration)
    }
    
    container.register(StorageService.self) {
        UserDefaultsStorageService()
    }
    
    container.register(CacheService.self) {
        MemoryCacheService()
    }
    
    // Real-time Services
    container.register(WebSocketService.self) {
        WebSocketManager()
    }
    
    container.register(PollingService.self) {
        PollingServiceImpl(networkService: container.resolve())
    }
    
    container.register(RealTimeUpdateService.self) {
        RealTimeUpdateServiceCoordinator(
            webSocketService: container.resolve(),
            pollingService: container.resolve(),
            networkService: container.resolve()
        )
    }
    
    // Data Sources
    container.register(RemoteDataSource.self) {
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
    
    container.register(LocalDataSource.self) {
        InMemoryLocalDataSource()
    }
    
    // Repositories
    container.register(GameRepository.self) {
        GameRepositoryImpl(
            remoteDataSource: container.resolve(),
            localDataSource: container.resolve(),
            cacheService: container.resolve()
        )
    }
    
    container.register(PlayerRepository.self) {
        PlayerRepositoryImpl(
            remoteDataSource: container.resolve(),
            localDataSource: container.resolve(),
            cacheService: container.resolve()
        )
    }
    
    container.register(TeamRepository.self) {
        TeamRepositoryImpl(
            remoteDataSource: container.resolve(),
            localDataSource: container.resolve(),
            cacheService: container.resolve()
        )
    }
    
    container.register(FavoriteRepository.self) {
        FavoriteRepositoryImpl(
            storageService: container.resolve()
        )
    }
    
    container.register(LeagueLeadersRepository.self) {
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
    container.register(GetGamesUseCase.self) {
        GetGamesUseCase(gameRepository: container.resolve())
    }
    
    // Note: GetPlayerProfileUseCase and GetTeamPageUseCase are created per-instance
    // via ViewModelFactory since they require playerId/teamId parameters
    
    container.register(GetStatLeadersUseCase.self) {
        GetStatLeadersUseCase(leagueLeadersRepository: container.resolve())
    }
    
    container.register(ManageFavoritesUseCase.self) {
        ManageFavoritesUseCase(favoriteRepository: container.resolve())
    }
    
    // Feature Flags
    container.register(FeatureFlagService.self) {
        UserDefaultsFeatureFlagService()
    }
    
    return container
}
