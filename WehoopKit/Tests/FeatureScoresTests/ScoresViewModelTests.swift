import Domain
import Foundation
import Synchronization
import Testing
@testable import FeatureScores

/// The screen's two tasks, run as SwiftUI runs `.task(id:)`.
@MainActor
final class ScreenTasks {
    let follow: KeyedTask<ScoresViewModel.SubscriptionKey>
    let load: KeyedTask<ScoresViewModel.ReadKey>

    init(_ model: ScoresViewModel) {
        follow = KeyedTask(key: { model.subscriptionKey }, action: { await model.follow() })
        load = KeyedTask(key: { model.readKey }, action: { await model.load() })
    }

    func cancel() async {
        await follow.cancel()
        await load.cancel()
    }
}

/// A clock the test moves.
nonisolated final class TestClock: Sendable {
    private let date: Mutex<Date>
    init(_ date: Date) { self.date = Mutex(date) }
    var now: Date { date.withLock { $0 } }
    func advance(_ seconds: TimeInterval) { date.withLock { $0 += seconds } }
}

@MainActor
struct ScoresViewModelTests {
    let schedule = StubSchedule()
    let scores = ScriptedScores()
    let clock = TestClock(Sample.now)

    private func model(
        leagues: Result<[League], URLError> = .success(Sample.leagues), liveRefresh: Duration? = nil,
        retryDelays: [Duration] = [.zero],
        sleep: @escaping @Sendable (Duration) async throws -> Void = { _ in await Task.yield() }
    ) -> ScoresViewModel {
        let clock = clock
        return ScoresViewModel(
            dependencies: ScoresDependencies(
                leagues: StubLeagues(result: leagues), schedule: schedule, liveScores: scores,
                calendar: Sample.calendar, now: { clock.now }
            ),
            daysAround: 3, retryDelays: retryDelays, liveRefreshInterval: liveRefresh, sleep: sleep
        )
    }

    private func cards(_ model: ScoresViewModel) -> [ScoreCard] {
        if case .loaded(let content) = model.state { content.cards } else { [] }
    }

    private func sections(_ model: ScoresViewModel) -> [ScoresContent.Kind] {
        if case .loaded(let content) = model.state { content.sections.map(\.kind) } else { [] }
    }

    private func card(_ model: ScoresViewModel, _ id: String) -> ScoreCard? {
        cards(model).first { $0.id == Game.ID(id) }
    }

    @Test("The strip is the days around today with today selected; the first league from the data is selected")
    func initialSelection() async {
        let model = model()
        #expect(model.days.count == 7 && model.days[3] == Sample.today)
        #expect(model.selectedDay == Sample.today && model.today == Sample.today)
        #expect(model.selectedLeague == nil)
        let screen = ScreenTasks(model)
        #expect(await eventually { model.selectedLeague == Sample.leagues[0].code })
        #expect(model.leagues == Sample.leagues && model.selectedLeagueName == "LA")
        await screen.cancel()
    }

    @Test("The screen reads the league's day, subscribes its scoreboard, and every join re-reads past the cache")
    func readsSubscribesAndRereadsOnJoin() async {
        schedule.set([Sample.game("g1")], for: Sample.leagues[0].code)
        let model = model()
        let screen = ScreenTasks(model)
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
        await screen.cancel()
    }

    @Test("A day tap re-reads that day and keeps the league's subscription; a join then re-reads the new day")
    func dayChangeKeepsTheSubscription() async {
        let tomorrow = Sample.today.addingTimeInterval(86_400)
        schedule.set([Sample.game("g1"), Sample.game("t1", at: 24 + 18)], for: Sample.leagues[0].code)
        let model = model()
        let screen = ScreenTasks(model)
        #expect(await eventually { cards(model).map(\.id.rawValue) == ["g1"] && scores.subscriptions.count == 1 })
        model.select(day: tomorrow.addingTimeInterval(3600))
        #expect(model.selectedDay == tomorrow)
        #expect(await eventually { cards(model).map(\.id.rawValue) == ["t1"] })
        let read = StubSchedule.Read(
            league: Sample.leagues[0].code, from: tomorrow, to: tomorrow.addingTimeInterval(86_400), latest: false
        )
        #expect(schedule.reads.last == read)
        #expect(scores.subscriptions.count == 1 && scores.terminated.isEmpty, "a day tap never leaves the channel")
        scores.send(.subscribed)
        #expect(await eventually { schedule.reads.last?.latest == true })
        #expect(schedule.reads.last?.from == tomorrow)
        await screen.cancel()
    }

