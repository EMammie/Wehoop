import Domain
import Foundation
import Synchronization
import Testing
@testable import FeatureScores

// MARK: View model

@MainActor
struct ScoresViewModelTests {
    let schedule = StubSchedule()
    let scores = ScriptedScores()

    private func model(
        leagues: Result<[League], URLError> = .success(Sample.leagues), liveRefresh: Duration? = nil,
        sleep: @escaping @Sendable (Duration) async throws -> Void = { _ in await Task.yield() }
    ) -> ScoresViewModel {
        ScoresViewModel(
            dependencies: ScoresDependencies(
                leagues: StubLeagues(result: leagues), schedule: schedule, liveScores: scores,
                calendar: Sample.calendar, now: { Sample.now }
            ),
            daysAround: 3, retryDelays: [.zero], liveRefreshInterval: liveRefresh, sleep: sleep
        )
    }

    /// Runs the model as `.task(id: runKey)` would: the first run loads the leagues, which selects one.
    private func start(_ model: ScoresViewModel) async -> Task<Void, Never> {
        await model.run()
        return Task { await model.run() }
    }

    private func cards(_ model: ScoresViewModel) -> [ScoreCard] {
        if case .loaded(let content) = model.state { content.cards } else { [] }
    }

    private func sections(_ model: ScoresViewModel) -> [ScoresContent.Kind] {
        if case .loaded(let content) = model.state { content.sections.map(\.kind) } else { [] }
    }

    @Test("The strip is the days around today with today selected; the first league from the data is selected")
    func initialSelection() async {
        let model = model()
        #expect(model.days.count == 7 && model.days[3] == Sample.today)
        #expect(model.selectedDay == Sample.today && model.today == Sample.today)
        #expect(model.selectedLeague == nil)
        await model.run()
        #expect(model.leagues == Sample.leagues)
        #expect(model.selectedLeague == Sample.leagues[0].code && model.selectedLeagueName == "LA")
    }

    @Test("A run reads the selected league's day, subscribes its scoreboard, and every join re-reads past the cache")
    func readsSubscribesAndRereadsOnJoin() async {
        schedule.set([Sample.game("g1")], for: Sample.leagues[0].code)
        let model = model()
        let task = await start(model)
        #expect(await eventually { cards(model).map(\.id) == [Game.ID("g1")] && scores.subscriptions.count == 1 })
        let day = StubSchedule.Read(
            league: Sample.leagues[0].code, from: Sample.today, to: Sample.today.addingTimeInterval(86_400), latest: false
        )
        #expect(schedule.reads == [day])

        schedule.set([Sample.game("g1"), Sample.game("g2", at: 20)], for: Sample.leagues[0].code)
        scores.send(.subscribed)
        #expect(await eventually { cards(model).count == 2 })
        scores.send(.subscribed)
        #expect(await eventually { schedule.latestReads == 2 })
        #expect(scores.subscriptions == [Sample.leagues[0].code])
        task.cancel()
        await task.value
    }

    @Test("Selecting another league or day changes the run key; the run follows that league and day")
    func selection() async {
        let other = Sample.leagues[1].code
        let tomorrow = Sample.today.addingTimeInterval(86_400)
        schedule.set([Sample.game("b1", league: other, at: 24 + 18)], for: other)
        let model = model()
        await model.run()
        let before = model.runKey
        model.select(league: other)
        model.select(day: tomorrow.addingTimeInterval(3600))
        model.select(league: League.Code("not-listed"))
        #expect(model.runKey != before && model.selectedLeague == other && model.selectedDay == tomorrow)
        let task = Task { await model.run() }
        #expect(await eventually { cards(model).map(\.id) == [Game.ID("b1")] })
        #expect(schedule.reads.first == .init(league: other, from: tomorrow, to: tomorrow.addingTimeInterval(86_400), latest: false))
        #expect(scores.subscriptions == [other])
        task.cancel()
        await task.value
    }

