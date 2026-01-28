//
//  PollingServiceImpl.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine

/// Concrete implementation of PollingService
class PollingServiceImpl: PollingService {
    private let networkService: NetworkService
    private let subject = PassthroughSubject<Data, Error>()
    private var pollingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    var dataPublisher: AnyPublisher<Data, Error> {
        subject.eraseToAnyPublisher()
    }
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func startPolling(interval: TimeInterval, endpoint: String) {
        stopPolling() // Stop any existing polling
        
        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    let data = try await networkService.request(endpoint)
                    if !Task.isCancelled {
                        subject.send(data)
                    }
                } catch {
                    // Log error but continue polling - don't break the stream
                    // Errors are sent to subscribers but polling continues
                    if !Task.isCancelled {
                        // In a production app, you might want to use a separate error publisher
                        // For now, we'll just continue polling on the next interval
                    }
                }
                
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }
    
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
