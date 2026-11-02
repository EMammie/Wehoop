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
            seq: state.lastSeq
        )
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
