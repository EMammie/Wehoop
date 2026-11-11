import DesignSystem
import Domain
import Foundation

/// Text for clocks, periods and box score cells.
enum GameFormat {
    /// The shared clock text (DesignSystem), so the list and the game screen agree.
    static func clock(_ seconds: Double) -> String {
        ClockText.format(seconds)
    }

    static func periodLabel(_ period: GamePeriod) -> String {
        switch period.kind {
        case .quarter: "Q\(period.number)"
        case .half: "H\(period.number)"
        case .overtime: period.number <= 1 ? "OT" : "\(period.number)OT"
        case .elam: String(localized: "Elam")
        case .unknown, nil: "P\(period.number)"
        }
    }

    /// A count, or an en dash when the provider did not report it (never a made-up 0).
    static func count(_ value: Int?) -> String {
        value.map(String.init) ?? "–"
    }

    static func madeAttempted(_ made: Int?, _ attempted: Int?) -> String {
        guard let made, let attempted else { return "–" }
        return "\(made)-\(attempted)"
    }

    static func plusMinus(_ value: Int?) -> String {
        guard let value else { return "–" }
        return value > 0 ? "+\(value)" : "\(value)"
    }

    /// Minutes played (`MM:SS`) as whole minutes, truncated like a printed box score: "32:41" → "32".
    static func minutes(_ value: String?) -> String {
        guard let value, let minutes = value.split(separator: ":").first, let whole = Int(minutes) else { return "–" }
        return "\(whole)"
    }
}
