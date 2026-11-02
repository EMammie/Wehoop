import DesignSystem
import Domain
import SwiftUI

/// Points per period, away above home.
struct LineScoreView: View {
    let content: GameContent

    var body: some View {
        let periods = content.live.detail.periods
        Grid(alignment: .trailing, horizontalSpacing: Spacing.m, verticalSpacing: Spacing.xs) {
            GridRow {
                Text("").gridColumnAlignment(.leading)
                ForEach(periods, id: \.self) { Text(GameFormat.periodLabel($0.period)) }
                Text("T")
            }
            .wehoopFont(.caption)
            .foregroundStyle(Color.wehoopTextSecondary)
            ForEach(TeamSide.allCases.reversed(), id: \.self) { side in
                GridRow {
                    Text(content.teamAbbreviation(side)).gridColumnAlignment(.leading)
                    ForEach(periods, id: \.self) { Text("\(side == .home ? $0.score.home : $0.score.away)") }
                    Text("\(content.score(side))").bold()
                }
                .wehoopFont(.subheadline)
                .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(Color.wehoopSurface, in: RoundedRectangle(cornerRadius: Radius.medium))
    }
}

/// The play-by-play, newest first. Rows are keyed by the provider's event id, so a corrected
/// play updates in place and a catch-up never adds a second copy.
struct PlaysView: View {
    let sections: [GameContent.PlaySection]
    let content: GameContent

    var body: some View {
        LazyVStack(alignment: .leading, spacing: Spacing.s, pinnedViews: [.sectionHeaders]) {
            if sections.isEmpty {
                Text("No plays yet.")
                    .wehoopFont(.callout)
                    .foregroundStyle(Color.wehoopTextSecondary)
            }
            ForEach(sections) { section in
                Section {
                    ForEach(section.plays) { PlayRow(play: $0, content: content) }
                } header: {
                    Text(GameFormat.periodLabel(section.period))
                        .wehoopFont(.eyebrow)
                        .foregroundStyle(Color.wehoopTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.wehoopBackground)
                }
            }
        }
    }
}

struct PlayRow: View {
    let play: Play
    let content: GameContent

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
            Text(play.clock ?? "")
                .wehoopFont(.caption)
                .monospacedDigit()
                .foregroundStyle(Color.wehoopTextSecondary)
                .frame(width: 44, alignment: .leading)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if let side = play.side {
                    Text(content.teamAbbreviation(side))
                        .wehoopFont(.eyebrow)
                        .foregroundStyle(Color.wehoopTextSecondary)
                }
                Text(play.description ?? play.playerName ?? "")
                    .wehoopFont(play.isScoring ? .headline : .callout)
                    .foregroundStyle(Color.wehoopTextPrimary)
            }
            Spacer(minLength: Spacing.s)
            if play.isScoring {
                Text("\(play.score.away)-\(play.score.home)")
                    .wehoopFont(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(Color.wehoopTextPrimary)
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

/// Team totals and player lines for one side at a time.
struct BoxScoreView: View {
    let content: GameContent
    @State private var side: TeamSide = .away

    private static let columns: [(String, (BoxStats) -> String)] = [
        ("MIN", { GameFormat.minutes($0.minutes) }),
        ("PTS", { GameFormat.count($0.points) }),
        ("REB", { GameFormat.count($0.rebounds) }),
        ("AST", { GameFormat.count($0.assists) }),
        ("FG", { GameFormat.madeAttempted($0.fieldGoalsMade, $0.fieldGoalsAttempted) }),
        ("3PT", { GameFormat.madeAttempted($0.threesMade, $0.threesAttempted) }),
        ("FT", { GameFormat.madeAttempted($0.freeThrowsMade, $0.freeThrowsAttempted) }),
        ("STL", { GameFormat.count($0.steals) }),
        ("BLK", { GameFormat.count($0.blocks) }),
        ("TO", { GameFormat.count($0.turnovers) }),
        ("PF", { GameFormat.count($0.fouls) }),
        ("+/-", { GameFormat.plusMinus($0.plusMinus) }),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Picker(String(localized: "Team"), selection: $side) {
                ForEach(TeamSide.allCases.reversed(), id: \.self) { Text(content.teamName($0)).tag($0) }
            }
            .pickerStyle(.segmented)
            let players = content.playerLines(side)
            if players.isEmpty && content.teamLine(side) == nil {
                Text("No box score yet.")
                    .wehoopFont(.callout)
                    .foregroundStyle(Color.wehoopTextSecondary)
            } else {
                table(players: players, team: content.teamLine(side))
            }
        }
    }

    private func table(players: [PlayerBoxLine], team: TeamBoxLine?) -> some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: 0) {
                cell(String(localized: "Player"), header: true, alignment: .leading)
                ForEach(players) { cell(name($0), alignment: .leading) }
                if team != nil { cell(String(localized: "Team"), header: true, alignment: .leading) }
            }
            .frame(width: 128)
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .trailing, spacing: 0) {
                    row(Self.columns.map(\.0), header: true)
                    ForEach(players) { player in row(Self.columns.map { $0.1(player.stats) }) }
                    if let team { row(Self.columns.map { $0.1(team.stats) }, header: true) }
                }
            }
        }
    }

    private func name(_ player: PlayerBoxLine) -> String {
        player.starter ? player.name + " *" : player.name
    }

    private func row(_ values: [String], header: Bool = false) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(values.enumerated()), id: \.offset) { cell($0.element, header: header).frame(width: 46) }
        }
    }

    private func cell(_ text: String, header: Bool = false, alignment: Alignment = .trailing) -> some View {
        Text(text)
            .wehoopFont(header ? .eyebrow : .footnote)
            .monospacedDigit()
            .lineLimit(1)
            .foregroundStyle(header ? Color.wehoopTextSecondary : Color.wehoopTextPrimary)
            .frame(maxWidth: .infinity, minHeight: 28, alignment: alignment)
    }
}
