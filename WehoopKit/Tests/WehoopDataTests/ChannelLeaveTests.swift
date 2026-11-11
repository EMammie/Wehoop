import Foundation
import Realtime
import Synchronization
import Testing
@testable import WehoopData

/// Leaving a channel: a normal leave looks like a loss to the status watcher, whose rejoin
/// must never resubscribe the instance `removeChannel` is unsubscribing.
struct ChannelLeaveTests {
    private final class Log: Sendable {
        private let entries = Mutex<[String]>([])
        func add(_ entry: String) { entries.withLock { $0.append(entry) } }
        var all: [String] { entries.withLock { $0 } }
    }

    @Test("The channel is removed only after the watcher and a rejoin it has in flight have finished")
    func removeWaitsForTheRejoin() async {
        let log = Log()
        let (statuses, status) = AsyncStream.makeStream(of: RealtimeChannelStatus.self)
        // No grace: the loss below starts a resubscribe at once, which takes a while.
        let rejoin = RejoinPolicy(grace: .zero, attempts: 1, baseDelay: .zero) { _ in }
        let watcher = GuestChannel.watchStatuses(statuses, rejoin: rejoin, hooks: StatusHooks(
            isRecovering: { false },
            subscribe: {
                log.add("subscribe started")
                await withCheckedContinuation { done in
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.03) { done.resume() }
                }
                log.add("subscribe finished")
            },
            onJoin: { log.add("joined") }, onEnd: { log.add("ended") }
        ))
        status.yield(.subscribed)
        status.yield(.unsubscribed)   // the leave begins: unsubscribe is under way
        #expect(await eventually { log.all.contains("subscribe started") })
        await GuestChannel.leave(watcher: watcher) { log.add("removed") }
        #expect(log.all == ["joined", "subscribe started", "subscribe finished", "removed"])
    }

    @Test("A leave during the rejoin's grace cancels the rejoin: nothing resubscribes")
    func leaveDuringGrace() async {
        let log = Log()
        let (statuses, status) = AsyncStream.makeStream(of: RealtimeChannelStatus.self)
        let rejoin = RejoinPolicy(grace: .seconds(5), attempts: 3, baseDelay: .seconds(1)) { try await Task.sleep(for: $0) }
        let watcher = GuestChannel.watchStatuses(statuses, rejoin: rejoin, hooks: StatusHooks(
            isRecovering: { false },
            subscribe: { log.add("subscribe") }, onJoin: { log.add("joined") }, onEnd: { log.add("ended") }
        ))
        status.yield(.subscribed)
        status.yield(.unsubscribed)
        #expect(await eventually { log.all == ["joined"] })
        await GuestChannel.leave(watcher: watcher) { log.add("removed") }
        #expect(log.all == ["joined", "removed"])
    }
}
