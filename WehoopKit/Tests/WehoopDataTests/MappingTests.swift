import Contracts
import Domain
import Foundation
import LiveEngine
import Supabase
import Testing
import TestSupport
@testable import WehoopData

struct MappingTests {
    @Test("Every golden schedule row maps to a Game with its typed ids, status and score", arguments: LeagueCode.known)
    func scheduleRows(league: LeagueCode) throws {
        let rows = try Golden.schedule(league)
        let games = rows.compactMap(Mapping.game)
        #expect(!rows.isEmpty && games.count == rows.count)
        for (row, game) in zip(rows, games) {
            #expect(game.id.rawValue == row.id && game.league.rawValue == league.rawValue)
            #expect(game.home.teamId?.rawValue == row.homeTeamId && game.away.alias == row.awayAlias)
            #expect(game.score == Domain.Score(home: row.homePoints, away: row.awayPoints))
            #expect(game.status == Mapping.status(row.status) && game.lastSeq == row.lastSeq)
        }
    }

    @Test("The replay label maps from the schedule row and the snapshot; a real game has none")
    func replayLabel() throws {
        let row = try #require(try Golden.schedule(.wnba).first)
        #expect(Mapping.game(row)?.replay == nil)
        #expect(Mapping.game(try Golden.labelled(row, replay: .recorded))?.replay == .recorded)
        #expect(Mapping.game(try Golden.labelled(row, replay: .unknown("rerun")))?.replay == .unknown("rerun"))
        let snapshot = try Golden.snapshot(.wnba)
        #expect(Mapping.liveGame(LiveGameState(snapshot: snapshot), serverOffset: 0).replay == nil)
        let synthetic = try Golden.labelled(snapshot, replay: .synthetic, at: ["game"])
        #expect(Mapping.liveGame(LiveGameState(snapshot: synthetic), serverOffset: 0).replay == .synthetic)
    }

    @Test("Leagues map with their short name and colors")
    func leagues() throws {
        let leagues = try Golden.leagues().map(Mapping.league)
        let wnba = try #require(leagues.first { $0.code.rawValue == "wnba" })
        #expect(wnba.shortName == "WNBA" && wnba.colors?.primary.hasPrefix("#") == true)
    }

    @Test("Every backend status maps, and an unknown one stays unknown")
    func statuses() {
        for status in Contracts.GameStatus.known {
            #expect(Mapping.status(status) != .unknown(status.rawValue))
        }
        #expect(Mapping.status(.unknown("suspended")) == .unknown("suspended"))
    }

    @Test("The live header puts the clock's asOf on this device's clock")
    func liveClockOffset() throws {
        let snapshot = try Golden.snapshot(.wnba)
        let state = LiveGameState(snapshot: snapshot)
        let model = state.clockModel(serverOffset: 0)
        let live = Mapping.liveGame(state, serverOffset: 5)
        #expect(live.seq == snapshot.seq && live.status == .closed)
        #expect(live.clock.remaining == model.base)
        if let serverAsOf = model.asOf {
            #expect(live.clock.asOf == serverAsOf.addingTimeInterval(-5))
        }
    }

    @Test("The player response maps to the canonical summary with external and merged ids")
    func player() throws {
        let response = try Golden.player(.boston)
        let summary = Mapping.player(response)
        #expect(summary.id.rawValue == response.player.id)
        #expect(Set(summary.externalIds.map(\.league.rawValue)) == Set(response.externalIds.map(\.league.rawValue)))
    }
}

struct RealtimeDecodeTests {
    /// A broadcast message as supabase-swift hands it to callbacks: `{event, payload, type}`.
    private func message(event: String, payload: some Encodable) throws -> JSONObject {
        let body = try JSONDecoder().decode(AnyJSON.self, from: JSONEncoder().encode(payload))
        let json = try JSONEncoder().encode(["event": AnyJSON.string(event), "type": .string("broadcast"), "payload": body])
        return try JSONDecoder().decode(JSONObject.self, from: json)
    }

    @Test("A change broadcast decodes to the same GameChange /changes serves", arguments: [GoldenGame.wnba, .unrivaledElam])
    func change(game: GoldenGame) throws {
        for change in try Golden.changes(game).prefix(40) {
            #expect(RealtimeTransport.decode(try message(event: "change", payload: change)) == .change(change))
        }
    }

    @Test("A pulse broadcast decodes; other events and bad payloads are ignored")
    func pulseAndOthers() throws {
        let pulse = try Golden.pulse(.wnba)
        #expect(RealtimeTransport.decode(try message(event: "pulse", payload: pulse)) == .pulse(pulse))
        #expect(RealtimeTransport.decode(try message(event: "scores", payload: try Golden.scoreboard(.wnba))) == nil)
        #expect(RealtimeTransport.decode(try message(event: "change", payload: ["nope": 1])) == nil)
    }
}
