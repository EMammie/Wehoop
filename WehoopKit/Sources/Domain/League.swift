/// A league the app lists: one row of the backend's `leagues` table. Features receive
/// `[League]` and never name one; adding a league is a backend row, not a code change.
public struct League: Sendable, Hashable, Identifiable {
    /// The backend's league code (`leagues.code`). Open: a code this build has never seen
    /// is still a valid code.
    public struct Code: RawRepresentable, Hashable, Sendable, Codable, Comparable, CustomStringConvertible {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }

        public init(from decoder: any Decoder) throws {
            rawValue = try decoder.singleValueContainer().decode(String.self)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }

        public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
        public var description: String { rawValue }
    }

    /// Brand colors as `#rrggbb`; nil means the app's default palette.
    public struct Colors: Sendable, Hashable {
        public let primary: String
        public let secondary: String?
        public init(primary: String, secondary: String?) {
            self.primary = primary
            self.secondary = secondary
        }
    }

    public let code: Code
    public let name: String
    public let shortName: String
    public let colors: Colors?

    public var id: Code { code }

    public init(code: Code, name: String, shortName: String, colors: Colors?) {
        self.code = code
        self.name = name
        self.shortName = shortName
        self.colors = colors
    }
}
