/// A game the demo environment replays from a committed recording (backend plan rev 4.15),
/// never a game happening now. Nil on `Game` / `LiveGame` for a real game.
public enum ReplayKind: Sendable, Hashable {
    /// A recorded game (Sportradar Simulations), replayed at real-time speed.
    case recorded
    /// Assembled from documentation samples: not a game that was played.
    case synthetic
    /// A label this build does not know: still a replay, shown as one.
    case unknown(String)
}
