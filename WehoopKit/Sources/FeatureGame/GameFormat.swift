import Domain
import Foundation

/// Text for clocks, periods and box score cells.
enum GameFormat {
    /// `M:SS` from a minute up (rounded up, so the observed value shows until a full second
    /// has passed), `S.T` below a minute (tenths rounded up). Matches LiveEngine's `ClockModel`.
    static func clock(_ seconds: Double) -> String {
        if seconds >= 60 {
            let whole = Int(seconds.rounded(.up))
            return "\(whole / 60):" + String(format: "%02d", whole % 60)
        }
        let tenths = max(0, Int((seconds * 10 - 1e-9).rounded(.up)))
        // Just under a minute rounds up to 600 tenths: that is the minute display.
        if tenths >= 600 { return "1:00" }
        return "\(tenths / 10).\(tenths % 10)"
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
