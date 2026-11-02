import Foundation
import LiveEngine
import Synchronization
@testable import WehoopData

/// An HTTP transport answering from a script, recording every request.
final class StubHTTP: HTTPTransport {
    enum Reply {
        case status(Int, Data = Data())
        case failure(URLError.Code)
    }

    private let state: Mutex<(replies: [Reply], requests: [URLRequest])>

    init(_ replies: [Reply]) { state = Mutex((replies, [])) }

    var requests: [URLRequest] { state.withLock { $0.requests } }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let reply: Reply = state.withLock {
            $0.requests.append(request)
            return $0.replies.isEmpty ? .status(599) : $0.replies.removeFirst()
        }
        switch reply {
        case .status(let code, let body):
            return (body, HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!)
        case .failure(let code):
            throw URLError(code)
        }
    }
}

/// A clock whose sleeps return at once and are recorded.
final class RecordingClock: SyncClock {
    private let slept = Mutex<[Duration]>([])
    var sleeps: [Duration] { slept.withLock { $0 } }
    func now() -> Date { Date(timeIntervalSince1970: 1_800_000_000) }
    func sleep(for duration: Duration) async throws { slept.withLock { $0.append(duration) } }
}

/// A clock whose sleeps wait until `release()` (the registry's grace period).
final class GateClock: SyncClock {
    private let waiters = Mutex<[UUID: CheckedContinuation<Void, Never>]>([:])
    func now() -> Date { Date(timeIntervalSince1970: 1_800_000_000) }
    func sleep(for duration: Duration) async throws {
        let id = UUID()
        await withTaskCancellationHandler {
            await withCheckedContinuation { c in
                waiters.withLock { $0[id] = c }
            }
        } onCancel: {
            waiters.withLock { $0.removeValue(forKey: id) }?.resume()
        }
        try Task.checkCancellation()
    }

    /// Sleepers currently waiting.
    var sleeping: Int { waiters.withLock { $0.count } }

    /// Wakes every sleeper.
    func release() {
        let all = waiters.withLock { w in defer { w = [:] }; return w }
        all.values.forEach { $0.resume() }
    }
}

/// Polls `condition` (yielding) until it holds or ~2 s pass.
func eventually(_ condition: @Sendable () async -> Bool) async -> Bool {
    for _ in 0..<2000 {
        if await condition() { return true }
        try? await Task.sleep(for: .milliseconds(1))
    }
    return false
}
