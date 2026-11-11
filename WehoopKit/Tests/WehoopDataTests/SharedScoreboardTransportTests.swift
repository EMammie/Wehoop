import Contracts
import Foundation
import Synchronization
import Testing
import TestSupport
@testable import WehoopData

/// Two followers of one league (two iPad windows on its Scores) share one channel.
struct SharedScoreboardTransportTests {
    private final class Inbox: Sendable {
        let received = Mutex<[ScoreboardMessage]>([])
        let finished = Mutex(false)
    }

    /// Collects what one follower receives.
    private final class Follower: Sendable {
        let inbox = Inbox()
        let task: Task<Void, Never>

        init(_ stream: AsyncStream<ScoreboardMessage>) {
            let inbox = inbox
            task = Task {
                for await message in stream { inbox.received.withLock { $0.append(message) } }
                inbox.finished.withLock { $0 = true }
            }
        }

        var messages: [ScoreboardMessage] { inbox.received.withLock { $0 } }
        var isFinished: Bool { inbox.finished.withLock { $0 } }
    }

    @Test("Two followers of one league share one subscription and both receive every message")
    func twoFollowersShareOne() async throws {
        let upstream = ScriptedScoreboardTransport()
        let shared = SharedScoreboardTransport(upstream: upstream)
        let board = try Golden.scoreboard(.wnba)
        let first = Follower(shared.messages(league: "wnba"))
        upstream.send(.reconnected)
        #expect(await eventually { first.messages == [.reconnected] })
        // A follower arriving after the join is told the channel is joined, so it re-reads.
        let second = Follower(shared.messages(league: "wnba"))
        #expect(await eventually { second.messages == [.reconnected] })
        upstream.send(.scores(board))
        #expect(await eventually { first.messages == [.reconnected, .scores(board)] && second.messages == [.reconnected, .scores(board)] })
        #expect(upstream.subscribedLeagues == ["wnba"])
        first.task.cancel()
        second.task.cancel()
    }

    @Test("One follower leaving does not end the other; the last one leaving removes the channel")
    func lastLeavingEnds() async throws {
        let upstream = ScriptedScoreboardTransport()
        let shared = SharedScoreboardTransport(upstream: upstream)
        let board = try Golden.scoreboard(.wnba)
        let first = Follower(shared.messages(league: "wnba"))
        let second = Follower(shared.messages(league: "wnba"))
        upstream.send(.reconnected)
        #expect(await eventually { first.messages.count == 1 && second.messages.count == 1 })

        first.task.cancel()
        await first.task.value
        upstream.send(.scores(board))
        #expect(await eventually { second.messages == [.reconnected, .scores(board)] })
        #expect(upstream.terminated.isEmpty && shared.activeLeagues == ["wnba"])

        second.task.cancel()
        await second.task.value
        #expect(await eventually { upstream.terminated == [0] })
        #expect(shared.activeLeagues.isEmpty)

        // The next follower starts a fresh subscription.
        let third = Follower(shared.messages(league: "wnba"))
        #expect(upstream.subscribedLeagues == ["wnba", "wnba"])
        third.task.cancel()
    }

    @Test("Leagues are separate subscriptions; a channel lost for good ends every follower of it")
    func upstreamEnds() async {
        let upstream = ScriptedScoreboardTransport()
        let shared = SharedScoreboardTransport(upstream: upstream)
        let other = Follower(shared.messages(league: "ncaawb"))
        let first = Follower(shared.messages(league: "wnba"))
        let second = Follower(shared.messages(league: "wnba"))
        #expect(upstream.subscribedLeagues == ["ncaawb", "wnba"])
        upstream.end()   // the wnba channel (the last subscription)
        #expect(await eventually { first.isFinished && second.isFinished })
        #expect(!other.isFinished && shared.activeLeagues == ["ncaawb"])
        other.task.cancel()
    }
}
