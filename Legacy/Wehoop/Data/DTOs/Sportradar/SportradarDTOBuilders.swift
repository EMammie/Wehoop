//
//  SportradarDTOBuilders.swift
//  WehoopTests
//
//  Created for testing purposes
//

import Foundation

// MARK: - Test Builders for Sportradar DTOs
// These builders provide a fluent API for creating test data with sensible defaults

/// Builder for SportradarLeagueLeadersDTO
/// 
/// Example usage:
/// ```swift
/// let leaders = SportradarLeagueLeadersBuilder()
///     .withSeason(year: 2025, type: "REG")
///     .addCategory("points") { category in
///         category.addLeader(rank: 1, score: 25.5) { leader in
///             leader.withPlayer(id: "player-1", fullName: "Top Scorer")
///         }
///     }
///     .build()
/// ```
@MainActor
class SportradarLeagueLeadersBuilder {
    private var season: SportradarSeasonDTO?
    private var id: String?
    private var name: String?
    private var alias: String?
    private var type: String?
    private var categories: [SportradarLeagueLeadersDTO.SportradarLeaderCategoryDTO] = []
    
    init() {
        // Set sensible defaults
        self.id = "league-123"
        self.name = "Unrivaled"
        self.alias = "UNRIVALED"
    }
    
    @discardableResult
    func withSeason(year: Int = 2025, type: String = "REG", id: String? = nil) -> Self {
        self.season = SportradarSeasonDTO(
            id: id ?? "season-\(year)",
            year: year,
            type: type,
            name: name
        )
        return self
    }
    
    @discardableResult
    func withLeagueInfo(id: String, name: String, alias: String) -> Self {
        self.id = id
        self.name = name
        self.alias = alias
        return self
    }
    
    @discardableResult
    func addCategory(
        _ name: String,
        type: String? = nil,
        configure: (SportradarLeaderCategoryBuilder) -> Void = { _ in }
    ) -> Self {
        let builder = SportradarLeaderCategoryBuilder(name: name, type: type)
        configure(builder)
        categories.append(builder.build())
        return self
    }
    
    func build() -> SportradarLeagueLeadersDTO {
        SportradarLeagueLeadersDTO(
            season: season,
            id: id,
            name: name,
            alias: alias,
            type: type,
            categories: categories.isEmpty ? nil : categories
        )
    }
}

/// Builder for SportradarLeaderCategoryDTO
@MainActor
class SportradarLeaderCategoryBuilder {
    private let name: String
    private let type: String?
    private var ranks: [SportradarLeagueLeadersDTO.SportradarLeaderRankDTO] = []
    
    init(name: String, type: String? = nil) {
        self.name = name
        self.type = type
    }
    
    @discardableResult
    func addLeader(
        rank: Int = 1,
        score: Double,
        tied: Bool = false,
        configure: (SportradarLeaderRankBuilder) -> Void = { _ in }
    ) -> Self {
        let builder = SportradarLeaderRankBuilder(rank: rank, score: score, tied: tied)
        configure(builder)
        ranks.append(builder.build())
        return self
    }
    
    func build() -> SportradarLeagueLeadersDTO.SportradarLeaderCategoryDTO {
        SportradarLeagueLeadersDTO.SportradarLeaderCategoryDTO(
            name: name,
            type: type,
            ranks: ranks.isEmpty ? nil : ranks
        )
    }
}

/// Builder for SportradarLeaderRankDTO
@MainActor
class SportradarLeaderRankBuilder {
    private let rank: Int
    private let score: Double
    private let tied: Bool
    private var player: SportradarLeagueLeadersDTO.SportradarLeaderPlayerDTO?
    private var teams: [SportradarLeagueLeadersDTO.SportradarLeaderTeamDTO] = []
    private var total: SportradarLeagueLeadersDTO.SportradarLeaderStatisticsDTO?
    private var average: SportradarLeagueLeadersDTO.SportradarLeaderAverageDTO?
    
    init(rank: Int, score: Double, tied: Bool = false) {
        self.rank = rank
        self.score = score
        self.tied = tied
    }
    
    @discardableResult
    func withPlayer(
        id: String,
        fullName: String,
        firstName: String? = nil,
        lastName: String? = nil,
        position: String = "G",
        primaryPosition: String? = nil,
        jerseyNumber: String = "0"
    ) -> Self {
        self.player = SportradarLeagueLeadersDTO.SportradarLeaderPlayerDTO(
            id: id,
            fullName: fullName,
            firstName: firstName ?? fullName.split(separator: " ").first.map(String.init),
            lastName: lastName ?? fullName.split(separator: " ").last.map(String.init),
            position: position,
            primaryPosition: primaryPosition,
            jerseyNumber: jerseyNumber
        )
        return self
    }
    
    @discardableResult
    func addTeam(id: String, name: String) -> Self {
        teams.append(SportradarLeagueLeadersDTO.SportradarLeaderTeamDTO(
            id: id,
            name: name
        ))
        return self
    }
    
