//
//  MockPollingService.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine
@testable import Wehoop

/// Mock implementation of PollingService for testing
class MockPollingService: PollingService {
    private let dataSubject = PassthroughSubject<Data, Error>()
    private var isPolling = false
    private var pollingInterval: TimeInterval = 5.0
    private var pollingEndpoint: String?
    
    var dataPublisher: AnyPublisher<Data, Error> {
        dataSubject.eraseToAnyPublisher()
    }
    
    var polling: Bool {
        isPolling
    }
    
    var currentInterval: TimeInterval? {
        isPolling ? pollingInterval : nil
    }
    
    var currentEndpoint: String? {
        pollingEndpoint
    }
    
    func startPolling(interval: TimeInterval, endpoint: String) {
        isPolling = true
        pollingInterval = interval
        pollingEndpoint = endpoint
    }
    
    func stopPolling() {
        isPolling = false
        pollingEndpoint = nil
    }
    
    // Test helpers
    func simulateDataUpdate(_ data: Data) {
        dataSubject.send(data)
    }
    
    func simulatePollingError(_ error: Error) {
        dataSubject.send(completion: .failure(error))
    }
}