    @Test("Sections: live, then upcoming, then final, each by tip-off; an unknown status gets its own section")
    func sectionsSplitAndOrder() {
        let content = ScoresContent(games: [
            Sample.game("final-late", at: 21, status: .closed),
            Sample.game("up-late", at: 22),
            Sample.game("odd", status: .unknown("suspended")),
            Sample.game("live-b", at: 18, status: .halftime),
            Sample.game("final-early", at: 12, status: .complete),
            Sample.game("live-a", at: 18, status: .inProgress),
            Sample.game("up-early", at: 20, status: .timeTBD),
            Sample.game("off", at: 13, status: .postponed),
        ])
        #expect(content.sections.map(\.kind) == [.live, .upcoming, .final, .other])
        #expect(content.sections.map { $0.cards.map(\.id.rawValue) } == [
            ["live-a", "live-b"], ["up-early", "up-late"], ["final-early", "off", "final-late"], ["odd"],
        ])
        #expect(content.sections.map(\.kind.title) == ["Live", "Upcoming", "Final", "Other"])
        #expect(ScoresContent(games: []).isEmpty)
    }

    @Test("A day without games is empty, not loading or failed")
    func emptyDay() async {
        let model = model()
        let task = await start(model)
        #expect(await eventually { model.state == .empty })
        task.cancel()
        await task.value
    }

    @Test("Updates apply to games in the list; foreign, stale and repeated ones change nothing; a game moves to Live")
    func deltaApplication() async {
        let t0 = Sample.now
        schedule.set([
            Sample.game("g1", status: .scheduled, seq: 0, observedAt: t0),
            Sample.game("g2", at: 20, status: .inProgress, score: Score(home: 10, away: 9), seq: 40, observedAt: t0),
        ], for: Sample.leagues[0].code)
        let model = model()
        let task = await start(model)
        #expect(await eventually { sections(model) == [.live, .upcoming] })

        scores.send(.updates([
            Sample.update("g1", score: Score(home: 2, away: 0), seq: 1, observedAt: t0 + 5),
            Sample.update("elsewhere", score: Score(home: 50, away: 50), seq: 99, observedAt: t0 + 5),
        ]))
        #expect(await eventually { sections(model) == [.live] })
        #expect(cards(model).map(\.id.rawValue) == ["g1", "g2"])
        #expect(cards(model)[0].game.score == Score(home: 2, away: 0) && cards(model)[0].statusText == "Q2 4:12")

        // Older than the row (g2 observed at t0), then repeated (g1 at t0 + 5): nothing changes.
        scores.send(.updates([Sample.update("g2", score: Score(home: 0, away: 0), seq: 41, observedAt: t0 - 5)]))
        scores.send(.updates([Sample.update("g1", score: Score(home: 9, away: 9), seq: 1, observedAt: t0 + 5)]))
        scores.send(.updates([Sample.update("g2", score: Score(home: 12, away: 9), seq: 42, observedAt: t0 + 6)]))
        #expect(await eventually { cards(model).last?.game.score == Score(home: 12, away: 9) })
        #expect(cards(model)[0].game.score == Score(home: 2, away: 0))

        scores.send(.updates([Sample.update("g2", score: Score(home: 80, away: 70), status: .closed, seq: 90, observedAt: t0 + 7)]))
        #expect(await eventually { sections(model) == [.live, .final] })
        task.cancel()
        await task.value
    }

    @Test("A re-read that is older than an update already applied keeps the update")
    func rereadRacesADelta() async {
        let t0 = Sample.now
        schedule.set([Sample.game("g1", status: .inProgress, score: Score(home: 4, away: 2), seq: 10, observedAt: t0)],
                     for: Sample.leagues[0].code)
        let model = model()
        let task = await start(model)
        #expect(await eventually { cards(model).count == 1 && scores.subscriptions.count == 1 })
        scores.send(.updates([Sample.update("g1", score: Score(home: 6, away: 2), seq: 11, observedAt: t0 + 5)]))
        #expect(await eventually { cards(model).first?.game.score == Score(home: 6, away: 2) })
        scores.send(.subscribed)   // the schedule still serves the t0 row
        #expect(await eventually { schedule.latestReads == 1 })
        #expect(cards(model).first?.game.score == Score(home: 6, away: 2))
        // A newer row wins over the update.
        schedule.set([Sample.game("g1", status: .inProgress, score: Score(home: 8, away: 2), seq: 12, observedAt: t0 + 10)],
                     for: Sample.leagues[0].code)
        scores.send(.subscribed)
        #expect(await eventually { cards(model).first?.game.score == Score(home: 8, away: 2) })
        task.cancel()
        await task.value
    }

    @Test("A channel lost for good is subscribed again after a backoff, and its join re-reads the day")
    func resubscribes() async {
        schedule.set([Sample.game("g1")], for: Sample.leagues[0].code)
        let sleeps = Mutex<[Duration]>([])
        let model = model(sleep: { duration in sleeps.withLock { $0.append(duration) } })
        let task = await start(model)
        #expect(await eventually { scores.subscriptions.count == 1 })
        scores.end()
        #expect(await eventually { scores.subscriptions.count == 2 })
        #expect(sleeps.withLock { $0 } == [.zero])
        scores.send(.subscribed)
        #expect(await eventually { schedule.latestReads == 1 })
        task.cancel()
        await task.value
    }

    @Test("While a game is live the day is re-read on each interval; with none live it is not")
    func periodicRereadWhileLive() async {
        let gate = Gate()
        schedule.set([Sample.game("g1", status: .scheduled)], for: Sample.leagues[0].code)
        let model = model(liveRefresh: .seconds(60), sleep: { _ in try await gate.wait() })
        let task = await start(model)
        #expect(await eventually { cards(model).count == 1 && gate.sleeping == 1 })
        gate.release()
        #expect(await eventually { gate.sleeping == 1 })
        #expect(schedule.latestReads == 0, "nothing live: no re-read")

        scores.send(.updates([Sample.update("g1", score: Score(home: 2, away: 0), seq: 1, observedAt: Sample.now)]))
        #expect(await eventually { model.state != .loading && cards(model).first?.isLive == true })
        gate.release()
        #expect(await eventually { schedule.latestReads == 1 })
        task.cancel()
        await task.value
    }

    @Test("A failed first read shows the failure; a retry starts over; a failed re-read keeps the games")
    func failures() async {
        schedule.fail(true)
        let model = model()
        let task = await start(model)
        #expect(await eventually { model.state == .failed(message: "Couldn't load the games.") })
        task.cancel()
        await task.value

        schedule.set([Sample.game("g1")], for: Sample.leagues[0].code)
        schedule.fail(false)
        let key = model.runKey
        model.retry()
        #expect(model.runKey != key)
        let retried = Task { await model.run() }
        #expect(await eventually { cards(model).count == 1 })
        schedule.fail(true)
        scores.send(.subscribed)
        #expect(await eventually { schedule.latestReads == 1 })
        #expect(cards(model).count == 1)
        retried.cancel()
        await retried.value
    }

    @Test("Leagues that fail to load show the failure and select nothing")
    func leaguesFail() async {
        let model = model(leagues: .failure(URLError(.timedOut)))
        await model.run()
        #expect(model.state == .failed(message: "Couldn't load the leagues."))
        #expect(model.selectedLeague == nil)
    }

    @Test("Back in the foreground the run restarts: the shown games stay, the channel is rejoined and the day re-read")
    func foreground() async {
        schedule.set([Sample.game("g1")], for: Sample.leagues[0].code)
        let model = model()
        let first = await start(model)
        #expect(await eventually { cards(model).count == 1 && scores.subscriptions.count == 1 })
        first.cancel()
        await first.value
        let key = model.runKey
        model.returnedToForeground()
        #expect(model.runKey != key)
        schedule.fail(true)   // the first read of the new run fails: what is shown must stay
        let second = Task { await model.run() }
        #expect(await eventually { scores.subscriptions.count == 2 })
        #expect(cards(model).count == 1, "the shown games stay; no loading or failed state")
        schedule.fail(false)
        scores.send(.subscribed)
        #expect(await eventually { schedule.latestReads == 1 })
        second.cancel()
        await second.value
    }
}
