//
//  MockWebSocketService.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine
@testable import Wehoop

/// Mock implementation of WebSocketService for testing
class MockWebSocketService: WebSocketService {
    private let messageSubject = PassthroughSubject<String, Never>()
    private var shouldSucceedConnect = true
    private var shouldSucceedSend = true
    private var isConnected = false
    
    var messagePublisher: AnyPublisher<String, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    // Configuration for testing
    var connectShouldSucceed: Bool {
        get { shouldSucceedConnect }
        set { shouldSucceedConnect = newValue }
    }
    
    var sendShouldSucceed: Bool {
        get { shouldSucceedSend }
        set { shouldSucceedSend = newValue }
    }
    
    var connected: Bool {
        isConnected
    }
    
    func connect() async throws {
        if shouldSucceedConnect {
            isConnected = true
        } else {
            isConnected = false
            throw NSError(domain: "MockWebSocketError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])
        }
    }
    
    func disconnect() {
        isConnected = false
    }
    
    func send(_ message: String) async throws {
        if !shouldSucceedSend {
            throw NSError(domain: "MockWebSocketError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Send failed"])
        }
    }
    
    // Test helpers
    func simulateMessage(_ message: String) {
        messageSubject.send(message)
    }
    
    func simulateConnectionSuccess() {
        isConnected = true
    }
    
    func simulateConnectionFailure() {
        isConnected = false
    }
}
