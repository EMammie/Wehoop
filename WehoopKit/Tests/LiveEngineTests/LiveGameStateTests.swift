import Contracts
import Foundation
import Testing
@testable import LiveEngine
import TestSupport

/// The reducer on the golden streams: folding every change from the pre-game state
/// reproduces the final snapshot's durable state (decoded-equal), in all four games.
struct LiveGameStateTests {
    private struct Fold {
        let folded: LiveGameState
        let final: Snapshot
        let changes: [GameChange]
    }

    private func fold(_ game: GoldenGame) throws -> Fold {
        let final = try Golden.snapshot(game)
        let changes = try Golden.changes(game)
        var state = LiveGameState(snapshot: Golden.pregameSnapshot(of: final))
        for change in changes {
            #expect(state.apply(change) == .applied, "\(game) seq \(change.seq)")
        }
        return Fold(folded: state, final: final, changes: changes)
    }

    @Test("Folding the whole stream onto the pre-game state equals the final snapshot", arguments: GoldenGame.allCases)
    func foldEqualsSnapshot(game: GoldenGame) throws {
        let result = try fold(game)
        let (folded, final, changes) = (result.folded, result.final, result.changes)
        let expected = LiveGameState(snapshot: final)
        #expect(folded.lastSeq == changes.count && folded.lastSeq == final.seq)
        #expect(folded.game.status == expected.game.status)
        #expect(folded.game.score == expected.game.score)
        #expect(folded.game.period == expected.game.period)
        #expect(folded.game.elamTargetScore == expected.game.elamTargetScore)
        #expect(folded.game.periods == expected.game.periods)
        #expect(folded.game.teamStats == expected.game.teamStats)
        #expect(folded.game.playerStats == expected.game.playerStats)
        #expect(folded.game.eventsById == expected.game.eventsById)
        #expect(folded.game == expected.game) // the whole durable state at once
        #expect(folded.unknownChanges == 0)
    }

    @Test("Folded events sort into the snapshot's order with the provider key; arrival order does not (WNBA)")
    func eventOrder() throws {
        let result = try fold(.wnba)
        let (folded, final, changes) = (result.folded, result.final, result.changes)
        #expect(folded.game.events.map(\.providerEventId) == final.events.map(\.providerEventId))
        var arrival: [String] = []
        for change in changes {
            if case .eventInsert(let insert) = change.type, !arrival.contains(insert.providerEventId) {
                arrival.append(insert.providerEventId)
            }
        }
        let current = Set(final.events.map(\.providerEventId))
        #expect(arrival.filter(current.contains) != final.events.map(\.providerEventId))
    }

    @Test("A repeated change is a duplicate and a skipped one a gap; neither changes the state")
    func duplicateAndGap() throws {
        let final = try Golden.snapshot(.wnba)
        let changes = try Golden.changes(.wnba)
        var state = LiveGameState(snapshot: Golden.pregameSnapshot(of: final))
        state.apply(changes[0])
        state.apply(changes[1])
        let before = state
        #expect(state.apply(changes[1]) == .duplicate)
        #expect(state.apply(changes[0]) == .duplicate)
        #expect(state.apply(changes[3]) == .gap(expected: 3, received: 4))
        #expect(state == before)
        #expect(state.apply(changes[2]) == .applied && state.lastSeq == 3)
    }

    @Test("The replay label is identity: a snapshot sets it and folding every change keeps it")
    func replayLabel() throws {
        let final = try Golden.snapshot(.wnba)
        #expect(LiveGameState(snapshot: final).game.identity.replay == nil)
        let labelled = try Golden.labelled(final, replay: .recorded, at: ["game"])
        var state = LiveGameState(snapshot: Golden.pregameSnapshot(of: labelled))
        #expect(state.game.identity.replay == .recorded)
        for change in try Golden.changes(.wnba) { _ = state.apply(change) }
        #expect(state.game.identity.replay == .recorded)
        let synthetic = try Golden.labelled(final, replay: .synthetic, at: ["game"])
        #expect(LiveGameState(snapshot: synthetic).game.identity.replay == .synthetic)
    }

    @Test("A change of another game is ignored")
    func foreignGame() throws {
        let final = try Golden.snapshot(.wnba)
        let other = try Golden.changes(.ncaawb)[0]
        var state = LiveGameState(snapshot: Golden.pregameSnapshot(of: final))
        #expect(state.apply(other) == .foreignGame && state.lastSeq == 0)
    }

    @Test("A change of a type this build does not know advances seq and nothing else")
    func unknownChangeAdvancesSeq() throws {
        let final = try Golden.snapshot(.wnba)
        var state = LiveGameState(snapshot: Golden.pregameSnapshot(of: final))
        let json = """
        {"v":1,"id":"11111111-1111-4111-8111-111111111111","gameId":"\(final.game.id)","seq":1,\
        "ts":"2026-06-30T23:16:34Z","type":"stats_arena","body":{"anything":true}}
        """
        let change = try JSONDecoder().decode(GameChange.self, from: Data(json.utf8))
        let before = state.game
        #expect(state.apply(change) == .applied)
        #expect(state.lastSeq == 1 && state.unknownChanges == 1 && state.game == before)
    }

    @Test("A deletion removes the play; an update replaces body and position")
    func deleteAndUpdate() throws {
        let result = try fold(.wnba)
        let (folded, changes) = (result.folded, result.changes)
        let deleted = changes.compactMap { change -> String? in
            if case .eventDelete(let delete) = change.type { return delete.providerEventId }
            return nil
        }
        #expect(deleted.count == 2)
        #expect(deleted.allSatisfy { folded.game.eventsById[$0] == nil })
        let lastUpdate = changes.last { if case .eventUpdate = $0.type { true } else { false } }
        guard case .eventUpdate(let update)? = lastUpdate?.type else {
            Issue.record("the WNBA stream has event updates")
            return
        }
        let stored = folded.game.eventsById[update.providerEventId]
        #expect(stored?.body == update.body && stored?.providerSequence == update.providerSequence)
    }

    @Test("Pulses: the newest observation wins, an older or equal one is stale, and latestSeq ahead is reported")
    func pulses() throws {
        let final = try Golden.snapshot(.wnba)
        let pulse = try Golden.pulse(.wnba)
        var state = LiveGameState(snapshot: Golden.pregameSnapshot(of: final))
        let before = state.game
        #expect(state.apply(pulse) == PulseOutcome(applied: true, behind: true))
        #expect(state.clock.clock == pulse.clock && state.clock.running == pulse.clockRunning)
        #expect(state.game == before) // a pulse never touches score, period or status
        #expect(state.apply(pulse) == PulseOutcome(applied: false, behind: true))

        var caughtUp = LiveGameState(snapshot: final)
        #expect(caughtUp.apply(pulse) == PulseOutcome(applied: false, behind: false)) // same observedAt as the snapshot
    }

    @Test("A status change without an Elam target keeps the stored one (the backend omits it, never nulls it)")
    func elamTargetKept() throws {
        let result = try fold(.unrivaledElam)
        let (folded, final) = (result.folded, result.final)
        #expect(folded.game.elamTargetScore == 84 && final.game.elamTargetScore == 84)
        #expect(folded.game.periods.contains { $0.type == .elam })
    }
}
