import Foundation

// The status line every screen shows for a game, in one place so the Scores list and the
// game screen cannot drift apart. Presentation text in Domain is a deliberate exception
// (S5 review): the rules depend only on Domain values, and Domain is the one module both
// features share. Each screen adds its own clock (DesignSystem's ClockText).

extension GamePeriod {
    /// "Q3", "H2", "OT", "2OT", "Elam"; "P5" for a kind this build does not know.
    public var shortLabel: String {
        switch kind {
        case .quarter: "Q\(number)"
        case .half: "H\(number)"
        case .overtime: number <= 1 ? "OT" : "\(number)OT"
        case .elam: String(localized: "Elam")
        case .unknown, nil: "P\(number)"
        }
    }
}

// One case per status: the switch is a table, as in WehoopData's status mapping.
// swiftlint:disable cyclomatic_complexity
extension GameStatus {
    /// The tip-off time before (or "Scheduled" without one), the period while in progress
    /// ("Live" without one), "Final" once the provider validated the result, "Final ·
    /// unofficial" while it is still validating (`complete`), "Final/OT" after overtime.
    /// An unknown status is shown as the backend sent it.
    public func text(scheduledAt: Date?, period: GamePeriod?) -> String {
        switch self {
        case .scheduled, .created, .ifNecessary:
            return scheduledAt.map { $0.formatted(date: .omitted, time: .shortened) } ?? String(localized: "Scheduled")
        case .timeTBD: return String(localized: "Time TBD")
        case .inProgress: return period?.shortLabel ?? String(localized: "Live")
        case .halftime: return String(localized: "Halftime")
        case .delayed: return String(localized: "Delayed")
        case .complete: return Self.finalText(period) + " · " + String(localized: "unofficial")
        case .closed: return Self.finalText(period)
        case .cancelled: return String(localized: "Cancelled")
        case .postponed: return String(localized: "Postponed")
        case .unnecessary: return String(localized: "Not needed")
        case .unknown(let raw): return raw
        }
    }

    // swiftlint:enable cyclomatic_complexity

    private static func finalText(_ period: GamePeriod?) -> String {
        period?.kind == .overtime ? String(localized: "Final/OT") : String(localized: "Final")
    }
}
