import Domain
import Foundation

/// What the game screen shows, derived from the live state and the schedule row. Pure, so
/// the presentation rules are tested without a view.
public struct GameContent: Equatable, Sendable {
    public let schedule: Game?
    public let live: LiveGame

    public init(schedule: Game?, live: LiveGame) {
        self.schedule = schedule
        self.live = live
    }

    /// Plays grouped by period, newest period and newest play first.
    public struct PlaySection: Equatable, Sendable, Identifiable {
        public let period: GamePeriod
        public let plays: [Play]
        public var id: String { "\(period.sequence ?? period.number)-\(period.number)" }
    }

    public var playSections: [PlaySection] {
        var sections: [PlaySection] = []
        for play in live.detail.plays.reversed() {
            if let last = sections.last, last.period == play.period {
                sections[sections.count - 1] = PlaySection(period: last.period, plays: last.plays + [play])
            } else {
                sections.append(PlaySection(period: play.period, plays: [play]))
            }
        }
        return sections
    }

    public func teamName(_ side: TeamSide) -> String {
        let team = side == .home ? schedule?.home : schedule?.away
        return team?.name ?? team?.alias ?? (side == .home ? String(localized: "Home") : String(localized: "Away"))
    }

    public func teamAbbreviation(_ side: TeamSide) -> String {
        let team = side == .home ? schedule?.home : schedule?.away
        return team?.alias ?? String(teamName(side).prefix(3)).uppercased()
    }

    public func score(_ side: TeamSide) -> Int {
        side == .home ? live.score.home : live.score.away
    }

    public func teamLine(_ side: TeamSide) -> TeamBoxLine? {
        live.detail.teamLines.first { $0.side == side }
    }

    public func playerLines(_ side: TeamSide) -> [PlayerBoxLine] {
        live.detail.playerLines.filter { $0.side == side }
    }

    /// Whether this game has a play-by-play at all.
    public var hasPlays: Bool { live.coverage == .full || !live.detail.plays.isEmpty }

    /// The coverage label: what this game's data can and cannot show. Nil for full coverage.
    public var coverageNote: String? {
        switch live.coverage {
        case .full:
            nil
        case .extendedBoxscore:
            String(localized: """
                Score-only coverage: the score, period and status update live. \
                There is no play-by-play, and the box score arrives when the game is final.
                """)
        case .boxscore:
            String(localized: "Box-score coverage: there is no play-by-play for this game.")
        case .unknown:
            String(localized: "Limited coverage: some of this game's data may be missing.")
        }
    }

    /// "Final" once the provider has validated the result; "Final · unofficial" while the
    /// statistics are still being validated (`complete`).
    public var statusText: String {
        let live = live
        switch live.status {
        case .scheduled, .created, .ifNecessary:
            return schedule.map { $0.scheduledAt.formatted(date: .omitted, time: .shortened) } ?? String(localized: "Scheduled")
        case .timeTBD: return String(localized: "Time TBD")
        case .inProgress: return live.period.map(GameFormat.periodLabel) ?? String(localized: "Live")
        case .halftime: return String(localized: "Halftime")
        case .delayed: return String(localized: "Delayed")
        case .complete: return finalText + " · " + String(localized: "unofficial")
        case .closed: return finalText
        case .cancelled: return String(localized: "Cancelled")
        case .postponed: return String(localized: "Postponed")
        case .unnecessary: return String(localized: "Not needed")
        case .unknown(let raw): return raw
        }
    }

    private var finalText: String {
        switch live.period?.kind {
        case .overtime: String(localized: "Final/OT")
        default: String(localized: "Final")
        }
    }

    public var isLive: Bool { live.status.phase == .live }
}