    @Test("Another league ends the previous subscription and subscribes the new one, which follows its day")
    func leagueChangeResubscribes() async {
        let other = Sample.leagues[1].code
        schedule.set([Sample.game("b1", league: other)], for: other)
        let model = model()
        let screen = ScreenTasks(model)
        #expect(await eventually { scores.subscriptions.count == 1 })
        model.select(league: other)
        model.select(league: League.Code("not-listed"))
        #expect(model.selectedLeague == other)
        #expect(await eventually { scores.subscriptions == [Sample.leagues[0].code, other] && scores.terminated == [0] })
        #expect(await eventually { cards(model).map(\.id.rawValue) == ["b1"] })
        #expect(schedule.reads.last?.league == other)
        await screen.cancel()
    }

    @Test("Back in the foreground the channel is rejoined (the old stream ends) and the day re-read; the games stay")
    func foreground() async {
        schedule.set([Sample.game("g1")], for: Sample.leagues[0].code)
        let model = model()
        let screen = ScreenTasks(model)
        #expect(await eventually { cards(model).count == 1 && scores.subscriptions.count == 1 })
        schedule.fail(true)   // the new run's first read fails: what is shown must stay
        model.returnedToForeground()
        #expect(await eventually { scores.subscriptions.count == 2 && scores.terminated == [0] })
        #expect(await eventually { schedule.reads.count == 2 })
        #expect(cards(model).count == 1, "the shown games stay; no loading or failed state")
        schedule.fail(false)
        scores.send(.subscribed)
        #expect(await eventually { schedule.latestReads == 1 })
        await screen.cancel()
        #expect(scores.open == 0, "cancelling the screen's task ends the subscription")
    }

    @Test("A new calendar day moves the strip, and a selection on the old today to the new one; another day stays")
    func dayChange() async {
        let model = model()
        clock.advance(10 * 3600)   // past midnight UTC
        let newToday = Sample.today.addingTimeInterval(86_400)
        model.dayMayHaveChanged()
        #expect(model.today == newToday && model.days[3] == newToday && model.selectedDay == newToday)

        let yesterdayOfNew = Sample.today
        model.select(day: yesterdayOfNew)
        clock.advance(86_400)
        model.returnedToForeground()
        #expect(model.today == newToday.addingTimeInterval(86_400) && model.days.count == 7)
        #expect(model.selectedDay == yesterdayOfNew, "a day the user picked is kept")
        let key = model.readKey
        model.dayMayHaveChanged()
        #expect(model.readKey == key, "the same day changes nothing")
    }

    @Test("A day without games is empty, not loading or failed")
    func emptyDay() async {
        let model = model()
        let screen = ScreenTasks(model)
        #expect(await eventually { model.state == .empty })
        await screen.cancel()
    }

    @Test("Updates apply to games in the list; foreign, stale and repeated ones change nothing; a game moves to Live")
    func deltaApplication() async {
        let t0 = Sample.now
        schedule.set([
            Sample.game("g1", status: .scheduled, seq: 0, observedAt: t0),
            Sample.game("g2", at: 20, status: .inProgress, score: Score(home: 10, away: 9), seq: 40, observedAt: t0),
        ], for: Sample.leagues[0].code)
        let model = model()
        let screen = ScreenTasks(model)
        #expect(await eventually { sections(model) == [.live, .upcoming] && scores.subscriptions.count == 1 })

        scores.send(.updates([
            Sample.update("g1", score: Score(home: 2, away: 0), seq: 1, observedAt: t0 + 5),
            Sample.update("elsewhere", score: Score(home: 50, away: 50), seq: 99, observedAt: t0 + 5),
        ]))
        #expect(await eventually { sections(model) == [.live] })
        #expect(cards(model).map(\.id.rawValue) == ["g1", "g2"])
        #expect(card(model, "g1")?.game.score == Score(home: 2, away: 0) && card(model, "g1")?.statusText == "Q2 4:12")

        // Older than g2's row (observed at t0), then a repeat of g1's update: neither changes anything.
        scores.send(.updates([Sample.update("g2", score: Score(home: 0, away: 0), seq: 41, observedAt: t0 - 5)]))
        scores.send(.updates([Sample.update("g1", score: Score(home: 9, away: 9), seq: 1, observedAt: t0 + 5)]))
        // A sentinel behind them: once it shows, the two before it have been handled.
        scores.send(.updates([Sample.update("g1", score: Score(home: 4, away: 0), seq: 2, observedAt: t0 + 6)]))
        #expect(await eventually { card(model, "g1")?.game.score == Score(home: 4, away: 0) })
        #expect(card(model, "g2")?.game.score == Score(home: 10, away: 9), "the stale update was ignored")

        scores.send(.updates([Sample.update("g2", score: Score(home: 12, away: 9), seq: 42, observedAt: t0 + 6)]))
        #expect(await eventually { card(model, "g2")?.game.score == Score(home: 12, away: 9) })
        scores.send(.updates([Sample.update("g2", score: Score(home: 80, away: 70), status: .closed, seq: 90, observedAt: t0 + 7)]))
        #expect(await eventually { sections(model) == [.live, .final] })
        await screen.cancel()
    }

