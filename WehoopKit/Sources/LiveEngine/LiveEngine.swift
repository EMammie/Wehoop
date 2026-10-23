/// LiveEngine: the pure `LiveGameState` reducer (`init(snapshot:)`, `apply(GameChange)`
/// with dedupe on id and gap detection on seq, `apply(Pulse)`), the `GameSync` actor that
/// implements the backend reconnect contract (subscribe, buffer, snapshot, page
/// `/changes`, re-snapshot when history expired, catch up on reconnect), and `ClockModel`.
/// Transport, API and clock are injected protocols. No networking, no UI.
///
/// S0 placeholder: the reducer and sync land in S2.
import Contracts
import Domain

/// Outcome of offering a change with sequence number `seq` to a state at `lastSeq`.
public enum SequenceCheck: Sendable, Equatable {
    case next
    case duplicate
    case gap
}

/// Classifies `seq` against the last applied sequence number.
public func checkSequence(_ seq: Int, after lastSeq: Int) -> SequenceCheck {
    if seq <= lastSeq { return .duplicate }
    return seq == lastSeq + 1 ? .next : .gap
}
