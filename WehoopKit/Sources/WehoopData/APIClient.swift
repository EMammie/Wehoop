import Contracts
import Foundation
import LiveEngine

/// What a wehoop-api request can fail with.
public enum APIError: Error, Equatable {
    /// HTTP 404: the game or player does not exist.
    case notFound
    /// Any other non-2xx status, after retries.
    case status(Int)
    /// The response did not decode as the contract type.
    case decoding(String)
    /// A request was about to leave for a host other than the configured one.
    case foreignHost(String)
}

/// wehoop-api's `/v1` endpoints, typed by Contracts. One decoder; retry with backoff on 5xx
/// and timeouts; every request is built from `baseURL` and refused if it would go anywhere
/// else, so nothing configured for this host is ever sent to another.
public struct APIClient: GameAPI, Sendable {
    public let baseURL: URL
    private let transport: any HTTPTransport
    private let retry: RetryPolicy
    private let clock: any SyncClock
    private let jitter: @Sendable () -> Double

    public init(
        baseURL: URL,
        transport: any HTTPTransport = URLSession.shared,
        retry: RetryPolicy = RetryPolicy(),
        clock: any SyncClock = SystemClock(),
        jitter: @escaping @Sendable () -> Double = { Double.random(in: 0...1) }
    ) {
        self.baseURL = baseURL
        self.transport = transport
        self.retry = retry
        self.clock = clock
        self.jitter = jitter
    }

    // MARK: Endpoints

    /// `GET /v1/games/:id/snapshot`.
    public func snapshot(gameId: String) async throws -> Snapshot {
        try await get(["v1", "games", gameId, "snapshot"])
    }

    /// `GET /v1/games/:id/changes?after=&limit=` (the backend caps `limit` at 500).
    public func changes(gameId: String, after: Int, limit: Int) async throws -> ChangesPage {
        try await get(
            ["v1", "games", gameId, "changes"],
            query: [URLQueryItem(name: "after", value: String(after)), URLQueryItem(name: "limit", value: String(min(max(limit, 1), 500)))]
        )
    }

    /// `GET /v1/players/:id`, where `id` is a canonical uuid or `<league>:<providerId>`.
    public func player(id: String) async throws -> PlayerResponse {
        try await get(["v1", "players", id])
    }

    // MARK: Request

    static let decoder = JSONDecoder()

    func get<T: Decodable>(_ path: [String], query: [URLQueryItem] = []) async throws -> T {
        let request = try makeRequest(path: path, query: query)
        var attempt = 1
        while true {
            do {
                let (data, response) = try await transport.send(request)
                switch response.statusCode {
                case 200...299:
                    do { return try Self.decoder.decode(T.self, from: data) } catch {
                        throw APIError.decoding(String(describing: error))
                    }
                case 404:
                    throw APIError.notFound
                case let status where RetryPolicy.isRetryable(status: status) && attempt < retry.maxAttempts:
                    break
                case let status:
                    throw APIError.status(status)
                }
            } catch let error where RetryPolicy.isRetryable(error) && attempt < retry.maxAttempts {
                // A timeout or dropped connection: try again below.
            }
            try await clock.sleep(for: retry.delay(afterAttempt: attempt, jitter: jitter()))
            attempt += 1
        }
    }

    func makeRequest(path: [String], query: [URLQueryItem]) throws -> URLRequest {
        var url = baseURL
        for segment in path { url.append(path: segment) }
        if !query.isEmpty { url.append(queryItems: query) }
        guard url.scheme == baseURL.scheme, url.host == baseURL.host, url.port == baseURL.port else {
            throw APIError.foreignHost(url.host ?? "")
        }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
