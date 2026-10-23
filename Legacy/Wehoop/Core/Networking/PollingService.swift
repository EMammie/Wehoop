//
//  PollingService.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine

/// Protocol for polling-based updates as fallback for WebSocket
protocol PollingService {
    /// Starts polling at the specified interval for the given endpoint
    /// - Parameters:
    ///   - interval: The time interval between polls
    ///   - endpoint: The endpoint URL to poll
    func startPolling(interval: TimeInterval, endpoint: String)
    
    /// Stops the current polling operation
    func stopPolling()
    
    /// Publisher that emits data updates from polling
    var dataPublisher: AnyPublisher<Data, Error> { get }
}
