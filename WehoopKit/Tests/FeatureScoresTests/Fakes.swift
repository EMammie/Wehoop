import Domain
import Foundation
import Observation
import Synchronization
import Testing
@testable import FeatureScores

// MARK: Fakes

struct StubLeagues: LeagueRepository {
    let result: Result<[League], URLError>
    func leagues() async throws -> [League] { try result.get() }
}

/// A schedule whose games the test sets, recording every read.
final class StubSchedule: ScheduleRepository {
    struct Read: Equatable {
        let league: League.Code
        let from: Date
        let to: Date
        let latest: Bool
    }

    private struct State {
        var games: [League.Code: [Game]] = [:]
        var reads: [Read] = []
        var failing = false
    }

    private let state = Mutex(State())

    var reads: [Read] { state.withLock { $0.reads } }
    var latestReads: Int { reads.filter(\.latest).count }

    func set(_ games: [Game], for league: League.Code) { state.withLock { $0.games[league] = games } }
    func fail(_ failing: Bool) { state.withLock { $0.failing = failing } }

    private func read(_ league: League.Code, _ from: Date, _ to: Date, latest: Bool) throws -> [Game] {
        try state.withLock {
            $0.reads.append(Read(league: league, from: from, to: to, latest: latest))
            if $0.failing { throw URLError(.notConnectedToInternet) }
            return ($0.games[league] ?? []).filter { $0.scheduledAt >= from && $0.scheduledAt < to }
        }
    }

    func games(league: League.Code, from: Date, to: Date) async throws -> [Game] {
        try read(league, from, to, latest: false)
    }

    func latestGames(league: League.Code, from: Date, to: Date) async throws -> [Game] {
        try read(league, from, to, latest: true)
    }

    func game(id: Game.ID) async throws -> Game? { nil }
}

/// A scoreboard the test drives: each `scores` call is one subscription, whose end
/// (cancelled consumer or finished stream) is recorded.
final class ScriptedScores: LiveScoresSource {
    private struct State {
        var leagues: [League.Code] = []
        var current: AsyncStream<LiveScoresEvent>.Continuation?
        var terminated: Set<Int> = []
    }

    private let state = Mutex(State())

    var subscriptions: [League.Code] { state.withLock { $0.leagues } }
    /// Indexes (into `subscriptions`) of the streams that have ended.
    var terminated: Set<Int> { state.withLock { $0.terminated } }
    /// Subscriptions whose stream is still open.
    var open: Int { state.withLock { $0.leagues.count - $0.terminated.count } }

    func scores(league: League.Code) -> AsyncStream<LiveScoresEvent> {
        let (stream, continuation) = AsyncStream.makeStream(of: LiveScoresEvent.self)
        state.withLock {
            let index = $0.leagues.count
            $0.leagues.append(league)
            $0.current = continuation
            continuation.onTermination = { [weak self] _ in
                _ = self?.state.withLock { $0.terminated.insert(index) }
            }
        }
        return stream
    }

    func send(_ event: LiveScoresEvent) { state.withLock { $0.current }?.yield(event) }
    func end() { state.withLock { $0.current }?.finish() }
}

/// Runs `action` the way `.task(id:)` does: started at once, cancelled and started again
/// whenever `key` changes, cancelled by `cancel()`.
@MainActor
final class KeyedTask<Key: Hashable> {
    private let key: () -> Key
    private let action: () async -> Void
    private var current: Key
    private var task: Task<Void, Never>?
    private(set) var starts = 0
    private var stopped = false

    init(key: @escaping () -> Key, action: @escaping () async -> Void) {
        self.key = key
        self.action = action
        current = key()
        start()
        observe()
    }

    private func start() {
        starts += 1
        task = Task { await action() }
    }

    private func observe() {
        withObservationTracking { _ = key() } onChange: { [weak self] in
            Task { @MainActor in self?.keyChanged() }
        }
    }

    private func keyChanged() {
        guard !stopped else { return }
        let new = key()
        if new != current {
            task?.cancel()
            current = new
            start()
        }
        observe()
    }

    func cancel() async {
        stopped = true
        task?.cancel()
        await task?.value
    }
}

/// Sleeps that wait until the test releases them (the periodic re-read).
final class Gate: Sendable {
    private let waiters = Mutex<[UUID: CheckedContinuation<Void, Never>]>([:])

    var sleeping: Int { waiters.withLock { $0.count } }

    func wait() async throws {
        let id = UUID()
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in waiters.withLock { $0[id] = continuation } }
        } onCancel: {
            waiters.withLock { $0.removeValue(forKey: id) }?.resume()
        }
        try Task.checkCancellation()
    }

    func release() {
        let all = waiters.withLock { waiters in defer { waiters = [:] }; return waiters }
        all.values.forEach { $0.resume() }
    }
}

/// Polls `condition` on the main actor until it holds or ~2 s pass.
@MainActor
func eventually(_ condition: () -> Bool) async -> Bool {
    for _ in 0..<2000 {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(1))
    }
    return false
}

// MARK: Samples

nonisolated enum Sample {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// 2026-11-11 18:00 UTC.
    static let now = Date(timeIntervalSince1970: 1_793_469_600)
    static let today = calendar.startOfDay(for: now)

    static let leagues = [
        League(code: League.Code("aaa"), name: "League A", shortName: "LA", colors: nil),
        League(code: League.Code("bbb"), name: "League B", shortName: "LB", colors: nil),
    ]

    static func game(
        _ id: String, league: League.Code = leagues[0].code, at hour: Double = 19, status: GameStatus = .scheduled,
        score: Score = Score(home: 0, away: 0), period: GamePeriod? = nil, seq: Int = 0, observedAt: Date? = nil,
        coverage: Coverage = .full, replay: ReplayKind? = nil, clock: Double? = nil, elamTarget: Int? = nil
    ) -> Game {
        Game(
            id: Game.ID(id), league: league, scheduledAt: today.addingTimeInterval(hour * 3600), status: status,
            coverage: coverage,
            home: Game.Side(teamId: nil, name: "Home \(id)", market: nil, alias: nil),
            away: Game.Side(teamId: nil, name: "Away \(id)", market: nil, alias: nil),
            score: score, period: period, elamTargetScore: elamTarget,
            clock: GameClock(remaining: clock, running: nil, asOf: nil), title: nil, tournamentName: nil,
            seasonYear: 2026, lastSeq: seq, replay: replay, observedAt: observedAt
        )
    }

    static func update(
        _ id: String, score: Score, status: GameStatus = .inProgress, seq: Int, observedAt: Date?,
        period: GamePeriod? = GamePeriod(number: 2, kind: .quarter, sequence: 2)
    ) -> ScoreUpdate {
        ScoreUpdate(
            gameId: Game.ID(id), score: score, status: status, period: period, clockRemaining: 252,
            latestSeq: seq, observedAt: observedAt, replay: nil
        )
    }
}
