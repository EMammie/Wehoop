import Domain
import Foundation
import Synchronization
import Testing
@testable import FeatureGame

/// A live source whose streams the test drives: each `updates` call takes the next script.
final class ScriptedSource: LiveGameSource {
    enum Step: Sendable { case update(LiveGameUpdate), fail, finish }
    private let scripts: Mutex<[[Step]]>
    let calls = Mutex(0)

    init(_ scripts: [[Step]]) { self.scripts = Mutex(scripts) }

    func updates(gameId: Game.ID) -> AsyncThrowingStream<LiveGameUpdate, any Error> {
        calls.withLock { $0 += 1 }
        let script = scripts.withLock { $0.isEmpty ? [] : $0.removeFirst() }
        return AsyncThrowingStream { continuation in
            for step in script {
                switch step {
                case .update(let update): continuation.yield(update)
                case .fail: continuation.finish(throwing: URLError(.networkConnectionLost)); return
                case .finish: continuation.finish(); return
                }
            }
            // A script without an end stays open, like a followed live game.
        }
    }
}

struct FixedSchedule: ScheduleRepository {
    let game: Game?
    func games(league: League.Code, from: Date, to: Date) async throws -> [Game] { game.map { [$0] } ?? [] }
    func game(id: Game.ID) async throws -> Game? { game }
}

enum Sample {
    static let id = Game.ID("g1")

    static func play(_ id: String, period: Int, clock: String, made: Bool, score: (Int, Int)) -> Play {
        Play(
            id: id, period: GamePeriod(number: period, kind: .quarter, sequence: period), clock: clock,
            kind: .shot(made: made, points: 2), side: .home, playerName: "A. Player",
            description: "shot \(id)", score: Score(home: score.0, away: score.1)
        )
    }

    static func live(
        status: GameStatus = .inProgress, coverage: Coverage = .full, plays: [Play] = [],
        score: Score = Score(home: 2, away: 0), period: GamePeriod? = GamePeriod(number: 1, kind: .quarter, sequence: 1),
        replay: ReplayKind? = nil
    ) -> LiveGame {
        LiveGame(
            id: id, league: League.Code("wnba"), status: status, coverage: coverage, score: score,
            period: period, elamTargetScore: nil,
            clock: GameClock(remaining: 300, running: true, asOf: Date(timeIntervalSince1970: 1_000)), seq: plays.count,
            replay: replay,
            detail: GameDetail(periods: [], plays: plays, teamLines: [], playerLines: [])
        )
    }

    static let schedule = Game(
        id: id, league: League.Code("wnba"), scheduledAt: Date(timeIntervalSince1970: 0), status: .inProgress,
        coverage: .full,
        home: Game.Side(teamId: nil, name: "Liberty", market: "New York", alias: "NY"),
        away: Game.Side(teamId: nil, name: "Aces", market: "Las Vegas", alias: "LV"),
        score: Score(home: 0, away: 0), period: nil, elamTargetScore: nil,
        clock: GameClock(remaining: nil, running: nil, asOf: nil), title: nil,
        tournamentName: nil, seasonYear: 2026, lastSeq: 0, replay: nil
    )
}

@MainActor
struct GameViewModelTests {
    private func model(_ source: ScriptedSource, schedule: Game? = Sample.schedule) -> GameViewModel {
        GameViewModel(
            gameId: Sample.id, dependencies: GameDependencies(liveGames: source, schedule: FixedSchedule(game: schedule)),
            retryDelays: [.zero], sleep: { _ in await Task.yield() }
        )
    }

    private func content(_ model: GameViewModel) -> GameContent? {
        if case .loaded(let content) = model.state { content } else { nil }
    }

    @Test("Each update replaces the content; the stream ending (the game is final) ends the run")
    func followsUntilFinal() async {
        let p1 = Sample.play("e1", period: 1, clock: "9:40", made: true, score: (2, 0))
        let source = ScriptedSource([[
            .update(.init(game: Sample.live(plays: [p1]), cause: .snapshot)),
            .update(.init(game: Sample.live(status: .closed, plays: [p1]), cause: .final)),
            .finish,
        ]])
        let model = model(source)
        await model.run()
        let content = content(model)
        #expect(content?.live.status == .closed)
        #expect(content?.statusText == "Final")
        #expect(content?.teamName(.home) == "Liberty" && content?.teamName(.away) == "Aces")
        #expect(source.calls.withLock { $0 } == 1)
    }

    @Test("A failure with content on screen keeps it, shows reconnecting, and resubscribes")
    func failureKeepsContentAndRetries() async {
        let p1 = Sample.play("e1", period: 1, clock: "9:40", made: true, score: (2, 0))
        let source = ScriptedSource([
            [.update(.init(game: Sample.live(plays: [p1]), cause: .snapshot)), .fail],
            [.update(.init(game: Sample.live(status: .closed, plays: [p1]), cause: .final)), .finish],
        ])
        let model = model(source)
        await model.run()
        #expect(source.calls.withLock { $0 } == 2)
        #expect(content(model)?.live.status == .closed)
        #expect(model.isReconnecting == false)
    }

    @Test("A failure before anything loaded shows the failed state while retrying")
    func failureBeforeContent() async {
        let source = ScriptedSource([[.fail], []])
        let model = model(source)
        let task = Task { await model.run() }
        try? await Task.sleep(for: .milliseconds(50))
        #expect(model.state == .failed(message: "Couldn't load this game.", retrying: true))
        task.cancel()
        await task.value
    }

