//
//  WebSocketManager.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine

/// WebSocket manager implementation
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
        // Implementation will be added when WebSocket endpoint is available
        // For now, this is a stub that doesn't crash
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    func send(_ message: String) async throws {
        // Implementation will be added when WebSocket endpoint is available
        // For now, this is a stub that doesn't crash
    }
}
