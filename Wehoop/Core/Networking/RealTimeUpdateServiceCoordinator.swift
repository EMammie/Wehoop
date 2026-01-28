//
//  RealTimeUpdateServiceCoordinator.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine

/// Coordinator that manages WebSocket and polling services with automatic fallback
class RealTimeUpdateServiceCoordinator: RealTimeUpdateService {
    private let webSocketService: WebSocketService
    private let pollingService: PollingService
    private let networkService: NetworkService
    
    private var updateSubject = PassthroughSubject<Data, Never>()
    private var modeSubject = CurrentValueSubject<ConnectionMode, Never>(.disconnected)
    
    private var cancellables = Set<AnyCancellable>()
    
    private var websocketURL: String?
    private var pollingEndpoint: String?
    private var pollingInterval: TimeInterval = 5.0
    
    private let lock = NSLock()
    
    var connectionMode: ConnectionMode {
        modeSubject.value
    }
    
    var updatePublisher: AnyPublisher<Data, Never> {
        updateSubject.eraseToAnyPublisher()
    }
    
    var modePublisher: AnyPublisher<ConnectionMode, Never> {
        modeSubject.eraseToAnyPublisher()
    }
    
    init(
        webSocketService: WebSocketService,
        pollingService: PollingService,
        networkService: NetworkService
    ) {
        self.webSocketService = webSocketService
        self.pollingService = pollingService
        self.networkService = networkService
        
        setupWebSocketSubscription()
        setupPollingSubscription()
    }
    
    func start(websocketURL: String, pollingEndpoint: String, pollingInterval: TimeInterval = 5.0) async {
        lock.withLock {
            self.websocketURL = websocketURL
            self.pollingEndpoint = pollingEndpoint
            self.pollingInterval = pollingInterval
        }
        
        // Try WebSocket first
        await attemptWebSocketConnection(url: websocketURL)
    }
    
    func stop() {
        lock.withLock {
            webSocketService.disconnect()
            pollingService.stopPolling()
            modeSubject.send(.disconnected)
        }
    }
    
    func switchToPolling() {
        lock.withLock {
            guard let endpoint = pollingEndpoint else { return }
            
            webSocketService.disconnect()
            modeSubject.send(.polling)
            pollingService.startPolling(interval: pollingInterval, endpoint: endpoint)
        }
    }
    
    func reconnectWebSocket() async {
        var  url: String?
        lock.withLock {
            url = websocketURL
        }
        
        guard let url = url else { return }
        
        // Stop polling before attempting WebSocket
        pollingService.stopPolling()
        
        await attemptWebSocketConnection(url: url)
    }
    
    // MARK: - Private Methods
    
    private func attemptWebSocketConnection(url: String) async {
        do {
            try await webSocketService.connect()
            lock.withLock {
                modeSubject.send(.websocket)
                // Stop polling if it was running
                pollingService.stopPolling()
            }
        } catch {
            // WebSocket failed, fall back to polling
            await fallbackToPolling()
        }
    }
    
    private func fallbackToPolling() async {
        lock.withLock {
            guard let endpoint = pollingEndpoint else {
                modeSubject.send(.disconnected)
                return
            }
            
            modeSubject.send(.polling)
            pollingService.startPolling(interval: pollingInterval, endpoint: endpoint)
        }
    }
    
    private func setupWebSocketSubscription() {
        // Subscribe to WebSocket messages
        webSocketService.messagePublisher
            .compactMap { $0.data(using: .utf8) }
            .sink { [weak self] data in
                self?.updateSubject.send(data)
            }
            .store(in: &cancellables)
    }
    
    private func setupPollingSubscription() {
        // Subscribe to polling updates
        pollingService.dataPublisher
            .catch { _ in Empty<Data, Never>() } // Ignore polling errors, service will handle retry
            .sink { [weak self] data in
                self?.updateSubject.send(data)
            }
            .store(in: &cancellables)
    }
}
