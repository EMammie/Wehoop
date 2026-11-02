import Contracts
import Domain
import Foundation
import LiveEngine

/// The one place Contracts' wire values become Domain values (and plain string ids become
/// typed ids). Features never see a Contracts type.
enum Mapping {
    // One case per backend status; splitting the switch would hide the one-to-one mapping.
    // swiftlint:disable:next cyclomatic_complexity
    static func status(_ status: Contracts.GameStatus) -> Domain.GameStatus {
        switch status {
        case .scheduled: .scheduled
        case .created: .created
        case .timeTbd: .timeTBD
        case .ifNecessary: .ifNecessary
        case .inprogress: .inProgress
        case .halftime: .halftime
        case .delayed: .delayed
        case .complete: .complete
        case .closed: .closed
        case .cancelled: .cancelled
        case .postponed: .postponed
        case .unnecessary: .unnecessary
        case .unknown(let raw): .unknown(raw)
        }
    }

    static func coverage(_ coverage: CoverageLevel) -> Coverage {
        switch coverage {
        case .full: .full
        case .extendedBoxscore: .extendedBoxscore
        case .boxscore: .boxscore
        case .unknown(let raw): .unknown(raw)
        }
    }

    static func coverage(raw: String) -> Coverage { coverage(CoverageLevel(rawValue: raw)) }

    static func periodKind(_ type: PeriodType) -> PeriodKind {
        switch type {
        case .quarter: .quarter
        case .half: .half
        case .overtime: .overtime
        case .elam: .elam
        case .unknown(let raw): .unknown(raw)
        }
    }

    static func league(_ row: LeagueRow) -> League {
        League(code: League.Code(row.code.rawValue), name: row.name, shortName: row.shortName, colors: colors(row.colors))
    }

    static func colors(_ json: [String: JSONValue]?) -> League.Colors? {
        guard let json, case .string(let primary)? = json["primary"] else { return nil }
        if case .string(let secondary)? = json["secondary"] { return League.Colors(primary: primary, secondary: secondary) }
        return League.Colors(primary: primary, secondary: nil)
    }

    /// A `v_schedule` row; nil when its `scheduled_at` does not parse (never shown at a guessed time).
    static func game(_ row: ScheduleRow) -> Game? {
        guard let scheduledAt = ISODate.parse(row.scheduledAt) else { return nil }
        let period = row.currentPeriod.map {
            GamePeriod(number: $0, kind: row.periodType.map(periodKind), sequence: row.currentPeriodSequence)
        }
        return Game(
            id: Game.ID(row.id),
            league: League.Code(row.league.rawValue),
            scheduledAt: scheduledAt,
            status: status(row.status),
            coverage: coverage(row.coverage),
            home: Game.Side(teamId: row.homeTeamId.map { Team.ID($0) }, name: row.homeName, market: row.homeMarket, alias: row.homeAlias),
            away: Game.Side(teamId: row.awayTeamId.map { Team.ID($0) }, name: row.awayName, market: row.awayMarket, alias: row.awayAlias),
            score: Domain.Score(home: row.homePoints, away: row.awayPoints),
            period: period,
            elamTargetScore: row.elamTargetScore,
            clock: GameClock(
                remaining: (row.clockDecimal ?? row.clock).flatMap(ClockModel.seconds),
                running: row.clockRunning,
                asOf: row.clockAsOf.flatMap(ISODate.parse)
            ),
            title: row.title,
            tournamentName: row.tournamentName,
            seasonYear: row.seasonYear,
            lastSeq: row.lastSeq
        )
    }

    static func player(_ response: PlayerResponse) -> PlayerSummary {
        let p = response.player
        return PlayerSummary(
            id: PlayerSummary.ID(p.id),
            fullName: p.fullName,
            position: p.position,
            jersey: p.jersey,
            headshotURL: p.headshotUrl,
            externalIds: response.externalIds.map {
                PlayerSummary.ExternalId(provider: $0.provider, league: League.Code($0.league.rawValue), value: $0.externalId)
            },
            mergedIds: response.mergedIds.map { PlayerSummary.ID($0) }
        )
    }

    /// The live header of a folded game. `serverOffset` (server minus local seconds) moves
    /// the clock's `asOf` onto this device's clock.
    static func liveGame(_ state: LiveGameState, serverOffset: TimeInterval) -> LiveGame {
        let g = state.game
        let model = state.clockModel(serverOffset: serverOffset)
        return LiveGame(
            id: Game.ID(g.identity.id),
            league: League.Code(g.identity.league),
            status: status(g.status),
            coverage: coverage(raw: g.identity.coverage),
            score: Domain.Score(home: g.score.home, away: g.score.away),
            period: g.period.map { GamePeriod(number: $0.number, kind: periodKind($0.type), sequence: $0.sequence) },
            elamTargetScore: g.elamTargetScore,
            clock: GameClock(remaining: model.base, running: model.running, asOf: model.asOf?.addingTimeInterval(-serverOffset)),
            seq: state.lastSeq,
            detail: detail(g)
        )
    }

    // MARK: Game detail

