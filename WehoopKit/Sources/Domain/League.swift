/// Domain: the app's entities as `Sendable` value types (League, Season, Team, Player,
/// Game and GameStatus, Period, GameClock, Coverage, PlayEvent, stat lines, Standing,
/// PlayerSeasonLine, Tournament) and the `Sendable`, `async throws` repository
/// protocols, including `LiveGameSource`. Foundation only: no formatting, no provider
/// strings, no networking. Absent stats are `nil`, never 0.
///
/// S0 placeholder: only `League` exists so far.

/// A league the app covers.
public enum League: String, Sendable, Hashable, CaseIterable, Codable {
    case wnba
    case ncaawb
    case unrivaled
}