    @Test("Without a schedule row the teams are Home and Away")
    func missingSchedule() async {
        let source = ScriptedSource([[.update(.init(game: Sample.live(), cause: .snapshot)), .finish]])
        let model = model(source, schedule: nil)
        await model.run()
        #expect(content(model)?.teamName(.home) == "Home")
        #expect(content(model)?.teamAbbreviation(.away) == "AWA")
    }
}

struct GameContentTests {
    @Test("Plays are newest first, grouped by period with the newest period on top, one row per play id")
    func playSections() {
        let plays = [
            Sample.play("e1", period: 1, clock: "9:40", made: true, score: (2, 0)),
            Sample.play("e2", period: 1, clock: "1:10", made: false, score: (2, 0)),
            Sample.play("e3", period: 2, clock: "9:55", made: true, score: (4, 0)),
        ]
        let content = GameContent(schedule: Sample.schedule, live: Sample.live(plays: plays))
        let sections = content.playSections
        #expect(sections.map(\.period.number) == [2, 1])
        #expect(sections.map { $0.plays.map(\.id) } == [["e3"], ["e2", "e1"]])
        let ids = sections.flatMap { $0.plays.map(\.id) }
        #expect(Set(ids).count == ids.count)
    }

    @Test("Score-only coverage says what it cannot show and has no play-by-play")
    func extendedCoverage() {
        let content = GameContent(schedule: Sample.schedule, live: Sample.live(coverage: .extendedBoxscore))
        #expect(content.hasPlays == false)
        #expect(content.coverageNote?.contains("Score-only") == true)
        #expect(GameContent(schedule: nil, live: Sample.live()).coverageNote == nil)
    }

    @Test("A replay is labelled with a badge and a note; a real game has neither")
    func replayLabel() {
        let real = GameContent(schedule: Sample.schedule, live: Sample.live())
        #expect(real.replayBadge == nil && real.replayNote == nil)
        let recorded = GameContent(schedule: Sample.schedule, live: Sample.live(replay: .recorded))
        #expect(recorded.replayBadge == "Replay")
        #expect(recorded.replayNote?.contains("not happening now") == true)
        let synthetic = GameContent(schedule: nil, live: Sample.live(replay: .synthetic))
        #expect(synthetic.replayBadge == "Simulated replay")
        #expect(synthetic.replayNote?.contains("never played") == true)
        let unknown = GameContent(schedule: nil, live: Sample.live(replay: .unknown("rerun")))
        #expect(unknown.replayBadge == "Replay")
        // The status line is unchanged: the badge says replay, the clock and period stay as served.
        #expect(recorded.statusText == real.statusText && recorded.isLive)
    }

    @Test("Status: period while live, halftime, unofficial before validation, Final/OT after overtime")
    func statusText() {
        let ot = GamePeriod(number: 1, kind: .overtime, sequence: 5)
        #expect(GameContent(schedule: nil, live: Sample.live()).statusText == "Q1")
        #expect(GameContent(schedule: nil, live: Sample.live(status: .halftime)).statusText == "Halftime")
        #expect(GameContent(schedule: nil, live: Sample.live(status: .complete)).statusText == "Final · unofficial")
        #expect(GameContent(schedule: nil, live: Sample.live(status: .closed, period: ot)).statusText == "Final/OT")
    }
}

struct GameFormatTests {
    @Test("Clock: M:SS rounded up from a minute, tenths below")
    func clock() {
        #expect(GameFormat.clock(600) == "10:00")
        #expect(GameFormat.clock(59.95) == "1:00")
        #expect(GameFormat.clock(59.9) == "59.9")
        #expect(GameFormat.clock(0) == "0.0")
    }

    @Test("Period labels and box cells; a missing number is a dash, never 0")
    func labels() {
        #expect(GameFormat.periodLabel(GamePeriod(number: 3, kind: .quarter, sequence: 3)) == "Q3")
        #expect(GameFormat.periodLabel(GamePeriod(number: 2, kind: .overtime, sequence: 6)) == "2OT")
        #expect(GameFormat.periodLabel(GamePeriod(number: 1, kind: .elam, sequence: 4)) == "Elam")
        #expect(GameFormat.count(nil) == "–" && GameFormat.count(0) == "0")
        #expect(GameFormat.madeAttempted(4, 9) == "4-9" && GameFormat.madeAttempted(nil, 9) == "–")
        #expect(GameFormat.plusMinus(5) == "+5" && GameFormat.plusMinus(-3) == "-3")
        #expect(GameFormat.minutes("32:41") == "32")
    }

    @Test("The clock counts down from asOf only while running; stopped or unknown freezes it")
    func clockCounting() {
        let asOf = Date(timeIntervalSince1970: 1_000)
        let running = GameClock(remaining: 300, running: true, asOf: asOf)
        #expect(running.remaining(at: asOf.addingTimeInterval(10)) == 290)
        #expect(GameClock(remaining: 300, running: nil, asOf: asOf).remaining(at: asOf.addingTimeInterval(10)) == 300)
        #expect(GameClock(remaining: 300, running: false, asOf: asOf).remaining(at: asOf.addingTimeInterval(10)) == 300)
        #expect(GameClock(remaining: nil, running: true, asOf: asOf).remaining(at: asOf) == nil)
    }
}
