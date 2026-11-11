import DesignSystem
import Domain
import SwiftUI

/// The Scores tab's root screen. A tapped card is `actions.didSelectGame`; the app pushes
/// the game screen.
public struct ScoresScreen: View {
    @State private var model: ScoresViewModel
    @State private var wasInBackground = false
    @Environment(\.scenePhase) private var scenePhase
    private let actions: ScoresActions

    public init(dependencies: ScoresDependencies, actions: ScoresActions = ScoresActions()) {
        _model = State(initialValue: ScoresViewModel(dependencies: dependencies))
        self.actions = actions
    }

    init(model: ScoresViewModel, actions: ScoresActions = ScoresActions()) {
        _model = State(initialValue: model)
        self.actions = actions
    }

    public var body: some View {
        VStack(spacing: Spacing.s) {
            if model.leagues.count > 1 {
                ChipPicker(
                    items: model.leagues.map { ChipPicker.Item(id: $0.code, title: $0.shortName) },
                    selection: Binding(get: { model.selectedLeague }, set: { if let code = $0 { model.select(league: code) } })
                )
            }
            WeekStrip(
                days: model.days, today: model.today,
                selection: Binding(get: { model.selectedDay }, set: { model.select(day: $0) })
            )
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.top, Spacing.s)
        .background(Color.wehoopBackground)
        .navigationTitle(String(localized: "Scores"))
        .task(id: model.runKey) { await model.run() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: wasInBackground = true
            case .active where wasInBackground:
                wasInBackground = false
                model.returnedToForeground()
            default: break
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView()
        case .empty:
            ScrollView {
                ContentUnavailableView {
                    Label(String(localized: "No games"), systemImage: "calendar")
                } description: {
                    Text(emptyMessage)
                }
                .padding(.top, Spacing.xxl)
            }
            .refreshable { await model.refresh() }
        case .failed(let message):
            ContentUnavailableView {
                Label(message, systemImage: "wifi.exclamationmark")
            } actions: {
                Button(String(localized: "Try again")) { model.retry() }
                    .buttonStyle(.bordered)
            }
        case .loaded(let content):
            list(content)
        }
    }

    private var emptyMessage: String {
        let day = model.selectedDay.formatted(date: .abbreviated, time: .omitted)
        if let league = model.selectedLeagueName {
            return String(localized: "No \(league) games on \(day).")
        }
        return String(localized: "No games on \(day).")
    }

    private func list(_ content: ScoresContent) -> some View {
        ScrollView {
            // A game that changes section (upcoming → live → final) keeps its id; the lazy
            // stack would keep showing its old row, so a row's identity includes its section.
            LazyVStack(alignment: .leading, spacing: Spacing.s, pinnedViews: [.sectionHeaders]) {
                ForEach(content.sections) { section in
                    Section {
                        ForEach(section.cards, id: \.rowId) { card in
                            Button { actions.didSelectGame(card.id) } label: { ScoreCardView(card: card) }
                                .buttonStyle(.plain)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(card.accessibilityLabel)
                                .accessibilityAddTraits(.isButton)
                                .accessibilityIdentifier("score-card")
                        }
                    } header: {
                        Text(section.kind.title)
                            .wehoopFont(.eyebrow)
                            .textCase(.uppercase)
                            .foregroundStyle(section.kind == .live ? Color.wehoopLive : Color.wehoopTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.wehoopBackground)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.bottom, Spacing.xl)
        }
        .refreshable { await model.refresh() }
    }
}

/// One game: away above home, scores once started, the status, and the replay and coverage labels.
struct ScoreCardView: View {
    let card: ScoreCard
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if card.replayBadge != nil || card.coverageHint != nil {
                HStack(spacing: Spacing.s) {
                    if let badge = card.replayBadge { ReplayBadge(text: badge) }
                    if let hint = card.coverageHint {
                        Text(hint)
                            .wehoopFont(.caption)
                            .foregroundStyle(Color.wehoopTextSecondary)
                    }
                }
            }
            HStack(alignment: .center, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    team(.away)
                    team(.home)
                }
                Spacer(minLength: Spacing.s)
                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    Text(card.statusText)
                        .wehoopFont(.eyebrow)
                        .textCase(.uppercase)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(card.isLive ? Color.wehoopLive : Color.wehoopTextSecondary)
                    if let target = card.targetText {
                        Text(target)
                            .wehoopFont(.caption)
                            .foregroundStyle(Color.wehoopTextSecondary)
                    }
                }
            }
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.wehoopSurface, in: RoundedRectangle(cornerRadius: Radius.large))
        .contentShape(RoundedRectangle(cornerRadius: Radius.large))
    }

    private func team(_ side: TeamSide) -> some View {
        HStack(spacing: Spacing.s) {
            Text(card.teamName(side))
                .wehoopFont(.headline)
                .foregroundStyle(Color.wehoopTextPrimary)
                .lineLimit(2)
            Spacer(minLength: Spacing.s)
            if card.showsScore {
                Text(card.score(side), format: .number)
                    .wehoopFont(.displaySmall)
                    .monospacedDigit()
                    .foregroundStyle(Color.wehoopTextPrimary)
                    .contentTransition(reduceMotion ? .identity : .numericText(value: Double(card.score(side))))
                    .animation(reduceMotion ? nil : .snappy, value: card.score(side))
            }
        }
    }
}
