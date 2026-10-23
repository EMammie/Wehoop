import Testing
@testable import Domain

struct LeagueTests {
    @Test("League codes match the backend's league codes")
    func rawValuesMatchBackendCodes() {
        #expect(League.allCases.map(\.rawValue) == ["wnba", "ncaawb", "unrivaled"])
    }

    @Test("Unknown league codes do not decode to a league")
    func unknownCodeIsRejected() {
        #expect(League(rawValue: "nba") == nil)
    }
}
