import Foundation
import Testing
@testable import Contracts

/// Behavior of the generated wire types (wehoop-api `pnpm gen:swift`, M5 B1):
/// the open-union policy of plan rev 4.11 (5), shared fields on unknown variants,
/// snake_case view rows, and encode → decode equality. The per-league golden
/// fixtures of every change type land with S1 in TestSupport.
struct GeneratedDecodeTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    private func roundTrips<T: Codable & Equatable>(_ value: T) throws -> Bool {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value)) == value
    }

    private let statusChange = """
    {"v":1,"id":"11111111-1111-4111-8111-111111111111","gameId":"22222222-2222-4222-8222-222222222222",\
    "seq":7,"ts":"2026-06-30T23:16:33.000Z","type":"status",\
    "body":{"status":"inprogress","score":{"home":2,"away":0},"period":{"number":1,"type":"quarter","sequence":1}}}
    """

    @Test("A status change decodes to its body and survives a round trip")
    func statusChangeDecodes() throws {
        let change = try decode(GameChange.self, statusChange)
        guard case .status(let status) = change.type else {
            Issue.record("expected .status, got \(change.type)")
            return
        }
        #expect(change.seq == 7)
        #expect(status.body.status == .inprogress)
        #expect(status.body.score == Score(home: 2, away: 0))
        #expect(status.body.period?.type == .quarter)
        #expect(status.body.elamTargetScore == nil)
        #expect(try roundTrips(change))
    }

    @Test("A change of a type this build does not know keeps its envelope, so seq still advances")
    func unknownChangeTypeKeepsEnvelope() throws {
        let json = """
        {"v":1,"id":"11111111-1111-4111-8111-111111111111","gameId":"22222222-2222-4222-8222-222222222222",\
        "seq":8,"ts":"2026-06-30T23:16:34Z","type":"stats_arena","body":{"anything":true}}
        """
        let change = try decode(GameChange.self, json)
        #expect(change.seq == 8)
        #expect(change.type == .unknown("stats_arena"))
        #expect(change.type.rawValue == "stats_arena")
    }

    @Test("An event_insert carries a LiveEvent whose variant payload and shared base both decode")
    func shotEventDecodes() throws {
        let json = """
        {"v":1,"id":"11111111-1111-4111-8111-111111111111","gameId":"22222222-2222-4222-8222-222222222222",\
        "seq":9,"ts":"2026-06-30T23:16:35+00:00","type":"event_insert","providerEventId":"e1",\
        "body":{"type":"shot","period":{"number":1,"type":"quarter","sequence":1},"clock":"09:41",\
        "wallClock":"2026-06-30T23:16:30Z","score":{"home":2,"away":0},"providerTeamId":"t1","providerPlayerId":"p1",\
        "made":true,"points":2,"shotType":"layup","location":{"x":10,"y":20},"qualifiers":["fastbreak"]}}
        """
        let change = try decode(GameChange.self, json)
        guard case .eventInsert(let insert) = change.type, case .shot(let shot) = insert.body.type else {
            Issue.record("expected an event_insert carrying a shot, got \(change.type)")
            return
        }
        #expect(insert.providerEventId == "e1")
        #expect(shot.made && shot.points == 2 && shot.location?.x == 10)
        #expect(insert.body.period.type == .quarter)
        #expect(insert.body.clockDecimal == nil)
        #expect(insert.body.qualifiers == ["fastbreak"])
        #expect(try roundTrips(change))
    }

    @Test("An unknown play type and an unknown period type decode as .unknown with the base fields intact")
    func unknownEventAndPeriodType() throws {
        let json = """
        {"type":"hologram","period":{"number":5,"type":"shootout","sequence":5},"clock":null,"wallClock":null,\
        "score":{"home":1,"away":1}}
        """
        let event = try decode(LiveEvent.self, json)
        #expect(event.type == .unknown("hologram"))
        #expect(event.period.type == .unknown("shootout"))
        #expect(event.period.number == 5)
        #expect(event.clock == nil)
    }

    @Test("A backend enum entry literally named unknown folds into the fallback case")
    func reboundUnknownFolds() throws {
        let json = """
        {"type":"rebound","kind":"unknown","period":{"number":1,"type":"quarter","sequence":1},"clock":"1:00",\
        "wallClock":null,"score":{"home":0,"away":0}}
        """
        let event = try decode(LiveEvent.self, json)
        guard case .rebound(let rebound) = event.type else {
            Issue.record("expected .rebound, got \(event.type)")
            return
        }
        #expect(rebound.kind == .unknown("unknown"))
        #expect(LiveEvent.Rebound.Kind.known == [.offensive, .defensive, .teamOffensive, .teamDefensive])
    }

    @Test("A payload-less variant is a plain case and round-trips")
    func tipOff() throws {
        let json = """
        {"type":"tip_off","period":{"number":1,"type":"quarter","sequence":1},"clock":"10:00","wallClock":null,\
        "score":{"home":0,"away":0}}
        """
        let event = try decode(LiveEvent.self, json)
        #expect(event.type == .tipOff)
        #expect(try roundTrips(event))
    }

    @Test("A v_schedule row decodes its snake_case columns, a fourth league and a jsonb column")
    func scheduleRow() throws {
        let json = """
        {"id":"33333333-3333-4333-8333-333333333333","league":"elw","provider_game_id":"g","season_id":null,\
        "season_year":null,"season_type":null,"tournament_id":null,"tournament_name":null,"title":null,\
        "scheduled_at":"2026-11-01T17:00:00+00:00","status":"scheduled","coverage":"extended_boxscore",\
        "coverage_label":"score only","home_team_id":null,"home_name":null,"home_market":null,"home_alias":null,\
        "away_team_id":null,"away_name":null,"away_market":null,"away_alias":null,"home_points":0,"away_points":0,\
        "current_period":null,"period_type":null,"current_period_sequence":null,"elam_target_score":null,\
        "clock":null,"clock_decimal":null,"clock_running":null,"clock_as_of":null,\
        "venue":{"name":"Rome","capacity":5000,"tags":["x",null]},"broadcasts":null,"last_seq":0,"retained_from_seq":1,\
        "stats_final_at":null,"observed_at":null,"updated_at":"2026-10-31T00:00:00+00:00"}
        """
        let row = try decode(ScheduleRow.self, json)
        #expect(row.league == .unknown("elw"))
        #expect(row.coverage == .extendedBoxscore)
        #expect(row.lastSeq == 0 && row.retainedFromSeq == 1)
        #expect(row.venue?["name"] == .string("Rome"))
        #expect(row.venue?["tags"] == .array([.string("x"), .null]))
        #expect(row.seasonType == nil)
        #expect(try roundTrips(row))
    }

    @Test("Pulse and a /changes page decode; an unknown change inside a page does not fail the page")
    func pulseAndChangesPage() throws {
        let pulse = try decode(Pulse.self, """
        {"v":1,"type":"pulse","gameId":"22222222-2222-4222-8222-222222222222","latestSeq":12,"status":"halftime",\
        "clock":"0:00","clockRunning":false,"clockAsOf":"2026-06-30T23:50:00Z","observedAt":"2026-06-30T23:50:01Z"}
        """)
        #expect(pulse.latestSeq == 12 && pulse.status == .halftime && pulse.clockRunning == false)

        let page = try decode(ChangesPage.self, """
        {"changes":[\(statusChange),{"v":1,"id":"11111111-1111-4111-8111-111111111111",\
        "gameId":"22222222-2222-4222-8222-222222222222","seq":8,"ts":"2026-06-30T23:16:34Z","type":"stats_arena","body":{}}],\
        "nextAfter":8,"latestSeq":8,"hasMore":false,"retainedFrom":1}
        """)
        #expect(page.changes.count == 2)
        #expect(page.changes[1].type == .unknown("stats_arena"))
    }

    @Test("Every code enum knows its backend values and falls back to .unknown")
    func codes() {
        #expect(GameStatus.known.count == 12)
        #expect(GameStatus(rawValue: "closed") == .closed)
        #expect(GameStatus(rawValue: "suspended") == .unknown("suspended"))
        #expect(LeagueCode.known == [.wnba, .ncaawb, .unrivaled])
        #expect(SeasonType(rawValue: "CC") == .cc)
        #expect(ChangeType.known.count == 7)
        #expect(PeriodType.unknown("shootout").rawValue == "shootout")
    }
}
