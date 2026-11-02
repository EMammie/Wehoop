import Foundation
import Testing
@testable import Domain

struct DomainValueTests {
    @Test("Every known status has the backend's phase; an unknown status has none")
    func statusPhases() {
        let pre: [GameStatus] = [.scheduled, .created, .timeTBD, .ifNecessary]
        let live: [GameStatus] = [.inProgress, .halftime, .delayed]
        let post: [GameStatus] = [.complete, .closed, .cancelled, .postponed, .unnecessary]
        #expect(pre.allSatisfy { $0.phase == .pre })
        #expect(live.allSatisfy { $0.phase == .live })
        #expect(post.allSatisfy { $0.phase == .post })
        #expect(GameStatus.unknown("suspended").phase == nil)
    }

    @Test("Only closed is final; complete is over but not final")
    func finality() {
        #expect(GameStatus.closed.isFinal)
        #expect(!GameStatus.complete.isFinal)
    }

    @Test("Typed ids encode as their plain string and decode back")
    func identifierCoding() throws {
        let ids: [Game.ID] = [Game.ID("a"), Game.ID("b")]
        let data = try JSONEncoder().encode(ids)
        #expect(String(bytes: data, encoding: .utf8) == #"["a","b"]"#)
        #expect(try JSONDecoder().decode([Game.ID].self, from: data) == ids)
    }

    @Test("A league code this build has never seen is still a code")
    func openLeagueCode() throws {
        let code = try JSONDecoder().decode(League.Code.self, from: Data(#""elw""#.utf8))
        #expect(code.rawValue == "elw")
        #expect(League(code: code, name: "EuroLeague Women", shortName: "ELW", colors: nil).id == code)
    }
}
