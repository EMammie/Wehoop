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

    /// The shared status line (Domain's `GameStatus.text`, as on the game screen), with
    /// the last observed clock after the period while in progress (frozen: the list does
    /// not count down). Elam has no clock.
    public var statusText: String {
        let text = game.status.text(scheduledAt: game.scheduledAt, period: game.period)
        guard game.status == .inProgress, let period = game.period, period.kind != .elam,
              let remaining = game.clock.remaining else { return text }
        return text + " " + ClockText.format(remaining)
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
            let (away, home) = (teamName(.away), teamName(.home))
            parts.append(String(localized: "\(away) \(game.score.away), \(home) \(game.score.home)"))
        } else {
            let (away, home) = (teamName(.away), teamName(.home))
            parts.append(String(localized: "\(away) at \(home)"))
        }
        parts.append(statusText)
        if let targetText { parts.append(targetText) }
        if let coverageHint { parts.append(coverageHint) }
        return parts.joined(separator: ". ")
    }
}
