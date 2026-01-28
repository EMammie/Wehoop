//
//  WebSocketService.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine

/// Protocol for WebSocket service operations
protocol WebSocketService {
    func connect() async throws
    func disconnect()
    func send(_ message: String) async throws
    var messagePublisher: AnyPublisher<String, Never> { get }
}
