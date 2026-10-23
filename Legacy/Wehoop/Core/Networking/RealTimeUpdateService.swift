//
//  RealTimeUpdateService.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine

/// Enum representing the current connection mode
enum ConnectionMode {
    case websocket
    case polling
    case disconnected
}

/// Protocol for real-time update service that coordinates WebSocket and polling
protocol RealTimeUpdateService {
    /// Current connection mode
    var connectionMode: ConnectionMode { get }
    
    /// Publisher that emits real-time updates as Data
    var updatePublisher: AnyPublisher<Data, Never> { get }
    
    /// Publisher that emits connection mode changes
    var modePublisher: AnyPublisher<ConnectionMode, Never> { get }
    
    /// Starts the real-time update service
    /// - Parameters:
    ///   - websocketURL: The WebSocket URL to connect to
    ///   - pollingEndpoint: The HTTP endpoint to poll as fallback
    ///   - pollingInterval: The interval between polls (default: 5 seconds)
    func start(websocketURL: String, pollingEndpoint: String, pollingInterval: TimeInterval) async
    
    /// Stops the real-time update service
    func stop()
    
    /// Manually switch to polling mode
    func switchToPolling()
    
    /// Attempt to reconnect WebSocket
    func reconnectWebSocket() async
}
