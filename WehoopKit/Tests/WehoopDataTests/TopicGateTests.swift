import Foundation
import Synchronization
import Testing
@testable import WehoopData

/// Overlapping subscriptions of one topic: the second joins only after the first has
/// removed its channel (supabase-swift reuses the instance it is still unsubscribing).
struct TopicGateTests {
    private final class Log: Sendable {
        private let entries = Mutex<[String]>([])
        func add(_ entry: String) { entries.withLock { $0.append(entry) } }
        var all: [String] { entries.withLock { $0 } }
    }

    /// A subscription as GuestChannel runs it: join, stay until cancelled, then a slow removal.
    private func subscription(_ name: String, gate: TopicGate, topic: String, log: Log) -> Task<Void, Never> {
        Task {
            await gate.serialized(topic) {
                log.add("\(name) join")
                while !Task.isCancelled { try? await Task.sleep(for: .milliseconds(1)) }
                // removeChannel awaiting unsubscribe: not cut short by the cancellation.
                await withCheckedContinuation { done in
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.02) { done.resume() }
                }
                log.add("\(name) removed")
            }
        }
    }

    @Test("A new subscription of a topic joins only after the previous one has removed its channel")
    func overlappingSubscriptionsOfOneTopic() async {
        let gate = TopicGate()
        let log = Log()
        let first = subscription("A", gate: gate, topic: "league:wnba:scores", log: log)
        #expect(await eventually { log.all == ["A join"] })
        first.cancel()                       // a day tap or foreground restart: the old run leaves...
        let second = subscription("B", gate: gate, topic: "league:wnba:scores", log: log)   // ...as the new one starts
        #expect(await eventually { log.all.count == 3 })
        #expect(log.all == ["A join", "A removed", "B join"])
        second.cancel()
        await second.value
        #expect(await gate.heldTopics.isEmpty)
    }

    @Test("Other topics do not wait")
    func otherTopicsDoNotWait() async {
        let gate = TopicGate()
        let log = Log()
        let first = subscription("A", gate: gate, topic: "game:g1", log: log)
        let second = subscription("B", gate: gate, topic: "league:wnba:scores", log: log)
        #expect(await eventually { Set(log.all) == ["A join", "B join"] })
        first.cancel()
        second.cancel()
        await first.value
        await second.value
    }

    @Test("A subscription cancelled while waiting never joins, and the topic is free afterwards")
    func cancelledWhileWaiting() async {
        let gate = TopicGate()
        let log = Log()
        let first = subscription("A", gate: gate, topic: "t", log: log)
        #expect(await eventually { log.all == ["A join"] })
        let waiting = subscription("B", gate: gate, topic: "t", log: log)
        #expect(await eventually { await gate.waitingCount == 1 })   // B is parked on the gate
        waiting.cancel()                                             // onCancel wakes it
        #expect(await eventually { await gate.waitingCount == 0 })
        await waiting.value
        first.cancel()
        await first.value
        #expect(log.all == ["A join", "A removed"])
        #expect(await gate.heldTopics.isEmpty)
        let third = subscription("C", gate: gate, topic: "t", log: log)
        #expect(await eventually { log.all.last == "C join" })
        third.cancel()
        await third.value
    }
}
