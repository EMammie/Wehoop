import Domain
import Foundation
import Observation

/// Follows one game for the game screen. The live stream ends normally when the game is
/// final (the last update carries the final snapshot); an error (the first snapshot failed,
/// the channel was lost for good) is retried with backoff while the screen is open, and the
/// last state stays on screen meanwhile.
@Observable
public final class GameViewModel {
    public enum State: Equatable {
        case loading
        case loaded(GameContent)
        /// Nothing could be shown yet; `retrying` is true while another attempt is scheduled.
        case failed(message: String, retrying: Bool)
    }

    public let gameId: Game.ID
    public private(set) var state: State = .loading
    /// True between a failure and the next update while content is on screen.
    public private(set) var isReconnecting = false

    private let dependencies: GameDependencies
    private let retryDelays: [Duration]
    private let sleep: @Sendable (Duration) async throws -> Void
    private var schedule: Game?
    private var live: LiveGame?

    public init(
        gameId: Game.ID,
        dependencies: GameDependencies,
        retryDelays: [Duration] = [.seconds(1), .seconds(2), .seconds(5), .seconds(10), .seconds(30)],
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.gameId = gameId
        self.dependencies = dependencies
        self.retryDelays = retryDelays.isEmpty ? [.seconds(5)] : retryDelays
        self.sleep = sleep
    }

    /// Runs while the screen is visible (`.task`): loads the schedule row and follows the game
    /// until it is final or the task is cancelled.
    public func run() async {
        async let header: Void = loadSchedule()
        await follow()
        await header
    }

    private func loadSchedule() async {
        guard let game = try? await dependencies.schedule.game(id: gameId) else { return }
        schedule = game
        publish()
    }

    private func follow() async {
        var failures = 0
        while !Task.isCancelled {
            do {
                for try await update in dependencies.liveGames.updates(gameId: gameId) {
                    failures = 0
                    isReconnecting = false
                    live = update.game
                    publish()
                }
                return
            } catch is CancellationError {
                return
            } catch {
                let delay = retryDelays[min(failures, retryDelays.count - 1)]
                failures += 1
                if live == nil {
                    state = .failed(message: String(localized: "Couldn't load this game."), retrying: true)
                } else {
                    isReconnecting = true
                }
                do { try await sleep(delay) } catch { return }
            }
        }
    }

    private func publish() {
        guard let live else { return }
        state = .loaded(GameContent(schedule: schedule, live: live))
    }
}
