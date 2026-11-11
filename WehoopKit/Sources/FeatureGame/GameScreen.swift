import DesignSystem
import Domain
import SwiftUI

/// The game screen. The app pushes it for `AppRoute.game(id)`.
public struct GameScreen: View {
    @State private var model: GameViewModel
    @State private var tab: Tab = .plays

    enum Tab: Hashable { case plays, box }

    public init(gameId: Game.ID, dependencies: GameDependencies) {
        _model = State(initialValue: GameViewModel(gameId: gameId, dependencies: dependencies))
    }

    init(model: GameViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        content
            .background(Color.wehoopBackground)
            .inlineNavigationTitle()
            .task { await model.run() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message, let retrying):
            ContentUnavailableView {
                Label(message, systemImage: "wifi.exclamationmark")
            } description: {
                Text(retrying ? String(localized: "Trying again…") : String(localized: "Check your connection."))
            }
        case .loaded(let content):
            loaded(content)
        }
    }

    private func loaded(_ content: GameContent) -> some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                GameHeaderView(content: content, isReconnecting: model.isReconnecting)
                if !content.live.detail.periods.isEmpty {
                    LineScoreView(content: content)
                }
                if let note = content.replayNote {
                    NoteView(text: note, systemImage: "play.rectangle")
                }
                if let note = content.coverageNote {
                    NoteView(text: note, systemImage: "info.circle")
                }
                if content.hasPlays {
                    Picker(String(localized: "Section"), selection: $tab) {
                        Text("Plays").tag(Tab.plays)
                        Text("Box score").tag(Tab.box)
                    }
                    .pickerStyle(.segmented)
                }
                if content.hasPlays && tab == .plays {
                    PlaysView(sections: content.playSections, content: content)
                } else {
                    BoxScoreView(content: content)
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.bottom, Spacing.xl)
        }
    }
}

/// Teams, rolling score digits, status, clock and the Elam target.
struct GameHeaderView: View {
    let content: GameContent
    let isReconnecting: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Spacing.s) {
            if let badge = content.replayBadge {
                ReplayBadge(text: badge)
            }
            HStack(alignment: .center) {
                team(.away)
                Spacer()
                VStack(spacing: Spacing.xs) {
                    Text(content.statusText)
                        .wehoopFont(.eyebrow)
                        .foregroundStyle(content.isLive ? Color.wehoopLive : Color.wehoopTextSecondary)
                    ClockView(clock: content.live.clock, isLive: content.live.status == .inProgress)
                }
                Spacer()
                team(.home)
            }
            if let target = content.live.elamTargetScore {
                Text("Target score \(target)")
                    .wehoopFont(.footnote)
                    .foregroundStyle(Color.wehoopTextSecondary)
            }
            if isReconnecting {
                Label(String(localized: "Reconnecting…"), systemImage: "arrow.triangle.2.circlepath")
                    .wehoopFont(.caption)
                    .foregroundStyle(Color.wehoopDelayed)
            }
        }
        .padding(Spacing.l)
        .background(Color.wehoopSurface, in: RoundedRectangle(cornerRadius: Radius.large))
        .accessibilityElement(children: .combine)
    }

    private func team(_ side: TeamSide) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(content.teamName(side))
                .wehoopFont(.subheadline)
                .foregroundStyle(Color.wehoopTextSecondary)
                .lineLimit(1)
            Text(content.score(side), format: .number)
                .wehoopFont(.score)
                .monospacedDigit()
                .foregroundStyle(Color.wehoopTextPrimary)
                .contentTransition(reduceMotion ? .identity : .numericText(value: Double(content.score(side))))
                .animation(reduceMotion ? nil : .snappy, value: content.score(side))
        }
        .frame(minWidth: 90)
    }
}

/// Counts down only while the backend says the clock runs; otherwise shows the observed value.
struct ClockView: View {
    let clock: GameClock
    let isLive: Bool

    var body: some View {
        if clock.isCounting {
            TimelineView(.periodic(from: .now, by: 0.1)) { context in
                text(at: context.date)
            }
        } else {
            text(at: .now)
        }
    }

    @ViewBuilder
    private func text(at date: Date) -> some View {
        if isLive, let remaining = clock.remaining(at: date) {
            Text(GameFormat.clock(remaining))
                .wehoopFont(.headline)
                .monospacedDigit()
                .foregroundStyle(Color.wehoopTextPrimary)
        }
    }
}

/// A line of context under the header: the replay label, the coverage level.
struct NoteView: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .wehoopFont(.footnote)
            .foregroundStyle(Color.wehoopTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.m)
            .background(Color.wehoopSurface, in: RoundedRectangle(cornerRadius: Radius.medium))
    }
}

private extension View {
    /// The package also builds on macOS (for `swift test`), where the inline title mode does not exist.
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
