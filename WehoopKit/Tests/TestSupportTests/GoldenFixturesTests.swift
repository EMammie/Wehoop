import Contracts
import Foundation
import Testing
@testable import TestSupport

/// M5 S1 acceptance: every golden file the backend captured decodes through the
/// generated Contracts types (and survives encode → decode), and what the files
/// say about each other holds: contiguous pages, snapshot and pulse at the same
/// seq, every code known, the Elam target, Boston across three leagues.
struct GoldenFixturesTests {
    private static let leagues: [LeagueCode] = [.wnba, .ncaawb, .unrivaled]

    private func roundTrips<T: Codable & Equatable>(_ value: T) throws -> Bool {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value)) == value
    }

    @Test("Every manifest entry decodes as its contract type and survives a round trip")
    func everyEntryDecodes() throws { // swiftlint:disable:this cyclomatic_complexity
        let manifest = try Golden.manifest()
        #expect(manifest.generator == "pnpm golden")
        #expect(manifest.games.count == GoldenGame.allCases.count)
        var checked = 0

        func check<T: Codable & Equatable>(_ type: T.Type, _ entry: GoldenManifest.Entry) throws {
            if entry.array {
                let rows: [T] = try Golden.decode(entry.file)
                #expect(!rows.isEmpty, "\(entry.file) is empty")
                #expect(try roundTrips(rows), "\(entry.file)")
            } else {
                let value: T = try Golden.decode(entry.file)
                #expect(try roundTrips(value), "\(entry.file)")
            }
            checked += 1
        }

        for entry in manifest.entries {
            switch entry.type {
            case "LeagueRow": try check(LeagueRow.self, entry)
            case "ScheduleRow": try check(ScheduleRow.self, entry)
            case "StandingsRow": try check(StandingsRow.self, entry)
            case "PlayerSeasonRow": try check(PlayerSeasonRow.self, entry)
            case "LeadersRow": try check(LeadersRow.self, entry)
            case "BoxscoreRow": try check(BoxscoreRow.self, entry)
            case "Scoreboard": try check(Scoreboard.self, entry)
            case "Snapshot": try check(Snapshot.self, entry)
            case "ChangesPage": try check(ChangesPage.self, entry)
            case "Pulse": try check(Pulse.self, entry)
            case "PlayerResponse": try check(PlayerResponse.self, entry)
            default: Issue.record("\(entry.file): contract type \(entry.type) unknown to this test")
            }
        }
        #expect(checked == manifest.entries.count)
        #expect(checked >= 42)
    }

    @Test("Nothing in the goldens decodes to an .unknown case: the Swift knows every code the backend emitted")
    func nothingUnknown() throws { // swiftlint:disable:this cyclomatic_complexity
        func known(_ event: LiveEvent, _ place: String) {
            if case .unknown(let raw) = event.type { Issue.record("\(place): event type \(raw)") }
            if case .unknown(let raw) = event.period.type { Issue.record("\(place): period type \(raw)") }
        }
        for game in GoldenGame.allCases {
            for change in try Golden.changes(game) {
                let at = "\(game) seq \(change.seq)"
                switch change.type {
                case .unknown(let raw): Issue.record("\(at): change type \(raw)")
                case .eventInsert(let insert): known(insert.body, at)
                case .eventUpdate(let update): known(update.body, at)
                default: break
                }
            }
            let snapshot = try Golden.snapshot(game)
            for event in snapshot.events { known(event.body, "\(game) snapshot \(event.providerEventId)") }
            for period in snapshot.periods where period.type.rawValue != period.type.rawValue.lowercased() {
                Issue.record("\(game): period type \(period.type.rawValue)")
            }
            if case .unknown(let raw) = snapshot.game.status { Issue.record("\(game): status \(raw)") }
            let pulse = try Golden.pulse(game)
            if case .unknown(let raw) = pulse.status { Issue.record("\(game): pulse status \(raw)") }
        }
        for league in Self.leagues {
            for row in try Golden.schedule(league) {
                if case .unknown(let raw) = row.league { Issue.record("\(league) schedule: league \(raw)") }
                if case .unknown(let raw) = row.status { Issue.record("\(league) schedule: status \(raw)") }
                if case .unknown(let raw) = row.coverage { Issue.record("\(league) schedule: coverage \(raw)") }
                if let type = row.seasonType, case .unknown(let raw) = type { Issue.record("\(league) schedule: season type \(raw)") }
            }
            for row in try Golden.leaders(league) {
                if case .unknown(let raw) = row.category { Issue.record("\(league) leaders: category \(raw)") }
            }
            let scoreboard = try Golden.scoreboard(league)
            for delta in scoreboard.deltas {
                if case .unknown(let raw) = delta.status { Issue.record("\(league) scoreboard: status \(raw)") }
            }
        }
    }

    @Test("The pages of each game are contiguous from seq 1 and end where the snapshot and the pulse say", arguments: GoldenGame.allCases)
    func pagesAgree(game: GoldenGame) throws {
        let pages = try Golden.changesPages(game)
        let changes = pages.flatMap(\.changes)
        #expect(changes.map(\.seq) == Array(1...changes.count))
        #expect(Set(changes.map(\.id)).count == changes.count)
        for page in pages.dropLast() { #expect(page.hasMore && page.changes.count == 500) }
        let last = try #require(pages.last)
        #expect(!last.hasMore && last.latestSeq == changes.count && last.retainedFrom == 1)

        let tail = try Golden.tailPage(game)
        #expect(tail.changes.isEmpty && !tail.hasMore && tail.latestSeq == changes.count)

        let snapshot = try Golden.snapshot(game)
        let pulse = try Golden.pulse(game)
        #expect(snapshot.seq == changes.count && pulse.latestSeq == changes.count)
        #expect(snapshot.game.status == .closed && pulse.status == .closed)
        #expect(snapshot.coverage == game.coverage.rawValue)
        let boxscore = try Golden.boxscore(game)
        #expect(boxscore.count == snapshot.playerStats.count)
        #expect(snapshot.game.league == game.league.rawValue)
    }

    @Test("WNBA carries every change type; the extended game carries no events and still has final stats")
    func coverage() throws {
        let wnba = try Golden.changes(.wnba)
        let wnbaTypes = Set(wnba.map(\.type.rawValue))
        #expect(wnbaTypes == Set(ChangeType.known.map(\.rawValue)))

        let extended = try Golden.changes(.ncaawbExtended)
        #expect(Set(extended.map(\.type.rawValue)).isSubset(of: ["status", "period", "stats_team", "stats_player"]))
        let extendedSnapshot = try Golden.snapshot(.ncaawbExtended)
        #expect(extendedSnapshot.events.isEmpty && !extendedSnapshot.playerStats.isEmpty)

        let full = try Golden.snapshot(.ncaawb)
        #expect(full.events.count > 300 && full.game.score == extendedSnapshot.game.score)
        let schedule = try Golden.schedule(.ncaawb)
        #expect(schedule.contains { $0.providerGameId.hasPrefix("e5e5e5e5") && $0.coverage == .extendedBoxscore })
        #expect(schedule.contains { $0.providerGameId.hasPrefix("2e36b340") && $0.coverage == .full })
    }

    @Test("The Unrivaled game carries an Elam period, its target and no clock")
    func elam() throws {
        let snapshot = try Golden.snapshot(.unrivaledElam)
        #expect(snapshot.game.elamTargetScore == 84)
        #expect(snapshot.periods.contains { $0.type == .elam })
        #expect(snapshot.game.score == Score(home: 80, away: 84))
        #expect(snapshot.game.clock == nil && snapshot.game.clockRunning != true)
        let pulse = try Golden.pulse(.unrivaledElam)
        #expect(pulse.clockRunning != true)
    }

    @Test("Boston's response links three leagues; the leagues rows carry the switch data; leaders rank from 1 per category")
    func referenceData() throws {
        let boston = try Golden.player(.boston)
        #expect(boston.player.fullName == "Aliyah Boston")
        #expect(Set(boston.externalIds.map(\.league)) == [.wnba, .ncaawb, .unrivaled])
        let stuelke = try Golden.player(.stuelke)
        let collier = try Golden.player(.collier)
        #expect(Set(stuelke.externalIds.map(\.league)) == [.ncaawb])
        #expect(Set(collier.externalIds.map(\.league)).contains(.unrivaled))

        let leagues = try Golden.leagues()
        #expect(Set(leagues.map(\.code)) == [.wnba, .ncaawb, .unrivaled])
        #expect(leagues.allSatisfy { !$0.shortName.isEmpty && $0.colors?["primary"] != nil })

        for league in Self.leagues {
            let rows = try Golden.leaders(league)
            let categories = Set(rows.map(\.category))
            #expect(categories.count == LeaderCategory.known.count, "\(league)")
            for category in categories {
                let ranks = rows.filter { $0.category == category }.map(\.rank)
                #expect(ranks.first == 1 && ranks == ranks.sorted(), "\(league) \(category)")
            }
            let standings = try Golden.standings(league)
            let seasons = try Golden.playerSeasons(league)
            #expect(standings.allSatisfy { $0.league == league } && seasons.allSatisfy { $0.league == league })
            let scoreboard = try Golden.scoreboard(league)
            let schedule = try Golden.schedule(league)
            #expect(scoreboard.league == league && scoreboard.deltas.count == schedule.count)
        }
    }
}