    @discardableResult
    func withStatistics(
        gamesPlayed: Int? = nil,
        points: Int? = nil,
        rebounds: Int? = nil,
        assists: Int? = nil
    ) -> Self {
        self.total = SportradarLeagueLeadersDTO.SportradarLeaderStatisticsDTO(
            gamesPlayed: gamesPlayed,
            gamesStarted: nil,
            minutes: nil,
            fieldGoalsMade: nil,
            fieldGoalsAtt: nil,
            fieldGoalsPct: nil,
            twoPointsMade: nil,
            twoPointsAtt: nil,
            twoPointsPct: nil,
            threePointsMade: nil,
            threePointsAtt: nil,
            threePointsPct: nil,
            blockedAtt: nil,
            freeThrowsMade: nil,
            freeThrowsAtt: nil,
            freeThrowsPct: nil,
            offensiveRebounds: nil,
            defensiveRebounds: nil,
            rebounds: rebounds,
            assists: assists,
            turnovers: nil,
            assistsTurnoverRatio: nil,
            steals: nil,
            blocks: nil,
            personalFouls: nil,
            techFouls: nil,
            points: points,
            flagrantFouls: nil,
            ejections: nil,
            foulouts: nil,
            techFoulsNonUnsportsmanlike: nil,
            trueShootingAtt: nil,
            trueShootingPct: nil,
            efficiency: nil,
            fieldGoalsAtRimMade: nil,
            fieldGoalsAtRimAtt: nil,
            fieldGoalsAtMidrangeMade: nil,
            fieldGoalsAtMidrangeAtt: nil,
            awardedPoints: nil,
            coachEjections: nil,
            coachTechFouls: nil,
            doubleDoubles: nil,
            effectiveFgPct: nil,
            fastBreakAtt: nil,
            fastBreakMade: nil,
            fastBreakPct: nil,
            fastBreakPts: nil,
            foulsDrawn: nil,
            freeThrowPoints: nil,
            minus: nil,
            offensiveFouls: nil,
            plus: nil,
            pointsInPaint: nil,
            pointsInPaintAtt: nil,
            pointsInPaintMade: nil,
            pointsInPaintPct: nil,
            pointsOffTurnovers: nil,
            secondChanceAtt: nil,
            secondChanceMade: nil,
            secondChancePct: nil,
            secondChancePts: nil,
            tripleDoubles: nil,
            winningBaskets: nil
        )
        return self
    }
    
    @discardableResult
    func withAverages(
        points: Double? = nil,
        rebounds: Double? = nil,
        assists: Double? = nil
    ) -> Self {
        self.average = SportradarLeagueLeadersDTO.SportradarLeaderAverageDTO(
            minutes: nil,
            points: points,
            offRebounds: nil,
            defRebounds: nil,
            rebounds: rebounds,
            assists: assists,
            steals: nil,
            blocks: nil,
            turnovers: nil,
            personalFouls: nil,
            flagrantFouls: nil,
            blockedAtt: nil,
            fieldGoalsMade: nil,
            fieldGoalsAtt: nil,
            threePointsMade: nil,
            threePointsAtt: nil,
            freeThrowsMade: nil,
            freeThrowsAtt: nil,
            twoPointsMade: nil,
            twoPointsAtt: nil,
            efficiency: nil,
            trueShootingAtt: nil,
            fastBreakAtt: nil,
            fastBreakMade: nil,
            fastBreakPts: nil,
            foulsDrawn: nil,
            offensiveFouls: nil,
            pointsInPaint: nil,
            pointsInPaintAtt: nil,
            pointsInPaintMade: nil,
            pointsOffTurnovers: nil,
            secondChanceAtt: nil,
            secondChanceMade: nil,
            secondChancePts: nil
        )
        return self
    }
    
    func build() -> SportradarLeagueLeadersDTO.SportradarLeaderRankDTO {
        SportradarLeagueLeadersDTO.SportradarLeaderRankDTO(
            rank: rank,
            tied: tied,
            score: score,
            player: player,
            teams: teams.isEmpty ? nil : teams,
            total: total,
            average: average
        )
    }
}

// MARK: - Additional Builders

/// Builder for SportradarTeamsResponseDTO
@MainActor
class SportradarTeamsResponseBuilder {
    private var league: SportradarLeagueDTO?
    private var teams: [SportradarTeamDTO] = []
    private var comment: String?
    
    init() {
        self.league = SportradarLeagueDTO(
            id: "league-123",
            name: "Unrivaled",
            alias: "UNRIVALED"
        )
    }
    
    @discardableResult
    func withLeague(id: String, name: String, alias: String) -> Self {
        self.league = SportradarLeagueDTO(id: id, name: name, alias: alias)
        return self
    }
    
    @discardableResult
    func addTeam(
        id: String,
        name: String,
        alias: String,
        market: String? = nil,
        wins: Int? = nil,
        losses: Int? = nil
    ) -> Self {
        teams.append(SportradarTeamDTO(
            id: id,
            name: name,
            alias: alias,
            market: market,
            conference: nil,
            division: nil,
            wins: wins,
            losses: losses,
            winPercentage: nil,
            logo: nil,
            founded: nil,
            venue: nil
        ))
        return self
    }
    
    @discardableResult
    func withComment(_ comment: String) -> Self {
        self.comment = comment
        return self
    }
    
    func build() -> SportradarTeamsResponseDTO {
        SportradarTeamsResponseDTO(
            league: league,
            teams: teams,
            comment: comment
        )
    }
}

// MARK: - Convenience Extensions for Common Test Scenarios

extension SportradarLeagueLeadersBuilder {
    /// Creates a simple points leader response with one leader
    static func simplePointsLeader(
        playerId: String = "player-1",
        playerName: String = "Top Scorer",
        score: Double = 25.5
    ) -> SportradarLeagueLeadersDTO {
        SportradarLeagueLeadersBuilder()
            .addCategory("points") { category in
                category.addLeader(rank: 1, score: score) { leader in
                    leader
                        .withPlayer(id: playerId, fullName: playerName)
                        .addTeam(id: "team-1", name: "Test Team")
                }
            }
            .build()
    }
    
    /// Creates an empty response (no categories)
    static func empty() -> SportradarLeagueLeadersDTO {
        SportradarLeagueLeadersBuilder().build()
    }
    
    /// Creates a response with empty categories
    static func emptyCategories() -> SportradarLeagueLeadersDTO {
        SportradarLeagueLeadersBuilder()
            .addCategory("points")
            .build()
    }
}
