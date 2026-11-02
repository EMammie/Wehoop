import Foundation
import Realtime
import Synchronization
import Testing
@testable import WehoopData

struct RealtimeStatusTests {
    private func events(_ statuses: [RealtimeChannelStatus]) -> [ChannelWatch.Event] {
        var watch = ChannelWatch()
        return statuses.compactMap { watch.observe($0) }
    }

    @Test("The first join is one .joined (so GameSync catches up after its snapshot)")
    func firstJoin() {
        #expect(events([.unsubscribed, .subscribing, .subscribed]) == [.joined])
    }

    @Test("A rejoin after a loss is lost then joined again; a repeated subscribed yields nothing")
    func rejoinAndRepeat() {
        #expect(events([.unsubscribed, .subscribing, .subscribed, .unsubscribed, .subscribing, .subscribed]) == [.joined, .lost, .joined])
        #expect(events([.subscribed, .subscribed, .subscribed]) == [.joined])
    }

    private final class Calls: Sendable {
        let subscribes = Mutex(0)
        let sleeps = Mutex<[Duration]>([])
    }

    private func policy(_ calls: Calls) -> RejoinPolicy {
        RejoinPolicy(grace: .seconds(5), attempts: 3, baseDelay: .seconds(1)) { d in calls.sleeps.withLock { $0.append(d) } }
    }

    @Test("A channel the client rejoined by itself during the grace is not resubscribed")
    func recoveredByItself() async {
        let calls = Calls()
        let ok = await policy(calls).run(isRecovering: { true }, subscribe: { calls.subscribes.withLock { $0 += 1 } })
        #expect(ok && calls.subscribes.withLock { $0 } == 0)
    }

    @Test("A refused rejoin is retried with doubling backoff, then reported as failed (the stream finishes)")
    func rejoinFails() async {
        let calls = Calls()
        struct Refused: Error {}
        let ok = await policy(calls).run(isRecovering: { false }, subscribe: {
            calls.subscribes.withLock { $0 += 1 }
            throw Refused()
        })
        #expect(!ok && calls.subscribes.withLock { $0 } == 3)
        #expect(calls.sleeps.withLock { $0 } == [.seconds(5), .seconds(1), .seconds(2)])
    }

    @Test("A rejoin that succeeds on the second attempt recovers")
    func rejoinSecondAttempt() async {
        let calls = Calls()
        struct Refused: Error {}
        let ok = await policy(calls).run(isRecovering: { false }, subscribe: {
            let n = calls.subscribes.withLock { $0 += 1; return $0 }
            if n == 1 { throw Refused() }
        })
        #expect(ok && calls.subscribes.withLock { $0 } == 2)
    }
}
