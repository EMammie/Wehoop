/// TestSupport: the golden JSON captured from the backend (`Fixtures/`, wehoop-api
/// `pnpm golden` over a dev stack seeded with `pnpm seed:dev`; recaptured with
/// `scripts/sync-goldens.sh`), decoded through the generated `Contracts` types, plus
/// (S2) `FakeTransport` with injectable drops and duplicates and a deterministic
/// `ReplaySource` for previews, UI tests and `-WehoopFixtures`.
///
/// Every file in `Fixtures/manifest.json` is a body the backend served (the Hono
/// API in-process, or the local PostgREST as the anon role), parsed with its Zod
/// contract before it was written. Nothing here is hand-written JSON.
import Contracts
import Foundation

/// The seeded games the goldens were captured for. Raw values are the file stems
/// (`Fixtures/<league>/<stem>/…`), which name the backend replay fixture.
public enum GoldenGame: String, CaseIterable, Sendable {
    /// Las Vegas Aces at New York Liberty, 2026 Commissioner's Cup final: full coverage, every change type.
    case wnba = "sim-93ee7c68"
    /// Northwestern at Michigan State, 2025 REG: full coverage.
    case ncaawb = "sim-d9b71fe0"
    /// The same recording relabelled `extended_boxscore`: status and period changes only, stats when final.
    case ncaawbExtended = "sim-d9b71fe0-extended"
    /// Lunar Owls at Mist, hand-assembled from Sportradar docs samples: Elam period, target 84 (partly synthetic).
    case unrivaledElam = "docs-838316ea"

    public var league: LeagueCode {
        switch self {
        case .wnba: .wnba
        case .ncaawb, .ncaawbExtended: .ncaawb
        case .unrivaledElam: .unrivaled
        }
    }

    public var coverage: CoverageLevel {
        self == .ncaawbExtended ? .extendedBoxscore : .full
    }

    var directory: String { "\(league.rawValue)/\(rawValue)" }
}

/// `/v1/players/:id` responses captured: Boston (WNBA + NCAAW + Unrivaled ids), Stuelke, Collier.
public enum GoldenPlayer: String, CaseIterable, Sendable {
    case boston, stuelke, collier
}

/// `Fixtures/manifest.json`: what was captured, from which backend commit, as which contract type.
public struct GoldenManifest: Decodable, Sendable {
    public struct Entry: Decodable, Sendable {
        public let file: String
        /// The contract name in wehoop-api `src/contracts/registry.ts` (the Swift type of the same name).
        public let type: String
        /// True when the file is a JSON array of `type` (PostgREST rows).
        public let array: Bool
        public let league: String?
        public let game: String?
        /// The API path, PostgREST path or function the bytes came from.
        public let source: String
    }

    public struct Game: Decodable, Sendable {
        public let league: String
        public let providerGameId: String
        public let stem: String
        public let note: String
    }

    public let generator: String
    public let backendCommit: String
    public let capturedAt: String
    public let games: [Game]
    public let entries: [Entry]
}

public enum GoldenError: Error, CustomStringConvertible {
    case missing(String)

    public var description: String {
        switch self {
        case .missing(let path): "golden fixture missing: \(path) (run scripts/sync-goldens.sh)"
        }
    }
}

/// Typed access to the golden files. Paths are relative to `Fixtures/`.
public enum Golden {
    public static func url(_ path: String) throws -> URL {
        guard let root = Bundle.module.url(forResource: "Fixtures", withExtension: nil) else {
            throw GoldenError.missing("Fixtures")
        }
        let url = root.appendingPathComponent(path)
        guard FileManager.default.fileExists(atPath: url.path) else { throw GoldenError.missing(path) }
        return url
    }

    public static func data(_ path: String) throws -> Data {
        try Data(contentsOf: url(path))
    }

    public static func decode<T: Decodable>(_ path: String) throws -> T {
        try JSONDecoder().decode(T.self, from: data(path))
    }

    public static func decode<T: Decodable>(_ type: T.Type, _ path: String) throws -> T {
        try decode(path)
    }

    public static func manifest() throws -> GoldenManifest {
        try decode("manifest.json")
    }

    // MARK: Tables and per-league views (PostgREST bodies)

    public static func leagues() throws -> [LeagueRow] {
        try decode("leagues.json")
    }

    public static func schedule(_ league: LeagueCode) throws -> [ScheduleRow] {
        try decode("\(league.rawValue)/schedule.json")
    }

    public static func standings(_ league: LeagueCode) throws -> [StandingsRow] {
        try decode("\(league.rawValue)/standings.json")
    }

    public static func playerSeasons(_ league: LeagueCode) throws -> [PlayerSeasonRow] {
        try decode("\(league.rawValue)/player-seasons.json")
    }

    /// The top ranks of every category (50 rows ordered by rank, then category).
    public static func leaders(_ league: LeagueCode) throws -> [LeadersRow] {
        try decode("\(league.rawValue)/leaders.json")
    }

    /// One `league:{code}:scores` message covering every seeded game of the league.
    public static func scoreboard(_ league: LeagueCode) throws -> Scoreboard {
        try decode("\(league.rawValue)/scoreboard.json")
    }

    // MARK: Per game (API bodies)

    public static func snapshot(_ game: GoldenGame) throws -> Snapshot {
        try decode("\(game.directory)/snapshot.json")
    }

    /// Every `/changes` page from `after=0` (limit 500), in order; the last has `hasMore == false`.
    public static func changesPages(_ game: GoldenGame) throws -> [ChangesPage] {
        var pages: [ChangesPage] = []
        var page = 1
        while (try? url("\(game.directory)/changes-p\(page).json")) != nil {
            pages.append(try decode("\(game.directory)/changes-p\(page).json"))
            page += 1
        }
        guard !pages.isEmpty else { throw GoldenError.missing("\(game.directory)/changes-p1.json") }
        return pages
    }

    /// The whole durable stream of the game, seq 1…latestSeq.
    public static func changes(_ game: GoldenGame) throws -> [GameChange] {
        try changesPages(game).flatMap(\.changes)
    }

    /// `/changes?after=<latestSeq>`: the empty page a caught-up client receives.
    public static func tailPage(_ game: GoldenGame) throws -> ChangesPage {
        try decode("\(game.directory)/changes-tail.json")
    }

    /// The pulse the worker would send for the stored game (built by `buildPulse`).
    public static func pulse(_ game: GoldenGame) throws -> Pulse {
        try decode("\(game.directory)/pulse.json")
    }

    /// `v_boxscore` rows of the game (one per provider player id).
    public static func boxscore(_ game: GoldenGame) throws -> [BoxscoreRow] {
        try decode("\(game.directory)/boxscore.json")
    }

    // MARK: Players

    public static func player(_ player: GoldenPlayer) throws -> PlayerResponse {
        try decode("players/\(player.rawValue).json")
    }
}
