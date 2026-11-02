import Foundation

/// One HTTP exchange. `URLSession` in the app; a stub in tests (no live network in unit tests).
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

extension URLSession: HTTPTransport {
    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }
}

/// When a failed request is tried again: on HTTP 5xx and on timeouts or a dropped
/// connection, with exponential backoff (`baseDelay`, doubled each time, plus up to 25 %
/// jitter). A 4xx is the caller's mistake or a missing row and is never retried.
public struct RetryPolicy: Sendable {
    public let maxAttempts: Int
    public let baseDelay: Duration

    public init(maxAttempts: Int = 3, baseDelay: Duration = .milliseconds(500)) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = baseDelay
    }

    public static let none = RetryPolicy(maxAttempts: 1)

    func delay(afterAttempt attempt: Int, jitter: Double) -> Duration {
        baseDelay * Double(1 << (attempt - 1)) * (1 + 0.25 * min(max(jitter, 0), 1))
    }

    static func isRetryable(status: Int) -> Bool { (500...599).contains(status) }

    static func isRetryable(_ error: any Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        return [.timedOut, .networkConnectionLost, .cannotConnectToHost, .notConnectedToInternet]
            .contains(urlError.code)
    }
}
