import Domain
import Foundation
import Observation

/// The Scores tab: the leagues to switch between, the days of the strip, and the selected
/// league's games on the selected day, kept current by the league's scoreboard channel.
///
/// Two tasks run while the screen is visible, each keyed so that only what changed restarts:
/// - `follow()`, from `.task(id: subscriptionKey)` (league and generation): loads the leagues
///   once (the first is selected), then subscribes to the league's scoreboard. Every join
///   (the first included) re-reads the selected day past the cache, since the channel never
///   replays what it sent while away; each update is applied to its game when the game is in
///   the list and the update is newer (`Game.applying`); a channel lost for good is
///   subscribed again with backoff. While any game is live the day is also re-read every
///   `liveRefreshInterval`: the backend's sender is best-effort (a failed publish is not
///   resent), so a game's last change, often its final status, could otherwise stay
///   missing until the next join.
/// - `load()`, from `.task(id: readKey)` (league, day and generation): reads the day (a
///   cached copy is fine for a first paint). A day tap therefore re-reads only; it never
///   leaves and rejoins the league's channel.
/// A retry or a return to the foreground bumps the generation: both restart, the channel is
/// rejoined and the day re-read, and the games on screen stay meanwhile.
@Observable
public final class ScoresViewModel {
    public enum State: Equatable {
        case loading
        case loaded(ScoresContent)
        /// The league has no games on the day.
        case empty
        case failed(message: String)
    }

    /// What `follow()` follows: a new value restarts it.
    public struct SubscriptionKey: Hashable {
        public let league: League.Code?
        let generation: Int
    }

    /// What `load()` reads: a new value restarts it.
    public struct ReadKey: Hashable {
        public let league: League.Code?
        public let day: Date
        let generation: Int
    }

    public private(set) var leagues: [League] = []
    public private(set) var selectedLeague: League.Code?
    public private(set) var selectedDay: Date
    public private(set) var today: Date
    /// The days of the strip, `today` in the middle.
    public private(set) var days: [Date]
    public private(set) var state: State = .loading

    public var subscriptionKey: SubscriptionKey { SubscriptionKey(league: selectedLeague, generation: generation) }
    public var readKey: ReadKey { ReadKey(league: selectedLeague, day: selectedDay, generation: generation) }
    public var calendar: Calendar { dependencies.calendar }

    private struct Shown: Equatable {
        let league: League.Code
        let day: Date
    }

    private let dependencies: ScoresDependencies
    private let daysAround: Int
    private let retryDelays: [Duration]
    private let stableAfter: Duration
    private let liveRefreshInterval: Duration?
    private let sleep: @Sendable (Duration) async throws -> Void
    private var generation = 0
    /// The shown day's games as last read and updated.
    private var games: [Game] = []
    /// The league and day `games` belong to.
    private var shown: Shown?

    /// - Parameters:
    ///   - daysAround: days before and after today in the strip.
    ///   - stableAfter: a subscription that lasted this long resets the backoff when it ends.
    ///   - liveRefreshInterval: the re-read while a game is live; nil turns it off.
    public init(
        dependencies: ScoresDependencies,
        daysAround: Int = 7,
        retryDelays: [Duration] = [.seconds(1), .seconds(2), .seconds(5), .seconds(10), .seconds(30)],
        stableAfter: Duration = .seconds(30),
        liveRefreshInterval: Duration? = .seconds(60),
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.dependencies = dependencies
        self.daysAround = daysAround
        self.retryDelays = retryDelays.isEmpty ? [.seconds(5)] : retryDelays
        self.stableAfter = stableAfter
        self.liveRefreshInterval = liveRefreshInterval
        self.sleep = sleep
        let today = dependencies.calendar.startOfDay(for: dependencies.now())
        self.today = today
        days = Self.days(around: today, count: daysAround, calendar: dependencies.calendar)
        selectedDay = today
    }

    private static func days(around today: Date, count: Int, calendar: Calendar) -> [Date] {
        (-count...count).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }

    // MARK: Selection

    public func select(league: League.Code) {
        guard league != selectedLeague, leagues.contains(where: { $0.code == league }) else { return }
        selectedLeague = league
    }

    public func select(day: Date) {
        let day = calendar.startOfDay(for: day)
        guard day != selectedDay else { return }
        selectedDay = day
    }

    /// Back in the foreground: the day may have changed; read the day again and rejoin the channel.
    public func returnedToForeground() {
        dayMayHaveChanged()
        generation += 1
    }

    /// The calendar day or the clock changed (`NSCalendarDayChanged`, a significant time
    /// change): the strip moves to the new today, and so does a selection that was on the
    /// old one; a picked day the strip no longer shows is clamped into it.
    public func dayMayHaveChanged() {
        let newToday = calendar.startOfDay(for: dependencies.now())
        guard newToday != today else { return }
        if selectedDay == today { selectedDay = newToday }
        today = newToday
        days = Self.days(around: newToday, count: daysAround, calendar: calendar)
        // A picked day the strip no longer shows moves to its nearest end.
        if let first = days.first, let last = days.last {
            selectedDay = min(max(selectedDay, first), last)
        }
    }

