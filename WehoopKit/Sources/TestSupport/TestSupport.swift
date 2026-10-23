/// TestSupport: fixture snapshots and change streams generated from the backend's
/// committed replay fixtures (WNBA `sim-93ee7c68`, NCAAWB `sim-d9b71fe0`, the Unrivaled
/// docs set with Elam), `FakeTransport` with injectable drops and duplicates, and a
/// deterministic `ReplaySource` for previews, UI tests and `-WehoopFixtures`.
///
/// S0 placeholder: fixtures land with S1/S2.
import Contracts
import Domain
import LiveEngine

/// Identifiers of the backend replay fixtures this module will vend.
public enum ReplayFixture: String, Sendable, CaseIterable {
    case wnba = "sim-93ee7c68"
    case ncaawb = "sim-d9b71fe0"

    /// The league the fixture was recorded in.
    public var league: League {
        switch self {
        case .wnba: .wnba
        case .ncaawb: .ncaawb
        }
    }
}
