import Domain
import Foundation
import Observation

/// The Scores tab: the leagues to switch between, the days of the strip, and the selected
/// league's games on the selected day, kept current by the league's scoreboard channel.
///
/// Data flow, while the screen is visible (`run()` from `.task(id: runKey)`):
/// 1. the leagues load once (the first is selected);
/// 2. the day's games are read from the schedule (a cached copy is fine for a first paint);
/// 3. the league's scoreboard is subscribed; every join (the first included) re-reads the
///    day past the cache, since the channel never replays what it sent while away;
/// 4. each update is applied to its game if the game is in the list and the update is
///    newer than the row (`Game.applying`); others are ignored;
/// 5. a channel lost for good is subscribed again with backoff (its join re-reads);
/// 6. while any game is live, the day is also re-read every `liveRefreshInterval`: the
///    channel is best-effort (a failed publish is not resent), so a game's last change,
///    often its final status, could otherwise stay missing until the next join.
/// Changing the league or day, a retry, or returning to the foreground changes `runKey`,
/// which cancels the run and starts a fresh one (a foreground return re-reads and rejoins).
@Observable
public final class ScoresViewModel {
    public enum State: Equatable {
        case loading
        case loaded(ScoresContent)
        /// The league has no games on the day.
        case empty
        case failed(message: String)
    }

    /// What the running task follows; a new value restarts it.
    public struct RunKey: Hashable {
        public let league: League.Code?
        public let day: Date
        let generation: Int
    }

    public private(set) var leagues: [League] = []
    public private(set) var selectedLeague: League.Code?
    public private(set) var selectedDay: Date
    public let today: Date
    /// The days of the strip, `today` in the middle.
    public let days: [Date]
    public private(set) var state: State = .loading

    public var runKey: RunKey { RunKey(league: selectedLeague, day: selectedDay, generation: generation) }

    private let dependencies: ScoresDependencies
    private let retryDelays: [Duration]
    private let liveRefreshInterval: Duration?
    private let sleep: @Sendable (Duration) async throws -> Void
    private var generation = 0
    /// The selected day's games as last read and updated.
    private var games: [Game] = []
    private struct Shown: Equatable {
        let league: League.Code
        let day: Date
    }
    /// The league and day `games` belong to.
    private var shownDay: Shown?

    /// - Parameters:
    ///   - daysAround: days before and after today in the strip.
    ///   - liveRefreshInterval: the re-read while a game is live; nil turns it off.
    public init(
        dependencies: ScoresDependencies,
        daysAround: Int = 7,
        retryDelays: [Duration] = [.seconds(1), .seconds(2), .seconds(5), .seconds(10), .seconds(30)],
        liveRefreshInterval: Duration? = .seconds(60),
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.dependencies = dependencies
        self.retryDelays = retryDelays.isEmpty ? [.seconds(5)] : retryDelays
        self.liveRefreshInterval = liveRefreshInterval
        self.sleep = sleep
        let calendar = dependencies.calendar
        let today = calendar.startOfDay(for: dependencies.now())
        self.today = today
        days = (-daysAround...daysAround).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        selectedDay = today
    }

    // MARK: Selection

    public func select(league: League.Code) {
        guard league != selectedLeague, leagues.contains(where: { $0.code == league }) else { return }
        selectedLeague = league
    }

    public func select(day: Date) {
        let day = dependencies.calendar.startOfDay(for: day)
        guard day != selectedDay else { return }
        selectedDay = day
    }

    /// Back in the foreground: read the day again and rejoin the channel.
    public func returnedToForeground() { generation += 1 }

    /// After a failure: start over.
    public func retry() { generation += 1 }

    public var selectedLeagueName: String? {
        leagues.first { $0.code == selectedLeague }?.shortName
    }

    // MARK: Running

    /// Runs while the screen is visible, for the current `runKey`.
    public func run() async {
        if leagues.isEmpty {
            await loadLeagues()
            return
        }
        guard let league = selectedLeague else { return }
        let key = runKey
        // A new league or day starts empty; a foreground return or retry keeps what is shown.
        if shownDay != Shown(league: league, day: key.day) {
            shownDay = Shown(league: league, day: key.day)
            games = []
            state = .loading
        }
        await read(key, league: league, latest: false)
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.follow(key, league: league) }
            if let interval = liveRefreshInterval {
                group.addTask { await self.refreshWhileLive(key, league: league, every: interval) }
            }
        }
    }

    /// Pull to refresh: the day, past the cache.
    public func refresh() async {
        guard let league = selectedLeague else { return }
        await read(runKey, league: league, latest: true)
    }

    /// Selecting the first league changes `runKey`, which starts the run for it.
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

    private func follow(_ key: RunKey, league: League.Code) async {
        var failures = 0
        while !Task.isCancelled {
            for await event in dependencies.liveScores.scores(league: league) {
                guard key == runKey else { return }
                failures = 0
                switch event {
                case .subscribed: await read(key, league: league, latest: true)
                case .updates(let updates): apply(updates)
                }
            }
            guard !Task.isCancelled else { return }
            let delay = retryDelays[min(failures, retryDelays.count - 1)]
            failures += 1
            do { try await sleep(delay) } catch { return }
        }
    }

    private func refreshWhileLive(_ key: RunKey, league: League.Code, every interval: Duration) async {
        while !Task.isCancelled {
            do { try await sleep(interval) } catch { return }
            guard !Task.isCancelled, key == runKey else { return }
            if games.contains(where: { $0.status.phase == .live }) {
                await read(key, league: league, latest: true)
            }
        }
    }

    // MARK: Reads and updates

    /// The day's games from the schedule, merged into the list: a row older than the
    /// update already applied to its game keeps the update (a read can race a delta).
    private func read(_ key: RunKey, league: League.Code, latest: Bool) async {
        let calendar = dependencies.calendar
        let from = key.day
        let to = calendar.date(byAdding: .day, value: 1, to: from) ?? from.addingTimeInterval(24 * 3600)
        do {
            let fetched = latest
                ? try await dependencies.schedule.latestGames(league: league, from: from, to: to)
                : try await dependencies.schedule.games(league: league, from: from, to: to)
            guard !Task.isCancelled, key == runKey else { return }
            let current = Dictionary(games.map { ($0.id, $0) }) { first, _ in first }
            games = fetched.map { row in
                if let shown = current[row.id], row.isOlder(than: shown) { shown } else { row }
            }
            publish()
        } catch {
            guard !Task.isCancelled, key == runKey else { return }
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
