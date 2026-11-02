/// A canonical player: one person across every league the backend links.
public struct PlayerSummary: Sendable, Hashable, Identifiable {
    public typealias ID = Identifier<PlayerTag>

    /// A provider id the backend holds for this player (`player_external_ids`).
    public struct ExternalId: Sendable, Hashable {
        public let provider: String
        public let league: League.Code
        public let value: String
        public init(provider: String, league: League.Code, value: String) {
            self.provider = provider
            self.league = league
            self.value = value
        }
    }

    /// Always the surviving canonical id: a merged (tombstoned) id resolves to it.
    public let id: ID
    public let fullName: String
    public let position: String?
    public let jersey: String?
    public let headshotURL: String?
    public let externalIds: [ExternalId]
    /// Canonical ids merged into this player; a stored favorite with one of them is this player.
    public let mergedIds: [ID]

    public init(
        id: ID, fullName: String, position: String?, jersey: String?, headshotURL: String?,
        externalIds: [ExternalId], mergedIds: [ID]
    ) {
        self.id = id
        self.fullName = fullName
        self.position = position
        self.jersey = jersey
        self.headshotURL = headshotURL
        self.externalIds = externalIds
        self.mergedIds = mergedIds
    }
}
