import DesignSystem
import Domain
import Foundation

/// What one score card shows, derived from a schedule row. Pure, so the presentation rules
/// are tested without a view. The status rules are the game screen's (FeatureGame's
/// `GameContent.statusText`), for the list's frozen view of the game.
public struct ScoreCard: Equatable, Identifiable, Sendable {
    public let game: Game

    public init(game: Game) {
        self.game = game
    }

    public var id: Game.ID { game.id }

    /// The full name ("Las Vegas Aces", "Michigan State Spartans": a nickname alone is
    /// ambiguous across a league), else the alias, else Home or Away.
    public func teamName(_ side: TeamSide) -> String {
        let team = side == .home ? game.home : game.away
        if let name = team.name { return team.market.map { "\($0) \(name)" } ?? name }
        return team.alias ?? (side == .home ? String(localized: "Home") : String(localized: "Away"))
    }

    public func score(_ side: TeamSide) -> Int {
        side == .home ? game.score.home : game.score.away
    }

    /// The score shows once the game has started; never for a game not played (yet).
    public var showsScore: Bool {
        switch game.status {
        case .inProgress, .halftime, .delayed, .complete, .closed: true
        case .unknown: game.score != Score(home: 0, away: 0)
        default: false
        }
    }

    public var isLive: Bool { game.status.phase == .live }

    /// "Final" once the provider has validated the result; "Final · unofficial" while the
    /// statistics are still being validated (`complete`); the period (and the last observed
    /// clock) while live; the tip-off time before.
    public var statusText: String {
        switch game.status {
        case .scheduled, .created, .ifNecessary: return game.scheduledAt.formatted(date: .omitted, time: .shortened)
        case .timeTBD: return String(localized: "Time TBD")
        case .inProgress: return liveText
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

    private var liveText: String {
        guard let period = game.period else { return String(localized: "Live") }
        let label = ScoresFormat.periodLabel(period)
        guard period.kind != .elam, let remaining = game.clock.remaining else { return label }
        return label + " " + ScoresFormat.clock(remaining)
    }

    private var finalText: String {
        game.period?.kind == .overtime ? String(localized: "Final/OT") : String(localized: "Final")
    }

    /// The demo label (backend rev 4.15): never shown for a real game.
    public var replayBadge: String? {
        switch game.replay {
        case nil: nil
        case .recorded, .unknown: String(localized: "Replay")
        case .synthetic: String(localized: "Simulated replay")
        }
    }

    /// What this game's coverage cannot show; nil for full coverage.
    public var coverageHint: String? {
        switch game.coverage {
        case .full: nil
        case .extendedBoxscore: String(localized: "Score only")
        case .boxscore: String(localized: "No play-by-play")
        case .unknown: String(localized: "Limited coverage")
        }
    }

    /// The Elam ending's target, once the game is under way.
    public var targetText: String? {
        guard let target = game.elamTargetScore, game.status.phase != .pre else { return nil }
        return String(localized: "Target \(target)")
    }

    /// One VoiceOver sentence: replay label, teams (with scores once started), status, coverage.
    public var accessibilityLabel: String {
        var parts: [String] = []
        if let replayBadge { parts.append(replayBadge) }
        if showsScore {
            parts.append("\(teamName(.away)) \(game.score.away), \(teamName(.home)) \(game.score.home)")
        } else {
            parts.append(String(localized: "\(teamName(.away)) at \(teamName(.home))"))
        }
        parts.append(statusText)
        if let targetText { parts.append(targetText) }
        if let coverageHint { parts.append(coverageHint) }
        return parts.joined(separator: ". ")
    }
}

/// Period and clock text for the list.
enum ScoresFormat {
    static func periodLabel(_ period: GamePeriod) -> String {
        switch period.kind {
        case .quarter: "Q\(period.number)"
        case .half: "H\(period.number)"
        case .overtime: period.number <= 1 ? "OT" : "\(period.number)OT"
        case .elam: String(localized: "Elam")
        case .unknown, nil: "P\(period.number)"
        }
    }

    static func clock(_ seconds: Double) -> String {
        ClockText.format(seconds)
    }
}
