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
    /// Cap for exponential backoff so a long outage doesn't push retries out indefinitely
    private let maxBackoffInterval: TimeInterval = 60

    var dataPublisher: AnyPublisher<Data, Error> {
        subject.eraseToAnyPublisher()
    }

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func startPolling(interval: TimeInterval, endpoint: String) {
        stopPolling() // Stop any existing polling

        pollingTask = Task { [maxBackoffInterval] in
            var consecutiveFailures = 0

            while !Task.isCancelled {
                do {
                    let data = try await networkService.request(endpoint)
                    consecutiveFailures = 0
                    if !Task.isCancelled {
                        subject.send(data)
                    }
                } catch {
                    // Log and keep polling with exponential backoff so a down
                    // endpoint isn't hammered at the base interval forever.
                    // The stream itself stays alive (sending a Combine failure
                    // would terminate it for all subscribers).
                    consecutiveFailures += 1
                    Logger.error("Polling \(endpoint) failed (attempt \(consecutiveFailures)): \(error.localizedDescription)")
                }

                let backoffMultiplier = pow(2.0, Double(min(consecutiveFailures, 6)))
                let delay = consecutiveFailures == 0
                    ? interval
                    : min(interval * backoffMultiplier, maxBackoffInterval)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
    
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