    /// After a failure: start over.
    public func retry() { generation += 1 }

    public var selectedLeagueName: String? {
        leagues.first { $0.code == selectedLeague }?.shortName
    }

    // MARK: Running

    /// Runs while the screen is visible, for the current `subscriptionKey`.
    public func follow() async {
        if leagues.isEmpty {
            await loadLeagues()
            return
        }
        guard let league = selectedLeague else { return }
        let key = subscriptionKey
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.subscribe(key, league: league) }
            if let interval = liveRefreshInterval {
                group.addTask { await self.refreshWhileLive(key, league: league, every: interval) }
            }
        }
    }

    /// Runs while the screen is visible, for the current `readKey`: the selected day's games.
    public func load() async {
        guard let league = selectedLeague else { return }
        let day = selectedDay
        // A new league or day starts empty; a foreground return or retry keeps what is shown.
        if shown != Shown(league: league, day: day) {
            shown = Shown(league: league, day: day)
            games = []
            state = .loading
        }
        await read(league: league, day: day, latest: false)
    }

    /// Pull to refresh: the day, past the cache.
    public func refresh() async {
        guard let league = selectedLeague else { return }
        await read(league: league, day: selectedDay, latest: true)
    }

    /// Selecting the first league changes both keys, which starts the runs for it.
    private func loadLeagues() async {
        do {
            let loaded = try await dependencies.leagues.leagues()
            guard !Task.isCancelled else { return }
            leagues = loaded
            if loaded.isEmpty {
                state = .failed(message: String(localized: "No leagues to show."))
            } else if selectedLeague == nil {
                selectedLeague = loaded[0].code
            }
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(message: String(localized: "Couldn't load the leagues."))
        }
    }

    private func subscribe(_ key: SubscriptionKey, league: League.Code) async {
        var failures = 0
        while !Task.isCancelled {
            let started = ContinuousClock.now
            for await event in dependencies.liveScores.scores(league: league) {
                guard key == subscriptionKey else { return }
                switch event {
                case .subscribed:
                    await read(league: league, day: selectedDay, latest: true)
                case .updates(let updates):
                    failures = 0
                    apply(updates)
                }
            }
            guard !Task.isCancelled else { return }
            // A channel that stayed up a while starts the backoff over; one that keeps
            // joining and dropping does not.
            if ContinuousClock.now - started >= stableAfter { failures = 0 }
            let delay = retryDelays[min(failures, retryDelays.count - 1)]
            failures += 1
            do { try await sleep(delay) } catch { return }
        }
    }

    private func refreshWhileLive(_ key: SubscriptionKey, league: League.Code, every interval: Duration) async {
        while !Task.isCancelled {
            do { try await sleep(interval) } catch { return }
            guard !Task.isCancelled, key == subscriptionKey else { return }
            if games.contains(where: { $0.status.phase == .live }) {
                await read(league: league, day: selectedDay, latest: true)
            }
        }
    }

    // MARK: Reads and updates

    /// The day's games from the schedule, merged into the list: a row older than the
    /// update already applied to its game keeps the update (a read can race a delta). A
    /// read that comes back after the league or day changed is dropped.
    private func read(league: League.Code, day: Date, latest: Bool) async {
        let to = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(24 * 3600)
        do {
            let fetched = latest
                ? try await dependencies.schedule.latestGames(league: league, from: day, to: to)
                : try await dependencies.schedule.games(league: league, from: day, to: to)
            guard !Task.isCancelled, shown == Shown(league: league, day: day) else { return }
            let current = Dictionary(games.map { ($0.id, $0) }) { first, _ in first }
            games = fetched.map { row in
                if let onScreen = current[row.id], row.isOlder(than: onScreen) { onScreen } else { row }
            }
            publish()
        } catch {
            guard !Task.isCancelled, shown == Shown(league: league, day: day) else { return }
            // With games on screen a failed re-read keeps them; the next join or refresh tries again.
            if games.isEmpty { state = .failed(message: String(localized: "Couldn't load the games.")) }
        }
    }

    /// Applies scoreboard updates: an update for a game not in the list (another day, or
    /// not read yet) is ignored, and one not newer than its game's row changes nothing.
    func apply(_ updates: [ScoreUpdate]) {
        var changed = false
        for update in updates {
            guard let index = games.firstIndex(where: { $0.id == update.gameId }),
                  let updated = games[index].applying(update) else { continue }
            games[index] = updated
            changed = true
        }
        if changed { publish() }
    }

    private func publish() {
        let content = ScoresContent(games: games)
        state = content.isEmpty ? .empty : .loaded(content)
    }
}
