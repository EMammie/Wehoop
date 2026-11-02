import Foundation

/// The leagues the app lists, in display order.
public protocol LeagueRepository: Sendable {
    func leagues() async throws -> [League]
}

/// Games by league and time window.
public protocol ScheduleRepository: Sendable {
    /// Games of `league` scheduled in `[from, to)`, ordered by scheduled time.
    func games(league: League.Code, from: Date, to: Date) async throws -> [Game]
}

/// Canonical players.
public protocol PlayerRepository: Sendable {
    /// The player behind `id`; a merged id returns its survivor.
    func player(id: PlayerSummary.ID) async throws -> PlayerSummary
}

/// The user's favorite players, by canonical id.
public protocol FavoritesRepository: Sendable {
    func favorites() async -> [PlayerSummary.ID]
    func add(_ id: PlayerSummary.ID) async
    func remove(_ id: PlayerSummary.ID) async
    func contains(_ id: PlayerSummary.ID) async -> Bool
}

/// A game followed live. The stream finishes after the final state of a closed game;
/// it throws when the first load fails. Cancelling the consuming task stops following.
public protocol LiveGameSource: Sendable {
    func updates(gameId: Game.ID) -> AsyncThrowingStream<LiveGameUpdate, any Error>
}