    static func detail(_ g: GameState) -> GameDetail {
        // Stats bodies say which provider team is home; plays and player lines take their side from it.
        let sides = Dictionary(g.teamStats.values.map { ($0.providerTeamId, $0.isHome ? TeamSide.home : .away) }) { first, _ in first }
        let names = g.playerStats.mapValues(\.fullName)
        return GameDetail(
            periods: g.periods.map {
                PeriodLine(
                    period: GamePeriod(number: $0.number, kind: periodKind($0.type), sequence: $0.sequence),
                    score: Domain.Score(home: $0.score.home, away: $0.score.away)
                )
            },
            plays: g.events.map { play($0, sides: sides, names: names) },
            teamLines: g.teamStats.values
                .map { TeamBoxLine(side: $0.isHome ? .home : .away, stats: box($0.stats)) }
                .sorted { $0.side == .away && $1.side == .home },
            playerLines: g.playerStats.values
                .map { player($0, side: sides[$0.providerTeamId]) }
                .sorted(by: playerOrder)
        )
    }

    static func play(_ event: GameState.Event, sides: [String: TeamSide], names: [String: String]) -> Play {
        let body = event.body
        return Play(
            id: event.providerEventId,
            period: GamePeriod(number: body.period.number, kind: periodKind(body.period.type), sequence: body.period.sequence),
            clock: body.clock,
            kind: playKind(body.type),
            side: body.providerTeamId.flatMap { sides[$0] },
            playerName: body.providerPlayerId.flatMap { names[$0] },
            description: body.description,
            score: Domain.Score(home: body.score.home, away: body.score.away)
        )
    }

    // One case per generated event kind: the switch is a table, not branching logic.
    // swiftlint:disable:next cyclomatic_complexity
    static func playKind(_ kind: LiveEvent.Kind) -> Play.Kind {
        switch kind {
        case .tipOff: .tipOff
        case .shot(let shot): .shot(made: shot.made, points: shot.points)
        case .freeThrow(let freeThrow): .freeThrow(made: freeThrow.made)
        case .rebound: .rebound
        case .turnover: .turnover
        case .foul: .foul
        case .timeout: .timeout
        case .lineupChange: .substitution
        case .periodStart: .periodStart
        case .periodEnd: .periodEnd
        case .gameStatus: .gameStatus
        case .elamTargetSet(let target): .elamTarget(target.target)
        case .awardedPoint(let award): .awardedPoint(award.points)
        case .review: .review
        case .other, .unknown: .other
        }
    }

    static func player(_ line: StatsPlayerBody, side: TeamSide?) -> PlayerBoxLine {
        PlayerBoxLine(
            id: line.providerPlayerId, side: side, name: line.fullName, jersey: line.jersey,
            position: line.position, starter: line.starter ?? false, played: line.played,
            notPlayingReason: line.notPlayingReason, stats: box(line.stats)
        )
    }

    static func box(_ stats: TeamStats) -> BoxStats {
        var box = BoxStats()
        box.points = stats.points
        box.fieldGoalsMade = stats.fgm
        box.fieldGoalsAttempted = stats.fga
        box.threesMade = stats.tpm
        box.threesAttempted = stats.tpa
        box.freeThrowsMade = stats.ftm
        box.freeThrowsAttempted = stats.fta
        box.offensiveRebounds = stats.offRebounds
        box.defensiveRebounds = stats.defRebounds
        box.rebounds = stats.rebounds
        box.assists = stats.assists
        box.steals = stats.steals
        box.blocks = stats.blocks
        box.turnovers = stats.turnovers
        box.fouls = stats.personalFouls
        return box
    }

    static func box(_ stats: PlayerStats) -> BoxStats {
        var box = BoxStats()
        box.minutes = stats.minutes
        box.points = stats.points
        box.fieldGoalsMade = stats.fgm
        box.fieldGoalsAttempted = stats.fga
        box.threesMade = stats.tpm
        box.threesAttempted = stats.tpa
        box.freeThrowsMade = stats.ftm
        box.freeThrowsAttempted = stats.fta
        box.offensiveRebounds = stats.offRebounds
        box.defensiveRebounds = stats.defRebounds
        box.rebounds = stats.rebounds
        box.assists = stats.assists
        box.steals = stats.steals
        box.blocks = stats.blocks
        box.turnovers = stats.turnovers
        box.fouls = stats.personalFouls
        box.plusMinus = stats.plusMinus
        return box
    }

    /// Away before home, starters first, then by minutes played, then by name.
    static func playerOrder(_ lhs: PlayerBoxLine, _ rhs: PlayerBoxLine) -> Bool {
        let order: (PlayerBoxLine) -> Int = { $0.side == .away ? 0 : $0.side == .home ? 1 : 2 }
        if order(lhs) != order(rhs) { return order(lhs) < order(rhs) }
        if lhs.starter != rhs.starter { return lhs.starter }
        let lhsMinutes = lhs.stats.minutes.flatMap(ClockModel.seconds) ?? 0
        let rhsMinutes = rhs.stats.minutes.flatMap(ClockModel.seconds) ?? 0
        if lhsMinutes != rhsMinutes { return lhsMinutes > rhsMinutes }
        return (lhs.name, lhs.id) < (rhs.name, rhs.id)
    }

    static func cause(_ cause: SyncUpdate.Cause) -> LiveGameUpdate.Cause {
        switch cause {
        case .snapshot, .resnapshot: .snapshot
        case .change, .catchUp: .change
        case .pulse: .clock
        case .finalSnapshot: .final
        }
    }
}
