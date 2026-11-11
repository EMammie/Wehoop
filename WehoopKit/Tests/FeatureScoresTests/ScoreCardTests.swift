import Domain
import Foundation
import Testing
@testable import FeatureScores

struct ScoreCardTests {
    private let q3 = GamePeriod(number: 3, kind: .quarter, sequence: 3)

    private func card(_ game: Game) -> ScoreCard { ScoreCard(game: game) }

    @Test("Status: tip-off time before, period and last clock while live, halftime, unofficial before validation, Final/OT")
    func statusText() {
        let scheduled = Sample.game("g", at: 19.5)
        #expect(card(scheduled).statusText == scheduled.scheduledAt.formatted(date: .omitted, time: .shortened))
        #expect(card(Sample.game("g", status: .timeTBD)).statusText == "Time TBD")
        #expect(card(Sample.game("g", status: .inProgress, period: q3, clock: 252)).statusText == "Q3 4:12")
        #expect(card(Sample.game("g", status: .inProgress, period: q3)).statusText == "Q3")
        #expect(card(Sample.game("g", status: .inProgress)).statusText == "Live")
        let elam = GamePeriod(number: 1, kind: .elam, sequence: 4)
        #expect(card(Sample.game("g", status: .inProgress, period: elam, clock: 0)).statusText == "Elam", "Elam has no clock")
        #expect(card(Sample.game("g", status: .halftime, period: q3)).statusText == "Halftime")
        #expect(card(Sample.game("g", status: .complete, period: q3)).statusText == "Final · unofficial")
        let ot = GamePeriod(number: 2, kind: .overtime, sequence: 6)
        #expect(card(Sample.game("g", status: .closed, period: ot)).statusText == "Final/OT")
        #expect(card(Sample.game("g", status: .closed, period: q3)).statusText == "Final")
        #expect(card(Sample.game("g", status: .postponed)).statusText == "Postponed")
        #expect(card(Sample.game("g", status: .unknown("suspended"))).statusText == "suspended")
    }

    @Test("The score shows once a game has started, never before or for a game not played")
    func showsScore() {
        #expect(!card(Sample.game("g")).showsScore)
        #expect(!card(Sample.game("g", status: .cancelled)).showsScore)
        #expect(card(Sample.game("g", status: .halftime)).showsScore)
        #expect(card(Sample.game("g", status: .closed)).showsScore)
        #expect(card(Sample.game("g", status: .inProgress)).isLive && !card(Sample.game("g", status: .closed)).isLive)
    }

    @Test("A replay carries the badge the game screen shows; a real game none")
    func replayBadge() {
        #expect(card(Sample.game("g")).replayBadge == nil)
        #expect(card(Sample.game("g", replay: .recorded)).replayBadge == "Replay")
        #expect(card(Sample.game("g", replay: .unknown("rerun"))).replayBadge == "Replay")
        #expect(card(Sample.game("g", replay: .synthetic)).replayBadge == "Simulated replay")
    }

    @Test("Coverage hints say what a game cannot show; full coverage says nothing")
    func coverageHint() {
        #expect(card(Sample.game("g")).coverageHint == nil)
        #expect(card(Sample.game("g", coverage: .extendedBoxscore)).coverageHint == "Score only")
        #expect(card(Sample.game("g", coverage: .boxscore)).coverageHint == "No play-by-play")
    }

    @Test("VoiceOver reads one sentence: the replay label first, then teams and scores, status, target and coverage")
    func accessibilityLabel() {
        let live = Sample.game(
            "g", status: .inProgress, score: Score(home: 70, away: 68), period: GamePeriod(number: 1, kind: .elam, sequence: 5),
            coverage: .extendedBoxscore, replay: .synthetic, elamTarget: 84
        )
        #expect(card(live).accessibilityLabel == "Simulated replay. Away g 68, Home g 70. Elam. Target 84. Score only")
        let upcoming = Sample.game("g", at: 19, replay: .recorded)
        #expect(card(upcoming).accessibilityLabel == "Replay. Away g at Home g. \(card(upcoming).statusText)")
        #expect(card(upcoming).targetText == nil)
    }

    @Test("Team names are market and name, else the name, else the alias, else Home and Away")
    func teamNames() {
        let named = Game(
            id: Game.ID("g"), league: League.Code("aaa"), scheduledAt: Sample.now, status: .scheduled, coverage: .full,
            home: Game.Side(teamId: nil, name: "Aces", market: "Las Vegas", alias: "LVA"),
            away: Game.Side(teamId: nil, name: "Lunar Owls", market: nil, alias: "LNR"),
            score: Score(home: 0, away: 0), period: nil, elamTargetScore: nil,
            clock: GameClock(remaining: nil, running: nil, asOf: nil), title: nil, tournamentName: nil,
            seasonYear: nil, lastSeq: 0, replay: nil
        )
        #expect(card(named).teamName(.home) == "Las Vegas Aces" && card(named).teamName(.away) == "Lunar Owls")
        let game = Game(
            id: Game.ID("g"), league: League.Code("aaa"), scheduledAt: Sample.now, status: .scheduled, coverage: .full,
            home: Game.Side(teamId: nil, name: nil, market: nil, alias: "NYL"),
            away: Game.Side(teamId: nil, name: nil, market: nil, alias: nil),
            score: Score(home: 0, away: 0), period: nil, elamTargetScore: nil,
            clock: GameClock(remaining: nil, running: nil, asOf: nil), title: nil, tournamentName: nil,
            seasonYear: nil, lastSeq: 0, replay: nil
        )
        #expect(card(game).teamName(.home) == "NYL" && card(game).teamName(.away) == "Away")
    }
}
