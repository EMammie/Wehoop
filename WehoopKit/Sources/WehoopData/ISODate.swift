import Foundation

/// Timestamps as the backend writes them: `Z` or `+00:00`, with or without fractions
/// (PostgREST renders `timestamptz` with a colon offset; the API with `Z`).
enum ISODate {
    private static let styles: [Date.ISO8601FormatStyle] = [
        .init(includingFractionalSeconds: true),
        .init(),
        .init(timeZoneSeparator: .colon, includingFractionalSeconds: true),
        .init(timeZoneSeparator: .colon),
    ]

    static func parse(_ string: String) -> Date? {
        for style in styles {
            if let date = try? Date(string, strategy: style) { return date }
        }
        return nil
    }

    /// For PostgREST filters: UTC with fractional seconds and `Z`.
    static func format(_ date: Date) -> String {
        Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
    }
}
