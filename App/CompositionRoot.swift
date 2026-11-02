import Domain
import FeatureGame
import Foundation
import OSLog
import SwiftUI
import WehoopData

/// Builds the app's dependency graph and hands each feature its `Dependencies`: the
/// WehoopData implementations (live) or the recorded golden games (fixtures), always behind
/// Domain's protocols. The app never holds a provider key; it talks only to wehoop-api and
/// Supabase, configured per service in `Config/*.xcconfig`.
@MainActor
final class CompositionRoot {
    /// Where feature data comes from.
    enum DataMode: Equatable {
        /// wehoop-api and Supabase.
        case live
        /// Deterministic fixtures, for previews, UI tests and demos.
        case fixtures
    }

    /// What backs the features.
    enum Backend {
        case live(LiveBackend)
        case fixtures(FixtureBackend)
        /// Live mode without a usable configuration: the screens say so instead of crashing.
        case unconfigured(String)
    }

    /// Launch argument that switches the app to fixture data.
    static let fixturesArgument = "-WehoopFixtures"
    /// Launch argument followed by a `wehoop://` link to open at launch (UI tests, recordings;
    /// `simctl openurl` asks for confirmation the first time).
    static let openURLArgument = "-WehoopOpenURL"

    let dataMode: DataMode
    let tabs: [AppTab] = AppTab.allCases
    /// The link given with `-WehoopOpenURL`, if any.
    let launchURL: URL?
    let backend: Backend
    private let log = Logger(subsystem: "com.ChallengerApp.Wehoop", category: "composition")

    init(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) {
        dataMode = arguments.contains(Self.fixturesArgument) ? .fixtures : .live
        launchURL = arguments.firstIndex(of: Self.openURLArgument)
            .flatMap { arguments.indices.contains($0 + 1) ? URL(string: arguments[$0 + 1]) : nil }
        switch dataMode {
        case .fixtures:
            backend = .fixtures(FixtureBackend())
        case .live:
            do {
                backend = .live(LiveBackend(configuration: try BackendConfiguration.from(infoDictionary: infoDictionary)))
            } catch {
                backend = .unconfigured(Self.describe(error))
            }
        }
    }

    private static func describe(_ error: any Error) -> String {
        switch error as? BackendConfiguration.Problem {
        case .missing(let name): "\(name) is not set. Add it to Config/*.local.xcconfig."
        case .invalidURL(let name): "\(name) is not an http(s) URL."
        case nil: String(describing: error)
        }
    }

    /// The game screen's dependencies; nil when the app is not configured.
    var gameDependencies: GameDependencies? {
        switch backend {
        case .live(let live): GameDependencies(liveGames: live.liveGames, schedule: live.schedule)
        case .fixtures(let fixtures): GameDependencies(liveGames: fixtures.liveGames, schedule: fixtures.schedule)
        case .unconfigured: nil
        }
    }

    /// The screen for a pushed route.
    @ViewBuilder
    func destination(for route: AppRoute) -> some View {
        switch route {
        case .game(let id):
            if let dependencies = gameDependencies {
                GameScreen(gameId: id, dependencies: dependencies)
            } else {
                NotConfiguredView(reason: unconfiguredReason)
            }
        }
    }

    var unconfiguredReason: String {
        if case .unconfigured(let reason) = backend { reason } else { "" }
    }

    /// Foreground or a network change: every followed game catches up from `/changes`.
    func catchUp() async {
        let failures: [String: String] = switch backend {
        case .live(let live): await live.catchUp()
        case .fixtures(let fixtures): await fixtures.liveGames.catchUpAll()
        case .unconfigured: [:]
        }
        for (game, error) in failures.sorted(by: { $0.key < $1.key }) {
            log.error("catch-up failed for game \(game, privacy: .public): \(error, privacy: .public)")
        }
    }
}

/// Shown where live data would be when the build has no backend configuration.
struct NotConfiguredView: View {
    let reason: String

    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "Not configured"), systemImage: "gearshape.2")
        } description: {
            Text(reason)
        }
    }
}
