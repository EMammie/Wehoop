//
//  RateLimiter.swift
//  Wehoop
//

import Foundation

/// Spaces granted slots at least `minimumInterval` apart across concurrent callers.
///
/// Callers `await waitForSlot()` before performing a rate-limited operation.
/// Slot assignment is serialized by the actor, so N concurrent callers are
/// granted slots at t, t+interval, t+2×interval, … regardless of arrival order.
/// Sportradar trial keys allow 1 request/second; exceeding it returns HTTP 429.
actor RateLimiter {
    private let minimumInterval: Duration
    private let clock = ContinuousClock()
    private var nextSlot: ContinuousClock.Instant?

    /// - Parameter minimumInterval: Minimum spacing between granted slots, in
    ///   seconds. Pass 0 to disable waiting (useful in tests).
    init(minimumInterval: TimeInterval) {
        self.minimumInterval = .milliseconds(Int(minimumInterval * 1000))
    }

    /// Suspends until the caller's slot arrives. Throws `CancellationError`
    /// if the surrounding task is cancelled while waiting.
    func waitForSlot() async throws {
        guard minimumInterval > .zero else { return }
        let now = clock.now
        let slot = max(nextSlot ?? now, now)
        nextSlot = slot + minimumInterval
        try await clock.sleep(until: slot, tolerance: .milliseconds(10))
    }
}
