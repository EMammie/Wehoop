import Contracts
import Foundation
import Testing
import TestSupport
@testable import WehoopData

struct APIClientTests {
    private let base = URL(string: "http://127.0.0.1:3000")!

    private func client(_ http: StubHTTP, clock: RecordingClock = RecordingClock()) -> APIClient {
        APIClient(
            baseURL: base, transport: http, retry: RetryPolicy(maxAttempts: 3, baseDelay: .milliseconds(100)), clock: clock, jitter: { 0 }
        )
    }

    @Test("The snapshot endpoint decodes the golden body and asks the configured host")
    func snapshot() async throws {
        let body = try Golden.data("wnba/sim-93ee7c68/snapshot.json")
        let http = StubHTTP([.status(200, body)])
        let snapshot = try await client(http).snapshot(gameId: "2cca74a3-7639-4f3b-a27c-7591d0be1838")
        #expect(snapshot == (try Golden.snapshot(.wnba)))
        let expected = "http://127.0.0.1:3000/v1/games/2cca74a3-7639-4f3b-a27c-7591d0be1838/snapshot"
        #expect(http.requests.map(\.url?.absoluteString) == [expected])
    }

    @Test("/changes carries after and a limit capped at the backend's 500")
    func changesQuery() async throws {
        let body = try Golden.data("unrivaled/docs-838316ea/changes-tail.json")
        let http = StubHTTP([.status(200, body)])
        _ = try await client(http).changes(gameId: "g", after: 12, limit: 9000)
        #expect(http.requests.first?.url?.absoluteString == "http://127.0.0.1:3000/v1/games/g/changes?after=12&limit=500")
    }

    @Test("A 5xx and a timeout are retried with doubling backoff; then the body is returned")
    func retriesThenSucceeds() async throws {
        let body = try Golden.data("players/boston.json")
        let http = StubHTTP([.status(503), .failure(.timedOut), .status(200, body)])
        let clock = RecordingClock()
        let player = try await client(http, clock: clock).player(id: "unrivaled:54b8a881-27f7-4735-b499-0c3adf0286b0")
        #expect(player.player.fullName == (try Golden.player(.boston)).player.fullName)
        #expect(http.requests.count == 3)
        #expect(clock.sleeps == [.milliseconds(100), .milliseconds(200)])
    }

    @Test("A 404 is notFound at once; a 400 is never retried")
    func clientErrorsAreNotRetried() async throws {
        let notFound = StubHTTP([.status(404)])
        await #expect(throws: APIError.notFound) { try await client(notFound).player(id: "wnba:nobody") }
        #expect(notFound.requests.count == 1)
        let bad = StubHTTP([.status(400)])
        await #expect(throws: APIError.status(400)) { try await client(bad).snapshot(gameId: "x") }
        #expect(bad.requests.count == 1)
    }

    @Test("Retries stop after maxAttempts and report the last status")
    func retriesExhausted() async throws {
        let http = StubHTTP([.status(502), .status(502), .status(503)])
        await #expect(throws: APIError.status(503)) { try await client(http).snapshot(gameId: "x") }
        #expect(http.requests.count == 3)
    }

    @Test("An id that looks like a URL stays a path segment on the configured host")
    func hostScoped() async throws {
        let http = StubHTTP([.status(404)])
        _ = try? await client(http).player(id: "https://evil.example/x?y=1#z")
        let url = try #require(http.requests.first?.url)
        #expect(url.host == "127.0.0.1" && url.port == 3000)
        #expect(url.query == nil && url.fragment == nil)
        #expect(url.path.hasPrefix("/v1/players/"))
    }

    @Test("A body that does not match the contract is a decoding error, not a crash")
    func decodingError() async throws {
        let http = StubHTTP([.status(200, Data(#"{"nope":1}"#.utf8))])
        await #expect {
            try await client(http).snapshot(gameId: "x")
        } throws: { error in
            if case APIError.decoding = error { return true }
            return false
        }
    }
}

struct BackendConfigurationTests {
    @Test("Reads the three variables; a missing one or a non-http URL is reported by name")
    func fromEnvironment() throws {
        let env = [
            "WEHOOP_API_URL": "http://127.0.0.1:3000", "WEHOOP_SUPABASE_URL": "http://127.0.0.1:54321", "WEHOOP_SUPABASE_ANON_KEY": "k",
        ]
        let config = try BackendConfiguration.from(environment: env)
        #expect(config.apiBaseURL.port == 3000 && config.supabaseURL.port == 54321)
        #expect(throws: BackendConfiguration.Problem.missing("WEHOOP_SUPABASE_ANON_KEY")) {
            try BackendConfiguration.from(environment: env.filter { $0.key != "WEHOOP_SUPABASE_ANON_KEY" })
        }
        #expect(throws: BackendConfiguration.Problem.invalidURL("WEHOOP_API_URL")) {
            try BackendConfiguration.from(environment: env.merging(["WEHOOP_API_URL": "file:///etc"]) { $1 })
        }
    }

    @Test("Neither the description, the debug description nor a dump contains the key")
    func redacted() {
        let config = BackendConfiguration(
            apiBaseURL: URL(string: "http://a")!, supabaseURL: URL(string: "http://b")!, anonKey: "secret-value"
        )
        var dumped = ""
        dump(config, to: &dumped)
        for text in [config.description, String(reflecting: config), dumped] {
            #expect(!text.contains("secret-value"), "\(text)")
        }
    }
}
