import Contracts
import Domain
import Foundation
import LiveEngine
import Testing
import TestSupport
@testable import WehoopData

struct GameDetailMappingTests {
    private func detail(_ game: GoldenGame) throws -> (GameDetail, Snapshot) {
        let snapshot = try Golden.snapshot(game)
        return (Mapping.detail(LiveGameState(snapshot: snapshot).game), snapshot)
    }

    @Test("A full-coverage snapshot maps every play once, in the backend's order, with sides and names from the stats")
    func fullCoverage() throws {
        let (detail, snapshot) = try detail(.wnba)
        #expect(detail.plays.map(\.id) == snapshot.events.map(\.providerEventId))
        #expect(Set(detail.plays.map(\.id)).count == detail.plays.count)
        #expect(detail.teamLines.map(\.side) == [.away, .home])
        #expect(detail.playerLines.count == snapshot.playerStats.count)
        #expect(detail.playerLines.allSatisfy { $0.side != nil })
        let named = detail.plays.filter { $0.playerName != nil }
        #expect(!named.isEmpty)
        let lastScoring = try #require(detail.plays.last { $0.isScoring })
        #expect(lastScoring.score == Domain.Score(home: snapshot.game.score.home, away: snapshot.game.score.away))
        #expect(detail.periods.count == snapshot.periods.count)
    }

    @Test("Player lines: away before home, starters first within a side")
    func playerOrder() throws {
        let (detail, _) = try detail(.wnba)
        let sides = detail.playerLines.map(\.side)
        #expect(sides == sides.sorted { $0 == .away && $1 == .home })
        for side in TeamSide.allCases {
            let starters = detail.playerLines.filter { $0.side == side }.map(\.starter)
            #expect(starters == starters.sorted { $0 && !$1 })
        }
    }

    @Test("An Elam game maps its target and the Elam period")
    func elam() throws {
        let snapshot = try Golden.snapshot(.unrivaledElam)
        let live = Mapping.liveGame(LiveGameState(snapshot: snapshot), serverOffset: 0)
        #expect(live.elamTargetScore == 84)
        #expect(live.detail.periods.contains { $0.period.kind == .elam })
    }

    @Test("Info.plist configuration: values are read, and an empty or unexpanded value counts as missing")
    func infoDictionary() throws {
        let filled: [String: Any] = [
            "WehoopAPIURL": "http://127.0.0.1:3000",
            "WehoopSupabaseURL": "http://127.0.0.1:54321",
            "WehoopSupabaseAnonKey": "not-a-real-key",
        ]
        let config = try BackendConfiguration.from(infoDictionary: filled)
        #expect(config.apiBaseURL.absoluteString == "http://127.0.0.1:3000")
        var empty = filled
        empty["WehoopSupabaseAnonKey"] = ""
        #expect(throws: BackendConfiguration.Problem.missing("WEHOOP_SUPABASE_ANON_KEY")) {
            try BackendConfiguration.from(infoDictionary: empty)
        }
        var unexpanded = filled
        unexpanded["WehoopAPIURL"] = "$(WEHOOP_API_URL)"
        #expect(throws: BackendConfiguration.Problem.missing("WEHOOP_API_URL")) {
            try BackendConfiguration.from(infoDictionary: unexpanded)
        }
    }
}
