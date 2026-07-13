//
//  WebSocketManager.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine

/// Errors thrown by WebSocketManager
enum WebSocketError: LocalizedError {
    /// No WebSocket endpoint exists yet; callers should fall back to polling
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "WebSocket endpoint is not configured"
        }
    }
}

/// WebSocket manager implementation
///
/// No real WebSocket endpoint exists yet. `connect()` and `send(_:)` throw
/// `WebSocketError.notConfigured` so `RealTimeUpdateServiceCoordinator`
/// falls back to polling instead of reporting a connection that never
/// delivers messages. Replace with a `URLSessionWebSocketTask` receive loop
/// once an endpoint is available.
class WebSocketManager: WebSocketService {
    private let subject = PassthroughSubject<String, Never>()
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession

    var messagePublisher: AnyPublisher<String, Never> {
        subject.eraseToAnyPublisher()
    }

    init(session: URLSession = .shared) {
        self.session = session
    }

    func connect() async throws {
        throw WebSocketError.notConfigured
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    func send(_ message: String) async throws {
        throw WebSocketError.notConfigured
    }
}
