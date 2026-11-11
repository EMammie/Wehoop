import Domain
import Foundation

/// One day of one league, split into the sections the list shows: live first, then
/// upcoming, then final, each by tip-off time. A status this build does not know goes to
/// its own section rather than being guessed into another.
public struct ScoresContent: Equatable, Sendable {
    public enum Kind: Hashable, Sendable, CaseIterable {
        case live, upcoming, final, other

        public var title: String {
            switch self {
            case .live: String(localized: "Live")
            case .upcoming: String(localized: "Upcoming")
            case .final: String(localized: "Final")
            case .other: String(localized: "Other")
            }
        }
    }

    public struct Section: Equatable, Identifiable, Sendable {
        public let kind: Kind
        public let cards: [ScoreCard]
        public var id: Kind { kind }
    }

    public let sections: [Section]

    public init(games: [Game]) {
        let ordered = games.sorted { ($0.scheduledAt, $0.id) < ($1.scheduledAt, $1.id) }
        let grouped = Dictionary(grouping: ordered, by: Self.kind)
        sections = Kind.allCases.compactMap { kind in
            grouped[kind].map { Section(kind: kind, cards: $0.map(ScoreCard.init)) }
        }
    }

    public var isEmpty: Bool { sections.isEmpty }

    /// Every card, in the order shown.
    public var cards: [ScoreCard] { sections.flatMap(\.cards) }

    public static func kind(_ game: Game) -> Kind {
        switch game.status.phase {
        case .live: .live
        case .pre: .upcoming
        case .post: .final
        case nil: .other
        }
    }
}

extension ScoreCard {
    /// The list row's identity: the game within its section.
    var rowId: String { "\(ScoresContent.kind(game))/\(game.id.rawValue)" }
}
