import Domain
import FeatureScores
import Foundation
import Testing
@testable import Wehoop

struct ScoresNavigationTests {
    @Test("Tapping a score card pushes that game onto the Scores tab")
    func cardOpensGame() {
        let navigation = AppNavigation()
        navigation.scoresActions.didSelectGame(Game.ID("g1"))
        #expect(navigation.selectedTab == .scores)
        #expect(navigation.path(for: .scores) == [.game(Game.ID("g1"))])
        navigation.scoresActions.didSelectGame(Game.ID("g2"))
        #expect(navigation.path(for: .scores) == [.game(Game.ID("g1")), .game(Game.ID("g2"))])
    }

    @Test("The Scores action pushes on the Scores tab even if another tab is selected meanwhile")
    func pushesOnItsOwnTab() {
        let navigation = AppNavigation()
        let actions = navigation.scoresActions
        navigation.select(.teams)
        actions.didSelectGame(Game.ID("g1"))
        #expect(navigation.path(for: .scores) == [.game(Game.ID("g1"))])
        #expect(navigation.path(for: .teams).isEmpty)
    }

    @Test("Fixture mode's Scores tab lists each league's golden game on the launch day, labelled as a replay")
    func fixtureScores() async throws {
        let start = Date()
        let backend = FixtureBackend(start: start)
        let leagues = try await backend.leagues.leagues()
        #expect(leagues.map(\.code.rawValue) == ["wnba", "ncaawb", "unrivaled"])
        let day = Calendar.current.startOfDay(for: start)
        let games = try await backend.schedule.games(
            league: League.Code("wnba"), from: day, to: Calendar.current.date(byAdding: .day, value: 1, to: day)!
        )
        let golden = try #require(games.first { $0.id == Game.ID("2cca74a3-7639-4f3b-a27c-7591d0be1838") })
        #expect(golden.replay == .recorded && golden.home.name == "Liberty")
    }

    @Test("Fixture mode's scoreboard joins, then sends score changes for the playing game")
    func fixtureScoreChanges() async {
        let backend = FixtureBackend(start: Date(), scoreStep: 0.01, scoreTick: .milliseconds(50))
        var events = backend.liveScores.scores(league: League.Code("wnba")).makeAsyncIterator()
        #expect(await events.next() == .subscribed)
        guard case .updates(let updates)? = await events.next() else {
            Issue.record("expected score updates")
            return
        }
        #expect(updates.map(\.gameId) == [Game.ID("2cca74a3-7639-4f3b-a27c-7591d0be1838")])
        #expect(updates[0].latestSeq > 0 && updates[0].replay == .recorded)
    }
}

@MainActor
struct FixtureScoresFlowTests {
    @Test("In fixture mode the Scores list follows the replay: the golden game goes live and its score moves")
    func listFollowsTheReplay() async throws {
        let backend = FixtureBackend(start: Date(), scoreStep: 0.02, scoreTick: .milliseconds(100))
        let model = ScoresViewModel(dependencies: ScoresDependencies(
            leagues: backend.leagues, schedule: backend.schedule, liveScores: backend.liveScores
        ))
        await model.run()
        let task = Task { await model.run() }
        defer { task.cancel() }
        var seen: [String] = []
        for _ in 0..<100 {
            try await Task.sleep(for: .milliseconds(50))
            if case .loaded(let content) = model.state, let card = content.cards.first {
                seen.append("\(card.game.status) \(card.statusText) \(card.game.score.home)-\(card.game.score.away)")
                if card.showsScore, card.game.score.home > 0 { break }
            }
        }
        #expect(seen.last?.contains("inProgress") == true, "\(seen)")
    }
}
