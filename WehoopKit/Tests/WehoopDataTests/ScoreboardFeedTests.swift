import Contracts
import Domain
import Foundation
import Supabase
import Synchronization
import Testing
import TestSupport
@testable import WehoopData

/// A scoreboard transport whose messages the test sends; each `messages` call is one subscription.
final class ScriptedScoreboardTransport: ScoreboardTransport {
    private let state = Mutex<(leagues: [String], continuations: [AsyncStream<ScoreboardMessage>.Continuation])>(([], []))

    var subscribedLeagues: [String] { state.withLock { $0.leagues } }

    func messages(league: String) -> AsyncStream<ScoreboardMessage> {
        let (stream, continuation) = AsyncStream.makeStream(of: ScoreboardMessage.self)
        state.withLock {
            $0.leagues.append(league)
            $0.continuations.append(continuation)
        }
        return stream
    }

    func send(_ message: ScoreboardMessage) {
        state.withLock { $0.continuations.last }?.yield(message)
    }

    func end() {
        state.withLock { $0.continuations.last }?.finish()
    }
}

struct ScoreboardFeedTests {
    /// A broadcast message as supabase-swift hands it to callbacks: `{event, payload, type}`.
    private func message(event: String, payload: some Encodable) throws -> JSONObject {
        let body = try JSONDecoder().decode(AnyJSON.self, from: JSONEncoder().encode(payload))
        let json = try JSONEncoder().encode(["event": AnyJSON.string(event), "type": .string("broadcast"), "payload": body])
        return try JSONDecoder().decode(JSONObject.self, from: json)
    }

    @Test("A scores broadcast decodes to the golden Scoreboard; other events and bad payloads are ignored", arguments: LeagueCode.known)
    func decode(league: LeagueCode) throws {
        let board = try Golden.scoreboard(league)
        #expect(RealtimeScoreboardTransport.decode(try message(event: "scores", payload: board)) == .scores(board))
        let bytes = try Golden.data("\(league.rawValue)/scoreboard.json")
        #expect(RealtimeScoreboardTransport.decode(event: "scores", payload: bytes) == .scores(board))
        #expect(RealtimeScoreboardTransport.decode(try message(event: "pulse", payload: board)) == nil)
        #expect(RealtimeScoreboardTransport.decode(try message(event: "scores", payload: ["deltas": 1])) == nil)
    }

    @Test("A golden delta maps to the Domain update: score, status, period, frozen clock, seq and time")
    func mapping() throws {
        let board = try Golden.scoreboard(.wnba)
        let delta = try #require(board.deltas.first { $0.gameId == "2cca74a3-7639-4f3b-a27c-7591d0be1838" })
        let update = Mapping.scoreUpdate(delta)
        #expect(update.gameId == Game.ID(delta.gameId))
        #expect(update.score == Domain.Score(home: 93, away: 85))
        #expect(update.status == .closed)
        #expect(update.period == GamePeriod(number: 4, kind: .quarter, sequence: 4))
        #expect(update.clockRemaining == 0)
        #expect(update.latestSeq == 1233)
        #expect(update.observedAt == ISODate.parse("2026-10-14T16:24:52.366Z"))
        #expect(update.replay == nil)
        let pregame = try #require(board.deltas.first { $0.period == nil })
        #expect(Mapping.scoreUpdate(pregame).period == nil && Mapping.scoreUpdate(pregame).clockRemaining == nil)
    }

    @Test("A replayed game's delta carries its label")
    func replayLabel() {
        let delta = ScoreboardDelta(
            gameId: "g1", score: Contracts.Score(home: 2, away: 0), status: .inprogress,
            period: PeriodRef(number: 1, type: .elam, sequence: 5), clock: nil, latestSeq: 3, observedAt: nil, replay: .synthetic
        )
        let update = Mapping.scoreUpdate(delta)
        #expect(update.replay == .synthetic && update.period?.kind == .elam && update.observedAt == nil)
    }

    @Test("The schedule row's observed_at maps, so a delta can be compared with it")
    func rowObservedAt() throws {
        let row = try #require(try Golden.schedule(.wnba).first { $0.id.hasPrefix("2cca74a3") })
        #expect(Mapping.game(row)?.observedAt == ISODate.parse("2026-10-14T16:24:52.366+00:00"))
    }

    @Test("Joins become .subscribed; the league's deltas become updates; another league's and empty messages are dropped")
    func feed() async throws {
        let transport = ScriptedScoreboardTransport()
        let feed = ScoreboardFeed(transport: transport)
        var events = feed.scores(league: League.Code("wnba")).makeAsyncIterator()
        #expect(transport.subscribedLeagues == ["wnba"])

        let wnba = try Golden.scoreboard(.wnba)
        let other = try Golden.scoreboard(.ncaawb)
        let empty = Scoreboard(v: 1, type: "scores", league: .wnba, deltas: [], sentAt: wnba.sentAt)
        transport.send(.reconnected)
        transport.send(.scores(other))
        transport.send(.scores(empty))
        transport.send(.scores(wnba))
        transport.send(.reconnected)
        transport.end()

        #expect(await events.next() == .subscribed)
        #expect(await events.next() == .updates(wnba.deltas.map(Mapping.scoreUpdate)))
        #expect(await events.next() == .subscribed)
        #expect(await events.next() == nil, "the feed ends when the channel is lost for good")
    }

    private final class CountingRows: RowSource {
        let fetches = Mutex(0)
        let failing = Mutex(false)

        func schedule(league: String, from: Date, to: Date) async throws -> [ScheduleRow] {
            fetches.withLock { $0 += 1 }
            if failing.withLock({ $0 }) { throw URLError(.notConnectedToInternet) }
            return try Golden.schedule(LeagueCode(rawValue: league))
        }

        func scheduleRow(id: String) async throws -> ScheduleRow? { nil }
        func leagues() async throws -> [LeagueRow] { [] }
    }

    @Test("The latest read goes past the cache; offline it still answers with the cached day")
    func latestReadsPastTheCache() async throws {
        let rows = CountingRows()
        let repository = ScheduleRepositoryImpl(rows: rows, cache: Cache(directory: nil))
        let league = League.Code("wnba")
        let (from, to) = (Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 86_400))
        _ = try await repository.games(league: league, from: from, to: to)
        _ = try await repository.games(league: league, from: from, to: to)
        #expect(rows.fetches.withLock { $0 } == 1)
        _ = try await repository.latestGames(league: league, from: from, to: to)
        #expect(rows.fetches.withLock { $0 } == 2)
        rows.failing.withLock { $0 = true }
        let offline = try await repository.latestGames(league: league, from: from, to: to)
        #expect(rows.fetches.withLock { $0 } == 3 && offline.count == 3)
    }
}
