import Contracts
import Foundation
import Testing
@testable import TestSupport

/// Fixture mode's Scores backend: the golden rows around a start time, the golden games
/// replayed as their row would move, and the scoreboard messages agreeing with the rows.
struct ScoreboardScriptTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)
    private let wnbaGame = "2cca74a3-7639-4f3b-a27c-7591d0be1838"
    private let unrivaledGame = "9565fc20-c54c-44ad-88fb-e32940b6f164"

    private func script() throws -> ScoreboardScript {
        try ScoreboardScript(start: start, stepInterval: 1)
    }

    private func day(around date: Date) -> (Date, Date) {
        (date.addingTimeInterval(-12 * 3600), date.addingTimeInterval(12 * 3600))
    }

    @Test("Each league's golden game tips off at the start; the other rows keep their distance to it")
    func layout() throws {
        let script = try script()
        let (from, to) = day(around: start)
        let unrivaled = try script.rows(league: .unrivaled, from: from, to: to, at: start)
        // Lunar Owls at Mist at the start, Vinyl at Rose 1 h 15 later, Laces at Phantom 19 h later (outside).
        #expect(unrivaled.map { String($0.id.prefix(8)) } == ["9565fc20", "020e8b74"])
        #expect(ScoreboardScript.parse(unrivaled[0].scheduledAt) == start)
        #expect(ScoreboardScript.parse(unrivaled[1].scheduledAt) == start.addingTimeInterval(75 * 60))
        let ncaawb = try script.rows(league: .ncaawb, from: from, to: to, at: start)
        #expect(ncaawb.count == 2, "the full and the score-only recording of one game")
        // The WNBA league's older golden games land months before.
        #expect(try script.rows(league: .wnba, from: from, to: to, at: start).map(\.id) == [wnbaGame])
    }

    @Test("A golden game is pregame until its first change, then follows its stream to the golden final row")
    func replayFollowsTheStream() throws {
        let script = try script()
        let pregame = try #require(try script.row(id: wnbaGame, at: start))
        #expect(pregame.status == .scheduled && pregame.homePoints == 0 && pregame.awayPoints == 0)
        #expect(pregame.lastSeq == 0 && pregame.currentPeriod == nil && pregame.observedAt == nil)
        #expect(pregame.replay == .recorded)

        let changes = try Golden.changes(.wnba)
        let end = try #require(script.endTime(of: wnbaGame))
        #expect(end == start.addingTimeInterval(Double(changes.count)))
        let midway = try #require(try script.row(id: wnbaGame, at: start.addingTimeInterval(600)))
        #expect(midway.lastSeq == 600 && midway.status.rawValue == "inprogress")

        let final = try #require(try script.row(id: wnbaGame, at: end.addingTimeInterval(3600)))
        let golden = try #require(try Golden.schedule(.wnba).first { $0.id == wnbaGame })
        #expect(final.status == golden.status && final.lastSeq == golden.lastSeq)
        #expect(final.homePoints == golden.homePoints && final.awayPoints == golden.awayPoints)
        #expect(final.currentPeriod == golden.currentPeriod && final.periodType == golden.periodType)
    }

    @Test("The hand-assembled Unrivaled game is labelled a simulated replay, the recordings a replay")
    func labels() throws {
        #expect(ScoreboardScript.label(for: .unrivaledElam) == .synthetic)
        #expect(ScoreboardScript.label(for: .wnba) == .recorded && ScoreboardScript.label(for: .ncaawbExtended) == .recorded)
        #expect(try script().row(id: unrivaledGame, at: start)?.replay == .synthetic)
    }

    @Test("A scoreboard message lists the games that moved in the window, each as its row then stands")
    func scoreboardAgreesWithRows() throws {
        let script = try script()
        let at = start.addingTimeInterval(300.5)
        let board = try #require(script.scoreboard(league: .wnba, after: start.addingTimeInterval(295), through: at))
        #expect(board.league == .wnba && board.type == "scores" && board.deltas.map(\.gameId) == [wnbaGame])
        let delta = board.deltas[0]
        let row = try #require(try script.row(id: wnbaGame, at: at))
        #expect(delta.latestSeq == row.lastSeq && delta.status == row.status)
        #expect(delta.score == Contracts.Score(home: row.homePoints, away: row.awayPoints))
        #expect(delta.observedAt == row.observedAt && delta.replay == .recorded)
        #expect(delta.observedAt.flatMap(ScoreboardScript.parse) == start.addingTimeInterval(300))
    }

    @Test("Nothing moved, nothing sent: before the start, inside one step, and after the game is final")
    func quietWindows() throws {
        let script = try script()
        #expect(script.scoreboard(league: .wnba, after: start.addingTimeInterval(-60), through: start) == nil)
        #expect(script.scoreboard(league: .wnba, after: start.addingTimeInterval(10.1), through: start.addingTimeInterval(10.9)) == nil)
        let end = try #require(script.endTime(of: wnbaGame))
        #expect(script.scoreboard(league: .wnba, after: end, through: end.addingTimeInterval(60)) == nil)
    }

    @Test("Successive messages are newer and newer: observedAt and seq never go back")
    func monotonic() throws {
        let script = try script()
        var last: (seq: Int, at: Date)?
        for second in stride(from: 5.0, through: 700, by: 5) {
            let window = (start.addingTimeInterval(second - 5), start.addingTimeInterval(second))
            let board = script.scoreboard(league: .ncaawb, after: window.0, through: window.1)
            for delta in board?.deltas ?? [] where delta.gameId.hasPrefix("f1c00f56") {
                let at = try #require(delta.observedAt.flatMap(ScoreboardScript.parse))
                if let last { #expect(delta.latestSeq > last.seq && at > last.at) }
                last = (delta.latestSeq, at)
            }
        }
        #expect(last?.seq == (try Golden.changes(.ncaawb).last?.seq))
    }
}
