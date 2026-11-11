import Foundation
import Testing
@testable import Domain

struct ScoreUpdateTests {
    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    private func game(seq: Int = 10, observedAt: Date?, replay: ReplayKind? = nil) -> Game {
        Game(
            id: Game.ID("g1"), league: League.Code("wnba"), scheduledAt: t0, status: .inProgress, coverage: .full,
            home: Game.Side(teamId: nil, name: "Liberty", market: nil, alias: "NYL"),
            away: Game.Side(teamId: nil, name: "Aces", market: nil, alias: "LVA"),
            score: Score(home: 10, away: 8), period: GamePeriod(number: 1, kind: .quarter, sequence: 1),
            elamTargetScore: nil, clock: GameClock(remaining: 300, running: true, asOf: t0), title: "Final",
            tournamentName: nil, seasonYear: 2026, lastSeq: seq, replay: replay, observedAt: observedAt
        )
    }

    private func update(id: String = "g1", seq: Int, observedAt: Date?, replay: ReplayKind? = nil) -> ScoreUpdate {
        ScoreUpdate(
            gameId: Game.ID(id), score: Score(home: 12, away: 8), status: .halftime,
            period: GamePeriod(number: 2, kind: .quarter, sequence: 2), clockRemaining: 0,
            latestSeq: seq, observedAt: observedAt, replay: replay
        )
    }

    @Test("A newer update replaces score, status, period and clock (frozen); the teams and tip-off stay")
    func appliesNewer() throws {
        let applied = try #require(game(observedAt: t0).applying(update(seq: 11, observedAt: t0 + 5)))
        #expect(applied.score == Score(home: 12, away: 8))
        #expect(applied.status == .halftime && applied.period?.number == 2)
        #expect(applied.clock == GameClock(remaining: 0, running: nil, asOf: t0 + 5))
        #expect(applied.lastSeq == 11 && applied.observedAt == t0 + 5)
        #expect(applied.home.name == "Liberty" && applied.scheduledAt == t0 && applied.title == "Final")
    }

    @Test("The newer observedAt wins, whatever the seq says; at the same time the higher seq wins")
    func observedAtWins() {
        let row = game(seq: 10, observedAt: t0)
        #expect(row.applying(update(seq: 10, observedAt: t0 - 1)) == nil)
        #expect(row.applying(update(seq: 12, observedAt: t0 - 1)) == nil)
        #expect(row.applying(update(seq: 10, observedAt: t0 + 1)) != nil)
        #expect(row.applying(update(seq: 11, observedAt: t0)) != nil)
        #expect(row.applying(update(seq: 10, observedAt: t0)) == nil, "a repeated delta changes nothing")
    }

    @Test("Without both times the seq decides")
    func seqFallback() {
        #expect(game(seq: 10, observedAt: nil).applying(update(seq: 11, observedAt: t0)) != nil)
        #expect(game(seq: 10, observedAt: nil).applying(update(seq: 10, observedAt: t0)) == nil)
        #expect(game(seq: 10, observedAt: t0).applying(update(seq: 11, observedAt: nil)) != nil)
        #expect(game(seq: 10, observedAt: t0).applying(update(seq: 9, observedAt: nil)) == nil)
    }

    @Test("An update for another game changes nothing")
    func foreignGame() {
        #expect(game(observedAt: t0).applying(update(id: "g2", seq: 99, observedAt: t0 + 60)) == nil)
    }

    @Test("The replay label comes from the update, and an update without one keeps the row's")
    func replayLabel() {
        #expect(game(observedAt: nil).applying(update(seq: 11, observedAt: nil, replay: .synthetic))?.replay == .synthetic)
        #expect(game(observedAt: nil, replay: .recorded).applying(update(seq: 11, observedAt: nil))?.replay == .recorded)
    }

    @Test("A row read again is older than what is shown only when the shown one is newer")
    func rowVersusRow() {
        let shown = game(seq: 12, observedAt: t0 + 10)
        #expect(game(seq: 11, observedAt: t0).isOlder(than: shown))
        #expect(!shown.isOlder(than: game(seq: 11, observedAt: t0)))
        #expect(!shown.isOlder(than: shown))
    }
}
