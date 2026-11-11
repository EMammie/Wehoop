import Foundation

/// The leagues the app lists, in display order.
public protocol LeagueRepository: Sendable {
    func leagues() async throws -> [League]
}

/// Games by league and time window.
public protocol ScheduleRepository: Sendable {
    /// Games of `league` scheduled in `[from, to)`, ordered by scheduled time.
    func games(league: League.Code, from: Date, to: Date) async throws -> [Game]
    /// The same window read from the backend now, past any cache: the re-read after the
    /// scores channel (re)joins or the app returns to the foreground.
    func latestGames(league: League.Code, from: Date, to: Date) async throws -> [Game]
    /// One game's schedule row (teams, tip-off, coverage); nil when no such game exists.
    func game(id: Game.ID) async throws -> Game?
}

extension ScheduleRepository {
    /// For a repository without a cache, the latest read is the plain read.
    public func latestGames(league: League.Code, from: Date, to: Date) async throws -> [Game] {
        try await games(league: league, from: from, to: to)
    }
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