    @Test("A re-read that is older than an update already applied keeps the update")
    func rereadRacesADelta() async {
        let t0 = Sample.now
        schedule.set([Sample.game("g1", status: .inProgress, score: Score(home: 4, away: 2), seq: 10, observedAt: t0)],
                     for: Sample.leagues[0].code)
        let model = model()
        let screen = ScreenTasks(model)
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
        await screen.cancel()
    }

    @Test("A channel lost for good is subscribed again with backoff; joins alone do not reset it, an update does")
    func resubscribesWithBackoff() async {
        schedule.set([Sample.game("g1")], for: Sample.leagues[0].code)
        let sleeps = Mutex<[Duration]>([])
        let model = model(retryDelays: [.seconds(1), .seconds(2), .seconds(5)]) { duration in
            sleeps.withLock { $0.append(duration) }
        }
        let screen = ScreenTasks(model)
        #expect(await eventually { scores.subscriptions.count == 1 })
        scores.send(.subscribed)
        scores.end()
        #expect(await eventually { scores.subscriptions.count == 2 })
        scores.send(.subscribed)
        scores.end()
        #expect(await eventually { scores.subscriptions.count == 3 })
        #expect(sleeps.withLock { $0 } == [.seconds(1), .seconds(2)], "a join that drops at once does not reset the backoff")
        scores.send(.updates([Sample.update("g1", score: Score(home: 2, away: 0), seq: 1, observedAt: Sample.now)]))
        #expect(await eventually { cards(model).first?.game.score == Score(home: 2, away: 0) })
        scores.end()
        #expect(await eventually { scores.subscriptions.count == 4 })
        #expect(sleeps.withLock { $0 } == [.seconds(1), .seconds(2), .seconds(1)])
        await screen.cancel()
    }

    @Test("While a game is live the day is re-read on each interval; with none live it is not")
    func periodicRereadWhileLive() async {
        let gate = Gate()
        schedule.set([Sample.game("g1", status: .scheduled)], for: Sample.leagues[0].code)
        let model = model(liveRefresh: .seconds(60), sleep: { _ in try await gate.wait() })
        let screen = ScreenTasks(model)
        #expect(await eventually { cards(model).count == 1 && gate.sleeping == 1 && scores.subscriptions.count == 1 })
        gate.release()
        #expect(await eventually { gate.sleeping == 1 })
        #expect(schedule.latestReads == 0, "nothing live: no re-read")

        scores.send(.updates([Sample.update("g1", score: Score(home: 2, away: 0), seq: 1, observedAt: Sample.now)]))
        #expect(await eventually { cards(model).first?.isLive == true })
        gate.release()
        #expect(await eventually { schedule.latestReads == 1 })
        await screen.cancel()
    }

    @Test("A failed first read shows the failure; a retry starts over; a failed re-read keeps the games")
    func failures() async {
        schedule.fail(true)
        let model = model()
        let screen = ScreenTasks(model)
        #expect(await eventually { model.state == .failed(message: "Couldn't load the games.") })

        schedule.set([Sample.game("g1")], for: Sample.leagues[0].code)
        schedule.fail(false)
        model.retry()
        #expect(await eventually { cards(model).count == 1 && scores.subscriptions.count == 2 })
        schedule.fail(true)
        scores.send(.subscribed)
        #expect(await eventually { schedule.latestReads == 1 })
        #expect(cards(model).count == 1)
        await screen.cancel()
    }

    @Test("Leagues that fail to load show the failure and select nothing")
    func leaguesFail() async {
        let model = model(leagues: .failure(URLError(.timedOut)))
        await model.follow()
        #expect(model.state == .failed(message: "Couldn't load the leagues."))
        #expect(model.selectedLeague == nil)
    }
}

struct ScoresContentTests {
    @Test("Sections: live, upcoming, final, not played, each by tip-off; an unknown status gets its own section")
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
            Sample.game("gone", at: 11, status: .cancelled),
        ])
        #expect(content.sections.map(\.kind) == [.live, .upcoming, .final, .notPlayed, .other])
        #expect(content.sections.map { $0.cards.map(\.id.rawValue) } == [
            ["live-a", "live-b"], ["up-early", "up-late"], ["final-early", "final-late"], ["gone", "off"], ["odd"],
        ])
        #expect(content.sections.map(\.kind.title) == ["Live", "Upcoming", "Final", "Not played", "Other"])
        #expect(ScoresContent(games: []).isEmpty)
    }
}
