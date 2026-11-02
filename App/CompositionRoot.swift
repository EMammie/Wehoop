import Foundation

/// Builds the app's dependency graph and hands each feature its `Dependencies`.
///
/// S0 stub: it only decides the data mode and the tab order. S4 wires the WehoopData
/// implementations (live) or TestSupport's `ReplaySource` (fixtures) behind Domain's
/// protocols. The app never holds a provider key; it talks only to wehoop-api.
struct CompositionRoot {
    /// Where feature data comes from.
    enum DataMode: Equatable {
        /// wehoop-api and Supabase.
        case live
        /// Deterministic fixtures, for previews, UI tests and demos.
        case fixtures
    }

    /// Launch argument that switches the app to fixture data.
    static let fixturesArgument = "-WehoopFixtures"

    let dataMode: DataMode
    let tabs: [AppTab] = AppTab.allCases

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        dataMode = arguments.contains(Self.fixturesArgument) ? .fixtures : .live
    }
}
