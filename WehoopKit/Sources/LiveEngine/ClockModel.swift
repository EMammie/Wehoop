import Foundation

/// The game clock on screen. Counts down only when the last observation says the
/// clock is running (`running == true`), from the observation's `asOf` on the
/// server's clock (local time corrected by `serverOffset`, from the snapshot's
/// `serverTime`). Stopped (`false`) or unknown (`nil`) freezes the observed value:
/// the app never guesses that a clock runs (the old app ran it through timeouts).
/// A period without a clock (Unrivaled's Elam ending) has no display.
public struct ClockModel: Sendable, Hashable {
    /// Seconds left in the period at `asOf`; nil when the observation carries no clock.
    public let base: TimeInterval?
    public let running: Bool?
    public let asOf: Date?
    /// Server time minus local time, in seconds.
    public let serverOffset: TimeInterval

    public init(observation: ClockObservation, serverOffset: TimeInterval) {
        base = observation.clockDecimal.flatMap(Self.seconds) ?? observation.clock.flatMap(Self.seconds)
        running = observation.running
        asOf = observation.asOf.flatMap(ISODate.parse)
        self.serverOffset = serverOffset
    }

    /// True when the display moves with time.
    public var isCounting: Bool { running == true && base != nil && asOf != nil }

    /// Seconds left at local time `now`; nil without a clock.
    public func remaining(at now: Date) -> TimeInterval? {
        guard let base else { return nil }
        guard isCounting, let asOf else { return base }
        let elapsed = now.addingTimeInterval(serverOffset).timeIntervalSince(asOf)
        return max(0, base - max(0, elapsed))
    }

    /// The clock as a scoreboard shows it at local time `now`; nil without a clock.
    public func display(at now: Date) -> String? {
        remaining(at: now).map(Self.format)
    }

    /// `M:SS` from a minute up (seconds rounded up, so the observed value shows until a
    /// full second has passed), `S.T` below a minute (tenths rounded up).
    public static func format(_ seconds: TimeInterval) -> String {
        if seconds >= 60 {
            let whole = Int(seconds.rounded(.up))
            return "\(whole / 60):" + String(format: "%02d", whole % 60)
        }
        let tenths = Int((seconds * 10 - 1e-9).rounded(.up))
        return "\(max(0, tenths) / 10).\(max(0, tenths) % 10)"
    }

    /// Seconds in a provider clock string: `MM:SS`, `M:SS`, `M:SS.T` or `SS.T`.
    public static func seconds(_ clock: String) -> TimeInterval? {
        let parts = clock.split(separator: ":", omittingEmptySubsequences: false)
        switch parts.count {
        case 1:
            return Double(parts[0]).flatMap { $0 >= 0 ? $0 : nil }
        case 2:
            guard let minutes = Int(parts[0]), let seconds = Double(parts[1]),
                  minutes >= 0, seconds >= 0, seconds < 60 else { return nil }
            return Double(minutes) * 60 + seconds
        default:
            return nil
        }
    }
}

extension LiveGameState {
    /// The clock display for this state's last observation.
    public func clockModel(serverOffset: TimeInterval) -> ClockModel {
        ClockModel(observation: clock, serverOffset: serverOffset)
    }
}
