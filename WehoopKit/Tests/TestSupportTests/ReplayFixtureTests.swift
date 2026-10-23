import Testing
@testable import TestSupport

struct ReplayFixtureTests {
    @Test("Each replay fixture maps to the league it was recorded in")
    func fixtureLeagues() {
        #expect(ReplayFixture.wnba.league == .wnba)
        #expect(ReplayFixture.ncaawb.league == .ncaawb)
    }
}
