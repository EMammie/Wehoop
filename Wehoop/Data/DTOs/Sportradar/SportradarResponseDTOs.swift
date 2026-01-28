//
//  SportradarResponseDTOs.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

// MARK: - Sportradar Response DTOs
// These DTOs match the actual Sportradar API JSON structure
// They will be mapped to existing app DTOs (TeamDTO, PlayerDTO, GameDTO)

/// Sportradar Teams Response - matches actual API structure
struct SportradarTeamsResponseDTO: Codable {
    let league: SportradarLeagueDTO?
    let teams: [SportradarTeamDTO]
    let comment: String?
    
    enum CodingKeys: String, CodingKey {
        case league, teams
        case comment = "_comment"
    }
}

struct SportradarLeagueDTO: Codable {
    let id: String?
    let name: String?
    let alias: String?
}

/// Sportradar Team Response - matches actual teams endpoint structure
struct SportradarTeamDTO: Codable {
    let id: String
    let name: String
    let alias: String? // Abbreviation
    let market: String? // City (optional, e.g., "Team" for TBD)
    
    // Additional fields that may appear in other endpoints (team profile, etc.)
    let conference: String?
    let division: String?
    let wins: Int?
    let losses: Int?
    let winPercentage: Double?
    let logo: String? // Logo URL
    let founded: Int?
    let venue: SportradarVenueDTO?
    
    /// Map to app TeamDTO
    func toTeamDTO() -> TeamDTO {
        TeamDTO(
            id: id,
            name: name,
            abbreviation: alias ?? name.prefix(3).uppercased(),
            logoURL: logo,
            city: market,
            conference: conference,
            division: division,
            wins: wins,
            losses: losses,
            winPercentage: winPercentage
        )
    }
}

struct SportradarVenueDTO: Codable {
    let id: String?
    let name: String?
    let city: String?
    let state: String?
    let capacity: Int?
}

// MARK: - Game Summary Mapping

extension SportradarGameSummaryDTO {
    /// Map to app GameDTO
    /// - Parameter homeTeamDTO: Home team DTO (fetched separately)
    /// - Parameter awayTeamDTO: Away team DTO (fetched separately)
    func toGameDTO(homeTeamDTO: TeamDTO, awayTeamDTO: TeamDTO) throws -> GameDTO {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let dateString = scheduled,
              let gameDate = dateFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) else {
            throw DTOMappingError.invalidDate(scheduled ?? "unknown")
        }
        
        // Map status
        var gameStatus = mapGameStatus(status ?? "scheduled")
        
        // For historical games, if status is scheduled but we have scores, it's likely finished
        // Check if game date is in the past and we have score data
        if gameStatus == .scheduled {
            let calendar = Calendar.current
            if let gameDate = dateFormatter.date(from: scheduled ?? ""), 
               gameDate < Date(),
               (home?.points ?? home?.statistics?.points ?? home?.statistics?.totalPoints ?? home?.statistics?.teamPoints ?? 0) > 0 ||
               (away?.points ?? away?.statistics?.points ?? away?.statistics?.totalPoints ?? away?.statistics?.teamPoints ?? 0) > 0 {
                // Game is in the past and has scores - it's finished
                gameStatus = .finished
            }
        }
        
        // Map boxscore from team statistics
        // For finished games, we should always have a box score if the game was played
        let boxScoreDTO: BoxScoreDTO?
        do {
            let boxScore = try toBoxScoreDTO()
            // For finished games, if scores are 0, try to extract from alternative sources
            if gameStatus == .finished && boxScore.homeScore == 0 && boxScore.awayScore == 0 {
                Logger.error("Finished game \(id) has box score with zero scores - attempting to extract from alternative sources")
                
                // Try to get scores from alternative sources
                var homeScore = home?.points ?? home?.statistics?.points ?? home?.statistics?.totalPoints ?? home?.statistics?.teamPoints
                var awayScore = away?.points ?? away?.statistics?.points ?? away?.statistics?.totalPoints ?? away?.statistics?.teamPoints
                
                // Try calculating from quarter scores
                if (homeScore == nil || homeScore == 0) || (awayScore == nil || awayScore == 0) {
                    if let homeScoring = home?.scoring, let awayScoring = away?.scoring {
                        let homeTotal = homeScoring.compactMap { $0.points }.reduce(0, +)
                        let awayTotal = awayScoring.compactMap { $0.points }.reduce(0, +)
                        if homeTotal > 0 {
                            homeScore = homeScore ?? homeTotal
                        }
                        if awayTotal > 0 {
                            awayScore = awayScore ?? awayTotal
                        }
                    }
                }
                
                // If we found scores, create a new box score with the correct scores
                if let homeScore = homeScore, let awayScore = awayScore, (homeScore > 0 || awayScore > 0) {
                    boxScoreDTO = BoxScoreDTO(
                        homeScore: homeScore,
                        awayScore: awayScore,
                        homeStats: home?.statistics?.toTeamStatsDTO(points: homeScore) ?? boxScore.homeStats,
                        awayStats: away?.statistics?.toTeamStatsDTO(points: awayScore) ?? boxScore.awayStats,
                        quarters: boxScore.quarters,
                        lastUpdated: boxScore.lastUpdated
                    )
                } else {
                    // Still return the box score even with 0 scores (finished games should always have a box score)
                    boxScoreDTO = boxScore
                }
            } else {
                boxScoreDTO = boxScore
            }
        } catch {
            // If box score mapping fails, log error but continue
            // For finished games, this is a problem; for scheduled games, it's expected
            Logger.error("Failed to map box score for game \(id): \(error.localizedDescription)")
            if gameStatus == .finished {
                // For finished games, ALWAYS try to create a box score from available data
                // This ensures finished games always have some box score data
                var homeScore = home?.points ?? home?.statistics?.points ?? home?.statistics?.totalPoints ?? home?.statistics?.teamPoints
                var awayScore = away?.points ?? away?.statistics?.points ?? away?.statistics?.totalPoints ?? away?.statistics?.teamPoints
                
                // Try to calculate from quarter scores if direct scores aren't available
                if (homeScore == nil || homeScore == 0) || (awayScore == nil || awayScore == 0) {
                    if let homeScoring = home?.scoring, let awayScoring = away?.scoring {
                        let homeTotal = homeScoring.compactMap { $0.points }.reduce(0, +)
                        let awayTotal = awayScoring.compactMap { $0.points }.reduce(0, +)
                        if homeTotal > 0 {
                            homeScore = homeScore ?? homeTotal
                        }
                        if awayTotal > 0 {
                            awayScore = awayScore ?? awayTotal
                        }
                    }
                }
                
                // For finished games, always create a box score (even if scores are 0)
                // A finished game should always have a box score
                boxScoreDTO = BoxScoreDTO(
                    homeScore: homeScore ?? 0,
                    awayScore: awayScore ?? 0,
                    homeStats: home?.statistics?.toTeamStatsDTO(points: homeScore ?? 0) ?? TeamStatsDTO(
                        points: homeScore ?? 0,
                        rebounds: 0,
                        assists: 0,
                        steals: nil,
                        blocks: nil,
                        turnovers: nil,
                        fieldGoalPercentage: nil,
                        threePointPercentage: nil,
                        freeThrowPercentage: nil,
                        fouls: nil
                    ),
                    awayStats: away?.statistics?.toTeamStatsDTO(points: awayScore ?? 0) ?? TeamStatsDTO(
                        points: awayScore ?? 0,
                        rebounds: 0,
                        assists: 0,
                        steals: nil,
                        blocks: nil,
                        turnovers: nil,
                        fieldGoalPercentage: nil,
                        threePointPercentage: nil,
                        freeThrowPercentage: nil,
                        fouls: nil
                    ),
                    quarters: mapQuarters(homeScoring: home?.scoring, awayScoring: away?.scoring),
                    lastUpdated: scheduled
                )
            } else {
                boxScoreDTO = nil
            }
        }
        
        return GameDTO(
            id: id,
            homeTeam: homeTeamDTO,
            awayTeam: awayTeamDTO,
            date: dateFormatter.string(from: gameDate),
            status: gameStatus.rawValue,
            boxScore: boxScoreDTO,
            venue: venue?.name,
            league: season?.name,
            broadcastNetwork: broadcasts?.first?.network,
            timeZone: broadcasts?.first?.locale
        )
    }
    
    /// Map to app BoxScoreDTO using team statistics
    func toBoxScoreDTO() throws -> BoxScoreDTO {
        // Try multiple sources for points (historical games may store points in statistics)
        var homeScore = home?.points 
            ?? home?.statistics?.points 
            ?? home?.statistics?.totalPoints 
            ?? home?.statistics?.teamPoints
        
        var awayScore = away?.points 
            ?? away?.statistics?.points 
            ?? away?.statistics?.totalPoints 
            ?? away?.statistics?.teamPoints
        
        // If scores are still nil, try to calculate from quarter scores
        if homeScore == nil || awayScore == nil {
            if let homeScoring = home?.scoring, let awayScoring = away?.scoring {
                let homeTotal = homeScoring.compactMap { $0.points }.reduce(0, +)
                let awayTotal = awayScoring.compactMap { $0.points }.reduce(0, +)
                if homeTotal > 0 {
                    homeScore = homeScore ?? homeTotal
                }
                if awayTotal > 0 {
                    awayScore = awayScore ?? awayTotal
                }
            }
        }
        
        // Default to 0 if still nil
        let finalHomeScore = homeScore ?? 0
        let finalAwayScore = awayScore ?? 0
        
        // Use full team statistics from game summary (much more accurate than aggregating from leaders)
        let homeStats = home?.statistics?.toTeamStatsDTO(points: finalHomeScore) ?? TeamStatsDTO(
            points: finalHomeScore,
            rebounds: 0,
            assists: 0,
            steals: nil,
            blocks: nil,
            turnovers: nil,
            fieldGoalPercentage: nil,
            threePointPercentage: nil,
            freeThrowPercentage: nil,
            fouls: nil
        )
        
        let awayStats = away?.statistics?.toTeamStatsDTO(points: finalAwayScore) ?? TeamStatsDTO(
            points: finalAwayScore,
            rebounds: 0,
            assists: 0,
            steals: nil,
            blocks: nil,
            turnovers: nil,
            fieldGoalPercentage: nil,
            threePointPercentage: nil,
            freeThrowPercentage: nil,
            fouls: nil
        )
        
        // Map quarters from scoring periods
        let quarterDTOs = mapQuarters(homeScoring: home?.scoring, awayScoring: away?.scoring)
        
        return BoxScoreDTO(
            homeScore: finalHomeScore,
            awayScore: finalAwayScore,
            homeStats: homeStats,
            awayStats: awayStats,
            quarters: quarterDTOs,
            lastUpdated: scheduled
        )
    }
    
    private func mapGameStatus(_ status: String) -> GameStatus {
        let lowercased = status.lowercased()
        if lowercased.contains("closed") || lowercased.contains("complete") || lowercased.contains("final") {
            return .finished
        } else if lowercased.contains("live") || lowercased.contains("inprogress") {
            return .live
        } else if lowercased.contains("postponed") {
            return .postponed
        } else if lowercased.contains("cancelled") || lowercased.contains("canceled") {
            return .cancelled
        } else {
            return .scheduled
        }
    }
    
    private func mapQuarters(homeScoring: [SportradarScoringPeriodDTO]?, awayScoring: [SportradarScoringPeriodDTO]?) -> [QuarterScoreDTO]? {
        guard let homeScoring = homeScoring, let awayScoring = awayScoring else {
            return nil
        }
        
        // Filter to only quarter types (not elam)
        let homeQuarters = homeScoring.filter { $0.type == "quarter" }.sorted { ($0.number ?? 0) < ($1.number ?? 0) }
        let awayQuarters = awayScoring.filter { $0.type == "quarter" }.sorted { ($0.number ?? 0) < ($1.number ?? 0) }
        
        guard homeQuarters.count == awayQuarters.count else {
            return nil
        }
        
        return homeQuarters.enumerated().compactMap { index, homePeriod in
            guard index < awayQuarters.count else { return nil }
            let awayPeriod = awayQuarters[index]
            
            return QuarterScoreDTO(
                id: "Q\(homePeriod.number ?? index + 1)",
                homeScore: homePeriod.points ?? 0,
                awayScore: awayPeriod.points ?? 0,
                quarterNumber: homePeriod.number ?? index + 1
            )
        }
    }
}

extension SportradarTeamGameStatisticsDTO {
    /// Map to TeamStatsDTO
    func toTeamStatsDTO(points: Int) -> TeamStatsDTO {
        // Prefer direct rebounds field, then personalRebounds, otherwise calculate from offensive + defensive
        let rebounds = self.rebounds ?? personalRebounds ?? ((offensiveRebounds ?? 0) + (defensiveRebounds ?? 0))
        
        return TeamStatsDTO(
            points: points,
            rebounds: rebounds,
            assists: assists ?? 0,
            steals: steals,
            blocks: blocks,
            turnovers: totalTurnovers ?? playerTurnovers,
            fieldGoalPercentage: fieldGoalsPct,
            threePointPercentage: threePointsPct,
            freeThrowPercentage: freeThrowsPct,
            fouls: totalFouls ?? personalFouls
        )
    }
}

/// Sportradar Player Response
struct SportradarPlayerDTO: Codable {
    let id: String
    let fullName: String? // or "name" field
    let firstName: String?
    let lastName: String?
    let position: String?
    let jerseyNumber: String? // May be string in API
    let height: String?
    let weight: String? // May be string in API
    let age: Int?
    let birthDate: String?
    let birthPlace: String?
    let college: String?
    let photo: String? // Photo URL
    
    // Team reference (may be ID or nested object)
    let team: SportradarTeamReferenceDTO?
    let teamId: String?
    
    // Statistics (may be nested or in separate endpoint)
    let statistics: [SportradarStatisticDTO]?
    let averages: SportradarAveragesDTO?
    
    enum CodingKeys: String, CodingKey {
        case id, position, age, college, photo, team, statistics, averages
        case fullName = "full_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case jerseyNumber = "jersey_number"
        case height, weight
        case birthDate = "birth_date"
        case birthPlace = "birth_place"
        case teamId = "team_id"
    }
    
    /// Map to app PlayerDTO
    func toPlayerDTO(teamDTO: TeamDTO) -> PlayerDTO {
        let name = fullName ?? "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespaces)
        let jerseyNum = jerseyNumber.flatMap { Int($0) }
        let weightInt = weight.flatMap { Int($0) }
        
        // Map statistics
        let stats: [StatisticDTO]
        if let statistics = statistics {
            stats = statistics.map { $0.toStatisticDTO() }
        } else if let averages = averages {
            stats = averages.toStatisticDTOs()
        } else {
            stats = []
        }
        
        return PlayerDTO(
            id: id,
            name: name,
            team: teamDTO,
            position: position ?? "Unknown",
            statistics: stats,
            jerseyNumber: jerseyNum,
            height: height,
            weight: weightInt,
            age: age,
            college: college,
            photoURL: photo
        )
    }
}

struct SportradarAveragesDTO: Codable {
    let points: Double?
    let rebounds: Double?
    let assists: Double?
    let steals: Double?
    let blocks: Double?
    let fieldGoalsMade: Double?
    let fieldGoalsAttempted: Double?
    let fieldGoalPercentage: Double?
    let threePointersMade: Double?
    let threePointersAttempted: Double?
    let threePointPercentage: Double?
    let freeThrowsMade: Double?
    let freeThrowsAttempted: Double?
    let freeThrowPercentage: Double?
    let gamesPlayed: Int?
    
    func toStatisticDTOs() -> [StatisticDTO] {
        var stats: [StatisticDTO] = []
        
        if let points = points {
            stats.append(StatisticDTO(
                id: UUID().uuidString,
                name: "Points Per Game",
                value: points,
                category: "scoring",
                unit: "points",
                season: nil,
                gamesPlayed: gamesPlayed
            ))
        }
        
        if let rebounds = rebounds {
            stats.append(StatisticDTO(
                id: UUID().uuidString,
                name: "Rebounds Per Game",
                value: rebounds,
                category: "rebounding",
                unit: "rebounds",
                season: nil,
                gamesPlayed: gamesPlayed
            ))
        }
        
        if let assists = assists {
            stats.append(StatisticDTO(
                id: UUID().uuidString,
                name: "Assists Per Game",
                value: assists,
                category: "assists",
                unit: "assists",
                season: nil,
                gamesPlayed: gamesPlayed
            ))
        }
        
        if let steals = steals {
            stats.append(StatisticDTO(
                id: UUID().uuidString,
                name: "Steals Per Game",
                value: steals,
                category: "defense",
                unit: "steals",
                season: nil,
                gamesPlayed: gamesPlayed
            ))
        }
        
        if let blocks = blocks {
            stats.append(StatisticDTO(
                id: UUID().uuidString,
                name: "Blocks Per Game",
                value: blocks,
                category: "defense",
                unit: "blocks",
                season: nil,
                gamesPlayed: gamesPlayed
            ))
        }
        
        if let fgPct = fieldGoalPercentage {
            stats.append(StatisticDTO(
                id: UUID().uuidString,
                name: "Field Goal Percentage",
                value: fgPct,
                category: "shooting",
                unit: "percentage",
                season: nil,
                gamesPlayed: gamesPlayed
            ))
        }
        
        if let threePtPct = threePointPercentage {
            stats.append(StatisticDTO(
                id: UUID().uuidString,
                name: "Three Point Percentage",
                value: threePtPct,
                category: "shooting",
                unit: "percentage",
                season: nil,
                gamesPlayed: gamesPlayed
            ))
        }
        
        if let ftPct = freeThrowPercentage {
            stats.append(StatisticDTO(
                id: UUID().uuidString,
                name: "Free Throw Percentage",
                value: ftPct,
                category: "shooting",
                unit: "percentage",
                season: nil,
                gamesPlayed: gamesPlayed
            ))
        }
        
        return stats
    }
}

struct SportradarStatisticDTO: Codable {
    let name: String?
    let value: Double?
    let category: String?
    let unit: String?
    let season: String?
    let gamesPlayed: Int?
    
    func toStatisticDTO() -> StatisticDTO {
        // Map Sportradar category to app category
        let mappedCategory = mapCategory(category ?? "other")
        return StatisticDTO(
            id: UUID().uuidString,
            name: name ?? "Unknown",
            value: value ?? 0.0,
            category: mappedCategory,
            unit: unit,
            season: season,
            gamesPlayed: gamesPlayed
        )
    }
    
    private func mapCategory(_ category: String) -> String {
        let lowercased = category.lowercased()
        if lowercased.contains("point") || lowercased.contains("score") {
            return "scoring"
        } else if lowercased.contains("rebound") {
            return "rebounding"
        } else if lowercased.contains("assist") {
            return "assists"
        } else if lowercased.contains("steal") || lowercased.contains("block") {
            return "defense"
        } else if lowercased.contains("percentage") || lowercased.contains("shot") {
            return "shooting"
        } else if lowercased.contains("turnover") {
            return "turnovers"
        } else {
            return "efficiency"
        }
    }
}

/// Sportradar Game Summary Response - matches actual API structure
struct SportradarGameSummaryDTO: Codable {
    let id: String
    let status: String?
    let coverage: String?
    let scheduled: String? // ISO 8601 date string
    let leadChanges: Int?
    let timesTied: Int?
    let clock: String?
    let quarter: Int?
    let possessionArrow: String?
    let trackOnCourt: Bool?
    let entryMode: String?
    let clockDecimal: String?
    let broadcasts: [SportradarBroadcastDTO]?
    let timeZones: SportradarTimeZonesDTO?
    let season: SportradarSeasonDTO?
    let venue: SportradarVenueDetailDTO?
    let home: SportradarTeamGameSummaryDTO?
    let away: SportradarTeamGameSummaryDTO?
    let officials: [SportradarOfficialDTO]?
    
    enum CodingKeys: String, CodingKey {
        case id, status, coverage, scheduled, clock, quarter, broadcasts, timeZones = "time_zones", season, venue, home, away, officials
        case leadChanges = "lead_changes"
        case timesTied = "times_tied"
        case possessionArrow = "possession_arrow"
        case trackOnCourt = "track_on_court"
        case entryMode = "entry_mode"
        case clockDecimal = "clock_decimal"
    }
}

/// Sportradar Team Game Summary - includes full team stats and players
struct SportradarTeamGameSummaryDTO: Codable {
    let name: String?
    let alias: String?
    let id: String?
    let points: Int?
    let remainingTimeouts: Int?
    let scoring: [SportradarScoringPeriodDTO]?
    let statistics: SportradarTeamGameStatisticsDTO?
    let periods: [SportradarPeriodStatisticsDTO]?
    let coaches: [SportradarCoachDTO]?
    let players: [SportradarPlayerGameSummaryDTO]?
    
    enum CodingKeys: String, CodingKey {
        case name, alias, id, points, scoring, statistics, periods, coaches, players
        case remainingTimeouts = "remaining_timeouts"
    }
}

struct SportradarTeamGameStatisticsDTO: Codable {
    let minutes: String?
    let fieldGoalsMade: Int?
    let fieldGoalsAtt: Int?
    let fieldGoalsPct: Double?
    let threePointsMade: Int?
    let threePointsAtt: Int?
    let threePointsPct: Double?
    let twoPointsMade: Int?
    let twoPointsAtt: Int?
    let twoPointsPct: Double?
    let blockedAtt: Int?
    let freeThrowsMade: Int?
    let freeThrowsAtt: Int?
    let freeThrowsPct: Double?
    let offensiveRebounds: Int?
    let defensiveRebounds: Int?
    let rebounds: Int? // Direct rebounds field (personal rebounds)
    let assists: Int?
    let steals: Int?
    let blocks: Int?
    let assistsTurnoverRatio: Double?
    let personalFouls: Int?
    let ejections: Int?
    let foulouts: Int?
    let points: Int?
    let fastBreakPts: Int?
    let secondChancePts: Int?
    let teamTurnovers: Int?
    let pointsOffTurnovers: Int?
    let teamRebounds: Int?
    let flagrantFouls: Int?
    let playerTechFouls: Int?
    let teamTechFouls: Int?
    let coachTechFouls: Int?
    let teamPoints: Int?
    let totalPoints: Int?
    let winningBasket: Bool?
    let freeThrowPoints: Int?
    let pointsInPaint: Int?
    let teamOffensiveRebounds: Int?
    let teamDefensiveRebounds: Int?
    let totalRebounds: Int?
    let totalTurnovers: Int?
    let personalRebounds: Int?
    let playerTurnovers: Int?
    let fieldGoalsAtRimMade: Int?
    let fieldGoalsAtRimAtt: Int?
    let fieldGoalsAtRimPct: Double?
    let fieldGoalsAtMidrangeMade: Int?
    let fieldGoalsAtMidrangeAtt: Int?
    let fieldGoalsAtMidrangePct: Double?
    let benchPoints: Int?
    let biggestLead: Int?
    let effectiveFgPct: Double?
    let efficiency: Int?
    let efficiencyGameScore: Double?
    let foulsDrawn: Int?
    let offensiveFouls: Int?
    let plsMin: Int?
    let pointsInPaintAtt: Int?
    let pointsInPaintMade: Int?
    let pointsInPaintPct: Double?
    let totalFouls: Int?
    let trueShootingAtt: Double?
    let trueShootingPct: Double?
    let mostUnanswered: SportradarMostUnansweredDTO?
    
    enum CodingKeys: String, CodingKey {
        case minutes, points, assists, steals, blocks, ejections, foulouts
        case fieldGoalsMade = "field_goals_made"
        case fieldGoalsAtt = "field_goals_att"
        case fieldGoalsPct = "field_goals_pct"
        case threePointsMade = "three_points_made"
        case threePointsAtt = "three_points_att"
        case threePointsPct = "three_points_pct"
        case twoPointsMade = "two_points_made"
        case twoPointsAtt = "two_points_att"
        case twoPointsPct = "two_points_pct"
        case blockedAtt = "blocked_att"
        case freeThrowsMade = "free_throws_made"
        case freeThrowsAtt = "free_throws_att"
        case freeThrowsPct = "free_throws_pct"
        case offensiveRebounds = "offensive_rebounds"
        case defensiveRebounds = "defensive_rebounds"
        case rebounds
        case assistsTurnoverRatio = "assists_turnover_ratio"
        case personalFouls = "personal_fouls"
        case fastBreakPts = "fast_break_pts"
        case secondChancePts = "second_chance_pts"
        case teamTurnovers = "team_turnovers"
        case pointsOffTurnovers = "points_off_turnovers"
        case teamRebounds = "team_rebounds"
        case flagrantFouls = "flagrant_fouls"
        case playerTechFouls = "player_tech_fouls"
        case teamTechFouls = "team_tech_fouls"
        case coachTechFouls = "coach_tech_fouls"
        case teamPoints = "team_points"
        case totalPoints = "total_points"
        case winningBasket = "winning_basket"
        case freeThrowPoints = "free_throw_points"
        case pointsInPaint = "points_in_paint"
        case teamOffensiveRebounds = "team_offensive_rebounds"
        case teamDefensiveRebounds = "team_defensive_rebounds"
        case totalRebounds = "total_rebounds"
        case totalTurnovers = "total_turnovers"
        case personalRebounds = "personal_rebounds"
        case playerTurnovers = "player_turnovers"
        case fieldGoalsAtRimMade = "field_goals_at_rim_made"
        case fieldGoalsAtRimAtt = "field_goals_at_rim_att"
        case fieldGoalsAtRimPct = "field_goals_at_rim_pct"
        case fieldGoalsAtMidrangeMade = "field_goals_at_midrange_made"
        case fieldGoalsAtMidrangeAtt = "field_goals_at_midrange_att"
        case fieldGoalsAtMidrangePct = "field_goals_at_midrange_pct"
        case benchPoints = "bench_points"
        case biggestLead = "biggest_lead"
        case effectiveFgPct = "effective_fg_pct"
        case efficiency
        case efficiencyGameScore = "efficiency_game_score"
        case foulsDrawn = "fouls_drawn"
        case offensiveFouls = "offensive_fouls"
        case plsMin = "pls_min"
        case pointsInPaintAtt = "points_in_paint_att"
        case pointsInPaintMade = "points_in_paint_made"
        case pointsInPaintPct = "points_in_paint_pct"
        case totalFouls = "total_fouls"
        case trueShootingAtt = "true_shooting_att"
        case trueShootingPct = "true_shooting_pct"
        case mostUnanswered = "most_unanswered"
    }
}

struct SportradarMostUnansweredDTO: Codable {
    let points: Int?
    let ownScore: Int?
    let oppScore: Int?
    
    enum CodingKeys: String, CodingKey {
        case points
        case ownScore = "own_score"
        case oppScore = "opp_score"
    }
}

struct SportradarPeriodStatisticsDTO: Codable {
    let type: String? // "REG" or "ELAM"
    let id: String?
    let number: Int?
    let sequence: Int?
    let minutes: String?
    let fieldGoalsMade: Int?
    let fieldGoalsAtt: Int?
    let fieldGoalsPct: Double?
    let threePointsMade: Int?
    let threePointsAtt: Int?
    let threePointsPct: Double?
    let twoPointsMade: Int?
    let twoPointsAtt: Int?
    let twoPointsPct: Double?
    let blockedAtt: Int?
    let freeThrowsMade: Int?
    let freeThrowsAtt: Int?
    let freeThrowsPct: Double?
    let offensiveRebounds: Int?
    let defensiveRebounds: Int?
    let rebounds: Int?
    let assists: Int?
    let turnovers: Int?
    let steals: Int?
    let blocks: Int?
    let assistsTurnoverRatio: Double?
    let personalFouls: Int?
    let offensiveFouls: Int?
    let ejections: Int?
    let points: Int?
    let secondChancePts: Int?
    let teamTurnovers: Int?
    let pointsOffTurnovers: Int?
    let teamRebounds: Int?
    let flagrantFouls: Int?
    let playerTechFouls: Int?
    let teamTechFouls: Int?
    let coachTechFouls: Int?
    let plsMin: Int?
    let effectiveFgPct: Double?
    let benchPoints: Int?
    let pointsInPaint: Int?
    let pointsInPaintAtt: Int?
    let pointsInPaintMade: Int?
    let pointsInPaintPct: Double?
    let trueShootingAtt: Double?
    let trueShootingPct: Double?
    let biggestLead: Int?
    let foulsDrawn: Int?
    let totalTurnovers: Int?
    let efficiency: Int?
    let efficiencyGameScore: Double?
    let winningBasket: Bool?
    let freeThrowPoints: Int?
    
    enum CodingKeys: String, CodingKey {
        case type, id, number, sequence, minutes, rebounds, assists, turnovers, steals, blocks, points, ejections
        case fieldGoalsMade = "field_goals_made"
        case fieldGoalsAtt = "field_goals_att"
        case fieldGoalsPct = "field_goals_pct"
        case threePointsMade = "three_points_made"
        case threePointsAtt = "three_points_att"
        case threePointsPct = "three_points_pct"
        case twoPointsMade = "two_points_made"
        case twoPointsAtt = "two_points_att"
        case twoPointsPct = "two_points_pct"
        case blockedAtt = "blocked_att"
        case freeThrowsMade = "free_throws_made"
        case freeThrowsAtt = "free_throws_att"
        case freeThrowsPct = "free_throws_pct"
        case offensiveRebounds = "offensive_rebounds"
        case defensiveRebounds = "defensive_rebounds"
        case assistsTurnoverRatio = "assists_turnover_ratio"
        case personalFouls = "personal_fouls"
        case offensiveFouls = "offensive_fouls"
        case secondChancePts = "second_chance_pts"
        case teamTurnovers = "team_turnovers"
        case pointsOffTurnovers = "points_off_turnovers"
        case teamRebounds = "team_rebounds"
        case flagrantFouls = "flagrant_fouls"
        case playerTechFouls = "player_tech_fouls"
        case teamTechFouls = "team_tech_fouls"
        case coachTechFouls = "coach_tech_fouls"
        case plsMin = "pls_min"
        case effectiveFgPct = "effective_fg_pct"
        case benchPoints = "bench_points"
        case pointsInPaint = "points_in_paint"
        case pointsInPaintAtt = "points_in_paint_att"
        case pointsInPaintMade = "points_in_paint_made"
        case pointsInPaintPct = "points_in_paint_pct"
        case trueShootingAtt = "true_shooting_att"
        case trueShootingPct = "true_shooting_pct"
        case biggestLead = "biggest_lead"
        case foulsDrawn = "fouls_drawn"
        case totalTurnovers = "total_turnovers"
        case efficiency
        case efficiencyGameScore = "efficiency_game_score"
        case winningBasket = "winning_basket"
        case freeThrowPoints = "free_throw_points"
    }
}

struct SportradarCoachDTO: Codable {
    let id: String?
    let fullName: String?
    let firstName: String?
    let lastName: String?
    let position: String?
    
    enum CodingKeys: String, CodingKey {
        case id, position
        case fullName = "full_name"
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct SportradarPlayerGameSummaryDTO: Codable {
    let fullName: String?
    let jerseyNumber: String?
    let id: String?
    let firstName: String?
    let lastName: String?
    let position: String?
    let primaryPosition: String?
    let played: Bool?
    let active: Bool?
    let starter: Bool?
    let onCourt: Bool?
    let statistics: SportradarPlayerStatisticsDTO?
    let periods: [SportradarPeriodStatisticsDTO]?
    
    enum CodingKeys: String, CodingKey {
        case id, position, statistics, periods, played, active, starter
        case fullName = "full_name"
        case jerseyNumber = "jersey_number"
        case firstName = "first_name"
        case lastName = "last_name"
        case primaryPosition = "primary_position"
        case onCourt = "on_court"
    }
}

struct SportradarVenueDetailDTO: Codable {
    let id: String?
    let name: String?
    let capacity: Int?
    let address: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    let location: SportradarLocationDTO?
}

struct SportradarLocationDTO: Codable {
    let lat: String?
    let lng: String?
}

struct SportradarOfficialDTO: Codable {
    let id: String?
    let fullName: String?
    let firstName: String?
    let lastName: String?
    let position: String?
    
    enum CodingKeys: String, CodingKey {
        case id, position
        case fullName = "full_name"
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

/// Sportradar Team Reference (used in schedule and other endpoints)
struct SportradarTeamReferenceDTO: Codable {
    let id: String
    let name: String?
    let alias: String?
}

/// Sportradar Game Response (used in schedule endpoint)
struct SportradarGameDTO: Codable {
    let id: String
    let status: String?
    let coverage: String?
    let scheduled: String? // ISO 8601 date string
    let trackOnCourt: Bool?
    let timeZones: SportradarTimeZonesDTO?
    let season: SportradarSeasonDTO?
    let venue: SportradarVenueDetailDTO?
    let broadcasts: [SportradarBroadcastDTO]?
    let home: SportradarTeamReferenceDTO?
    let away: SportradarTeamReferenceDTO?
    
    // Legacy fields for backward compatibility
    let homeId: String?
    let awayId: String?
    let league: String? // Deprecated - use season instead
    
    // Boxscore data (may be in separate endpoint or nested)
    let boxscore: SportradarBoxscoreDTO?
    let scoring: SportradarScoringDTO?
    
    enum CodingKeys: String, CodingKey {
        case id, status, coverage, scheduled, season, venue, broadcasts, home, away
        case trackOnCourt = "track_on_court"
        case timeZones = "time_zones"
        case homeId = "home_id"
        case awayId = "away_id"
        case boxscore, scoring, league
    }
    
    /// Map to app GameDTO
    /// - Parameter homeTeamDTO: Home team DTO (fetched separately)
    /// - Parameter awayTeamDTO: Away team DTO (fetched separately)
    func toGameDTO(homeTeamDTO: TeamDTO, awayTeamDTO: TeamDTO) throws -> GameDTO {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let dateString = scheduled,
              let gameDate = dateFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) else {
            throw DTOMappingError.invalidDate(scheduled ?? "unknown")
        }
        
        // Map status - Sportradar may use different status values
        let gameStatus = mapGameStatus(status ?? "scheduled")
        
        // Map boxscore if available
        let boxScoreDTO: BoxScoreDTO?
        if let boxscore = boxscore {
            boxScoreDTO = try boxscore.toBoxScoreDTO()
        } else if let scoring = scoring {
            boxScoreDTO = try scoring.toBoxScoreDTO()
        } else {
            boxScoreDTO = nil
        }
        
        // Extract broadcast network (use first TV broadcast's network, or first broadcast's network)
        let broadcastNetwork: String? = {
            if let broadcasts = broadcasts, !broadcasts.isEmpty {
                // Prefer TV broadcasts, fallback to any broadcast
                if let tvBroadcast = broadcasts.first(where: { $0.type?.lowercased() == "tv" }) {
                    return tvBroadcast.network
                }
                return broadcasts.first?.network
            }
            return nil
        }()
        
        // Extract timezone (prefer venue timezone, fallback to home team timezone)
        let timeZone: String? = timeZones?.venue ?? timeZones?.home
        
        return GameDTO(
            id: id,
            homeTeam: homeTeamDTO,
            awayTeam: awayTeamDTO,
            date: dateFormatter.string(from: gameDate),
            status: gameStatus.rawValue,
            boxScore: boxScoreDTO,
            venue: venue?.name,
            league: season?.name ?? league, // Prefer season name, fallback to legacy league field
            broadcastNetwork: broadcastNetwork,
            timeZone: timeZone
        )
    }
    
    private func mapGameStatus(_ status: String) -> GameStatus {
        let lowercased = status.lowercased()
        if lowercased.contains("closed") || lowercased.contains("complete") || lowercased.contains("final") {
            return .finished
        } else if lowercased.contains("live") || lowercased.contains("inprogress") {
            return .live
        } else if lowercased.contains("postponed") {
            return .postponed
        } else if lowercased.contains("cancelled") || lowercased.contains("canceled") {
            return .cancelled
        } else {
            return .scheduled
        }
    }
}

/// Sportradar Boxscore Response - matches actual API structure
struct SportradarBoxscoreDTO: Codable {
    let id: String?
    let status: String?
    let coverage: String?
    let scheduled: String?
    let leadChanges: Int?
    let timesTied: Int?
    let clock: String?
    let quarter: Int?
    let possessionArrow: String?
    let trackOnCourt: Bool?
    let entryMode: String?
    let clockDecimal: String?
    let broadcasts: [SportradarBroadcastDTO]?
    let timeZones: SportradarTimeZonesDTO?
    let season: SportradarSeasonDTO?
    let home: SportradarTeamBoxscoreDTO?
    let away: SportradarTeamBoxscoreDTO?
    
    enum CodingKeys: String, CodingKey {
        case id, status, coverage, scheduled, clock, quarter, broadcasts, timeZones = "time_zones", season, home, away
        case leadChanges = "lead_changes"
        case timesTied = "times_tied"
        case possessionArrow = "possession_arrow"
        case trackOnCourt = "track_on_court"
        case entryMode = "entry_mode"
        case clockDecimal = "clock_decimal"
    }
    
    func toBoxScoreDTO() throws -> BoxScoreDTO {
        let homeScore = home?.points ?? 0
        let awayScore = away?.points ?? 0
        
        // Aggregate team stats from player leaders (Sportradar doesn't provide direct team stats)
        let homeStats = aggregateTeamStats(from: home?.leaders, points: homeScore)
        let awayStats = aggregateTeamStats(from: away?.leaders, points: awayScore)
        
        // Map quarters from scoring array
        let quarterDTOs = mapQuarters(homeScoring: home?.scoring, awayScoring: away?.scoring)
        
        // Use scheduled time as lastUpdated if available
        let lastUpdated = scheduled
        
        return BoxScoreDTO(
            homeScore: homeScore,
            awayScore: awayScore,
            homeStats: homeStats,
            awayStats: awayStats,
            quarters: quarterDTOs,
            lastUpdated: lastUpdated
        )
    }
    
    /// Aggregate team statistics from player leaders
    /// Note: Since Sportradar only provides leaders (not all players), this is an approximation
    private func aggregateTeamStats(from leaders: SportradarLeadersDTO?, points: Int) -> TeamStatsDTO {
        // Collect unique players from all leader categories to avoid double-counting
        var uniquePlayers: [String: SportradarPlayerLeaderDTO] = [:]
        
        // Add points leader
        if let pointsLeader = leaders?.points?.first {
            uniquePlayers[pointsLeader.id ?? UUID().uuidString] = pointsLeader
        }
        
        // Add rebounds leader (if different from points leader)
        if let reboundsLeader = leaders?.rebounds?.first,
           let reboundsId = reboundsLeader.id,
           uniquePlayers[reboundsId] == nil {
            uniquePlayers[reboundsId] = reboundsLeader
        }
        
        // Add assists leader (if different from other leaders)
        if let assistsLeader = leaders?.assists?.first,
           let assistsId = assistsLeader.id,
           uniquePlayers[assistsId] == nil {
            uniquePlayers[assistsId] = assistsLeader
        }
        
        // Aggregate stats from unique players
        var totalRebounds = 0
        var totalAssists = 0
        var totalSteals = 0
        var totalBlocks = 0
        var totalTurnovers = 0
        var totalFouls = 0
        
        for player in uniquePlayers.values {
            guard let stats = player.statistics else { continue }
            totalRebounds += stats.rebounds ?? 0
            totalAssists += stats.assists ?? 0
            totalSteals += stats.steals ?? 0
            totalBlocks += stats.blocks ?? 0
            totalTurnovers += stats.turnovers ?? 0
            totalFouls += stats.personalFouls ?? 0
        }
        
        // Use percentages from points leader (best approximation for team percentages)
        let pointsLeaderStats = leaders?.points?.first?.statistics
        let fieldGoalPct = pointsLeaderStats?.fieldGoalsPct
        let threePointPct = pointsLeaderStats?.threePointsPct
        let freeThrowPct = pointsLeaderStats?.freeThrowsPct
        
        return TeamStatsDTO(
            points: points,
            rebounds: totalRebounds,
            assists: totalAssists,
            steals: totalSteals > 0 ? totalSteals : nil,
            blocks: totalBlocks > 0 ? totalBlocks : nil,
            turnovers: totalTurnovers > 0 ? totalTurnovers : nil,
            fieldGoalPercentage: fieldGoalPct,
            threePointPercentage: threePointPct,
            freeThrowPercentage: freeThrowPct,
            fouls: totalFouls > 0 ? totalFouls : nil
        )
    }
    
    /// Map scoring periods to quarter scores
    private func mapQuarters(homeScoring: [SportradarScoringPeriodDTO]?, awayScoring: [SportradarScoringPeriodDTO]?) -> [QuarterScoreDTO]? {
        guard let homeScoring = homeScoring, let awayScoring = awayScoring else {
            return nil
        }
        
        // Filter to only quarter types (not elam)
        let homeQuarters = homeScoring.filter { $0.type == "quarter" }.sorted { ($0.number ?? 0) < ($1.number ?? 0) }
        let awayQuarters = awayScoring.filter { $0.type == "quarter" }.sorted { ($0.number ?? 0) < ($1.number ?? 0) }
        
        guard homeQuarters.count == awayQuarters.count else {
            return nil
        }
        
        return homeQuarters.enumerated().compactMap { index, homePeriod in
            guard index < awayQuarters.count else { return nil }
            let awayPeriod = awayQuarters[index]
            
            return QuarterScoreDTO(
                id: "Q\(homePeriod.number ?? index + 1)",
                homeScore: homePeriod.points ?? 0,
                awayScore: awayPeriod.points ?? 0,
                quarterNumber: homePeriod.number ?? index + 1
            )
        }
    }
}

struct SportradarScoringDTO: Codable {
    let home: SportradarTeamScoreDTO?
    let away: SportradarTeamScoreDTO?
    
    func toBoxScoreDTO() throws -> BoxScoreDTO {
        let homeScore = home?.points ?? 0
        let awayScore = away?.points ?? 0
        
        let homeStats = home?.statistics?.toTeamStatsDTO() ?? TeamStatsDTO(
            points: homeScore,
            rebounds: 0,
            assists: 0,
            steals: nil,
            blocks: nil,
            turnovers: nil,
            fieldGoalPercentage: nil,
            threePointPercentage: nil,
            freeThrowPercentage: nil,
            fouls: nil
        )
        
        let awayStats = away?.statistics?.toTeamStatsDTO() ?? TeamStatsDTO(
            points: awayScore,
            rebounds: 0,
            assists: 0,
            steals: nil,
            blocks: nil,
            turnovers: nil,
            fieldGoalPercentage: nil,
            threePointPercentage: nil,
            freeThrowPercentage: nil,
            fouls: nil
        )
        
        return BoxScoreDTO(
            homeScore: homeScore,
            awayScore: awayScore,
            homeStats: homeStats,
            awayStats: awayStats,
            quarters: nil,
            lastUpdated: nil
        )
    }
}

/// Sportradar Team Boxscore - matches actual API structure
struct SportradarTeamBoxscoreDTO: Codable {
    let name: String?
    let alias: String?
    let id: String?
    let points: Int?
    let remainingTimeouts: Int?
    let scoring: [SportradarScoringPeriodDTO]?
    let leaders: SportradarLeadersDTO?
    
    enum CodingKeys: String, CodingKey {
        case name, alias, id, points, scoring, leaders
        case remainingTimeouts = "remaining_timeouts"
    }
}

struct SportradarScoringPeriodDTO: Codable {
    let type: String? // "quarter" or "elam"
    let number: Int?
    let sequence: Int?
    let points: Int?
}

struct SportradarLeadersDTO: Codable {
    let points: [SportradarPlayerLeaderDTO]?
    let rebounds: [SportradarPlayerLeaderDTO]?
    let assists: [SportradarPlayerLeaderDTO]?
}

struct SportradarPlayerLeaderDTO: Codable {
    let fullName: String?
    let jerseyNumber: String?
    let id: String?
    let position: String?
    let primaryPosition: String?
    let statistics: SportradarPlayerStatisticsDTO?
    
    enum CodingKeys: String, CodingKey {
        case id, position, statistics
        case fullName = "full_name"
        case jerseyNumber = "jersey_number"
        case primaryPosition = "primary_position"
    }
}

struct SportradarPlayerStatisticsDTO: Codable {
    let minutes: String?
    let fieldGoalsMade: Int?
    let fieldGoalsAtt: Int?
    let fieldGoalsPct: Double?
    let threePointsMade: Int?
    let threePointsAtt: Int?
    let threePointsPct: Double?
    let twoPointsMade: Int?
    let twoPointsAtt: Int?
    let twoPointsPct: Double?
    let blockedAtt: Int?
    let freeThrowsMade: Int?
    let freeThrowsAtt: Int?
    let freeThrowsPct: Double?
    let offensiveRebounds: Int?
    let defensiveRebounds: Int?
    let rebounds: Int?
    let assists: Int?
    let turnovers: Int?
    let steals: Int?
    let blocks: Int?
    let assistsTurnoverRatio: Double?
    let personalFouls: Int?
    let techFouls: Int?
    let flagrantFouls: Int?
    let plsMin: Int?
    let points: Int?
    let techFoulsNonUnsportsmanlike: Int?
    let doubleDouble: Bool?
    let tripleDouble: Bool?
    let effectiveFgPct: Double?
    let efficiency: Int?
    let efficiencyGameScore: Double?
    let foulsDrawn: Int?
    let offensiveFouls: Int?
    let pointsInPaint: Int?
    let pointsInPaintAtt: Int?
    let pointsInPaintMade: Int?
    let pointsInPaintPct: Double?
    let pointsOffTurnovers: Int?
    let trueShootingAtt: Double?
    let trueShootingPct: Double?
    let coachEjections: Int?
    let coachTechFouls: Int?
    let secondChancePts: Int?
    let secondChancePct: Double?
    
    enum CodingKeys: String, CodingKey {
        case minutes, rebounds, assists, turnovers, steals, blocks, points
        case fieldGoalsMade = "field_goals_made"
        case fieldGoalsAtt = "field_goals_att"
        case fieldGoalsPct = "field_goals_pct"
        case threePointsMade = "three_points_made"
        case threePointsAtt = "three_points_att"
        case threePointsPct = "three_points_pct"
        case twoPointsMade = "two_points_made"
        case twoPointsAtt = "two_points_att"
        case twoPointsPct = "two_points_pct"
        case blockedAtt = "blocked_att"
        case freeThrowsMade = "free_throws_made"
        case freeThrowsAtt = "free_throws_att"
        case freeThrowsPct = "free_throws_pct"
        case offensiveRebounds = "offensive_rebounds"
        case defensiveRebounds = "defensive_rebounds"
        case assistsTurnoverRatio = "assists_turnover_ratio"
        case personalFouls = "personal_fouls"
        case techFouls = "tech_fouls"
        case flagrantFouls = "flagrant_fouls"
        case plsMin = "pls_min"
        case techFoulsNonUnsportsmanlike = "tech_fouls_non_unsportsmanlike"
        case doubleDouble = "double_double"
        case tripleDouble = "triple_double"
        case effectiveFgPct = "effective_fg_pct"
        case efficiency
        case efficiencyGameScore = "efficiency_game_score"
        case foulsDrawn = "fouls_drawn"
        case offensiveFouls = "offensive_fouls"
        case pointsInPaint = "points_in_paint"
        case pointsInPaintAtt = "points_in_paint_att"
        case pointsInPaintMade = "points_in_paint_made"
        case pointsInPaintPct = "points_in_paint_pct"
        case pointsOffTurnovers = "points_off_turnovers"
        case trueShootingAtt = "true_shooting_att"
        case trueShootingPct = "true_shooting_pct"
        case coachEjections = "coach_ejections"
        case coachTechFouls = "coach_tech_fouls"
        case secondChancePts = "second_chance_pts"
        case secondChancePct = "second_chance_pct"
    }
}

struct SportradarBroadcastDTO: Codable {
    let type: String?
    let locale: String?
    let network: String?
    let channel: String?
}

struct SportradarTimeZonesDTO: Codable {
    let venue: String?
    let home: String?
    let away: String?
}

struct SportradarSeasonDTO: Codable {
    let id: String?
    let year: Int?
    let type: String?
    let name: String?
}

/// Legacy structure for backward compatibility
struct SportradarTeamScoreDTO: Codable {
    let points: Int?
    let statistics: SportradarTeamStatisticsDTO?
}

struct SportradarTeamStatisticsDTO: Codable {
    let rebounds: Int?
    let assists: Int?
    let steals: Int?
    let blocks: Int?
    let turnovers: Int?
    let fieldGoalsMade: Int?
    let fieldGoalsAttempted: Int?
    let fieldGoalPercentage: Double?
    let threePointersMade: Int?
    let threePointersAttempted: Int?
    let threePointPercentage: Double?
    let freeThrowsMade: Int?
    let freeThrowsAttempted: Int?
    let freeThrowPercentage: Double?
    let fouls: Int?
    
    func toTeamStatsDTO() -> TeamStatsDTO {
        TeamStatsDTO(
            points: 0, // Will be set from parent
            rebounds: rebounds ?? 0,
            assists: assists ?? 0,
            steals: steals,
            blocks: blocks,
            turnovers: turnovers,
            fieldGoalPercentage: fieldGoalPercentage,
            threePointPercentage: threePointPercentage,
            freeThrowPercentage: freeThrowPercentage,
            fouls: fouls
        )
    }
}

struct SportradarQuarterDTO: Codable {
    let id: String?
    let home: Int?
    let away: Int?
    let number: Int?
}

/// Sportradar League Leaders Response
struct SportradarLeagueLeadersDTO: Codable {
    let season: SportradarSeasonDTO?
    let id: String?
    let name: String?
    let alias: String?
    let type: String?
    let categories: [SportradarLeaderCategoryDTO]?
    
    struct SportradarLeaderCategoryDTO: Codable {
        let name: String?
        let type: String?
        let ranks: [SportradarLeaderRankDTO]?
    }
    
    struct SportradarLeaderRankDTO: Codable {
        let rank: Int?
        let tied: Bool?
        let score: Double?
        let player: SportradarLeaderPlayerDTO?
        let teams: [SportradarLeaderTeamDTO]?
        let total: SportradarLeaderStatisticsDTO?
        let average: SportradarLeaderAverageDTO?
    }
    
    struct SportradarLeaderPlayerDTO: Codable {
        let id: String?
        let fullName: String?
        let firstName: String?
        let lastName: String?
        let position: String?
        let primaryPosition: String?
        let jerseyNumber: String?
        
        enum CodingKeys: String, CodingKey {
            case id, position
            case fullName = "full_name"
            case firstName = "first_name"
            case lastName = "last_name"
            case primaryPosition = "primary_position"
            case jerseyNumber = "jersey_number"
        }
    }
    
    struct SportradarLeaderTeamDTO: Codable {
        let id: String?
        let name: String?
    }
    
    struct SportradarLeaderStatisticsDTO: Codable {
        let gamesPlayed: Int?
        let gamesStarted: Int?
        let minutes: Int?
        let fieldGoalsMade: Int?
        let fieldGoalsAtt: Int?
        let fieldGoalsPct: Double?
        let twoPointsMade: Int?
        let twoPointsAtt: Int?
        let twoPointsPct: Double?
        let threePointsMade: Int?
        let threePointsAtt: Int?
        let threePointsPct: Double?
        let blockedAtt: Int?
        let freeThrowsMade: Int?
        let freeThrowsAtt: Int?
        let freeThrowsPct: Double?
        let offensiveRebounds: Int?
        let defensiveRebounds: Int?
        let rebounds: Int?
        let assists: Int?
        let turnovers: Int?
        let assistsTurnoverRatio: Double?
        let steals: Int?
        let blocks: Int?
        let personalFouls: Int?
        let techFouls: Int?
        let points: Int?
        let flagrantFouls: Int?
        let ejections: Int?
        let foulouts: Int?
        let techFoulsNonUnsportsmanlike: Int?
        let trueShootingAtt: Double?
        let trueShootingPct: Double?
        let efficiency: Int?
        let fieldGoalsAtRimMade: Int?
        let fieldGoalsAtRimAtt: Int?
        let fieldGoalsAtMidrangeMade: Int?
        let fieldGoalsAtMidrangeAtt: Int?
        let awardedPoints: Int?
        let coachEjections: Int?
        let coachTechFouls: Int?
        let doubleDoubles: Int?
        let effectiveFgPct: Double?
        let fastBreakAtt: Int?
        let fastBreakMade: Int?
        let fastBreakPct: Double?
        let fastBreakPts: Int?
        let foulsDrawn: Int?
        let freeThrowPoints: Int?
        let minus: Int?
        let offensiveFouls: Int?
        let plus: Int?
        let pointsInPaint: Int?
        let pointsInPaintAtt: Int?
        let pointsInPaintMade: Int?
        let pointsInPaintPct: Double?
        let pointsOffTurnovers: Int?
        let secondChanceAtt: Int?
        let secondChanceMade: Int?
        let secondChancePct: Double?
        let secondChancePts: Int?
        let tripleDoubles: Int?
        let winningBaskets: Int?
        
        enum CodingKeys: String, CodingKey {
            case gamesPlayed = "games_played"
            case gamesStarted = "games_started"
            case minutes
            case fieldGoalsMade = "field_goals_made"
            case fieldGoalsAtt = "field_goals_att"
            case fieldGoalsPct = "field_goals_pct"
            case twoPointsMade = "two_points_made"
            case twoPointsAtt = "two_points_att"
            case twoPointsPct = "two_points_pct"
            case threePointsMade = "three_points_made"
            case threePointsAtt = "three_points_att"
            case threePointsPct = "three_points_pct"
            case blockedAtt = "blocked_att"
            case freeThrowsMade = "free_throws_made"
            case freeThrowsAtt = "free_throws_att"
            case freeThrowsPct = "free_throws_pct"
            case offensiveRebounds = "offensive_rebounds"
            case defensiveRebounds = "defensive_rebounds"
            case rebounds
            case assists, turnovers
            case assistsTurnoverRatio = "assists_turnover_ratio"
            case steals, blocks
            case personalFouls = "personal_fouls"
            case techFouls = "tech_fouls"
            case points
            case flagrantFouls = "flagrant_fouls"
            case ejections, foulouts
            case techFoulsNonUnsportsmanlike = "tech_fouls_non_unsportsmanlike"
            case trueShootingAtt = "true_shooting_att"
            case trueShootingPct = "true_shooting_pct"
            case efficiency
            case fieldGoalsAtRimMade = "field_goals_at_rim_made"
            case fieldGoalsAtRimAtt = "field_goals_at_rim_att"
            case fieldGoalsAtMidrangeMade = "field_goals_at_midrange_made"
            case fieldGoalsAtMidrangeAtt = "field_goals_at_midrange_att"
            case awardedPoints = "awarded_points"
            case coachEjections = "coach_ejections"
            case coachTechFouls = "coach_tech_fouls"
            case doubleDoubles = "double_doubles"
            case effectiveFgPct = "effective_fg_pct"
            case fastBreakAtt = "fast_break_att"
            case fastBreakMade = "fast_break_made"
            case fastBreakPct = "fast_break_pct"
            case fastBreakPts = "fast_break_pts"
            case foulsDrawn = "fouls_drawn"
            case freeThrowPoints = "free_throw_points"
            case minus, plus
            case offensiveFouls = "offensive_fouls"
            case pointsInPaint = "points_in_paint"
            case pointsInPaintAtt = "points_in_paint_att"
            case pointsInPaintMade = "points_in_paint_made"
            case pointsInPaintPct = "points_in_paint_pct"
            case pointsOffTurnovers = "points_off_turnovers"
            case secondChanceAtt = "second_chance_att"
            case secondChanceMade = "second_chance_made"
            case secondChancePct = "second_chance_pct"
            case secondChancePts = "second_chance_pts"
            case tripleDoubles = "triple_doubles"
            case winningBaskets = "winning_baskets"
        }
    }
    
    struct SportradarLeaderAverageDTO: Codable {
        let minutes: Double?
        let points: Double?
        let offRebounds: Double?
        let defRebounds: Double?
        let rebounds: Double?
        let assists: Double?
        let steals: Double?
        let blocks: Double?
        let turnovers: Double?
        let personalFouls: Double?
        let flagrantFouls: Double?
        let blockedAtt: Double?
        let fieldGoalsMade: Double?
        let fieldGoalsAtt: Double?
        let threePointsMade: Double?
        let threePointsAtt: Double?
        let freeThrowsMade: Double?
        let freeThrowsAtt: Double?
        let twoPointsMade: Double?
        let twoPointsAtt: Double?
        let efficiency: Double?
        let trueShootingAtt: Double?
        let fastBreakAtt: Double?
        let fastBreakMade: Double?
        let fastBreakPts: Double?
        let foulsDrawn: Double?
        let offensiveFouls: Double?
        let pointsInPaint: Double?
        let pointsInPaintAtt: Double?
        let pointsInPaintMade: Double?
        let pointsOffTurnovers: Double?
        let secondChanceAtt: Double?
        let secondChanceMade: Double?
        let secondChancePts: Double?
        
        enum CodingKeys: String, CodingKey {
            case minutes, points, rebounds, assists, steals, blocks, turnovers
            case offRebounds = "off_rebounds"
            case defRebounds = "def_rebounds"
            case personalFouls = "personal_fouls"
            case flagrantFouls = "flagrant_fouls"
            case blockedAtt = "blocked_att"
            case fieldGoalsMade = "field_goals_made"
            case fieldGoalsAtt = "field_goals_att"
            case threePointsMade = "three_points_made"
            case threePointsAtt = "three_points_att"
            case freeThrowsMade = "free_throws_made"
            case freeThrowsAtt = "free_throws_att"
            case twoPointsMade = "two_points_made"
            case twoPointsAtt = "two_points_att"
            case efficiency
            case trueShootingAtt = "true_shooting_att"
            case fastBreakAtt = "fast_break_att"
            case fastBreakMade = "fast_break_made"
            case fastBreakPts = "fast_break_pts"
            case foulsDrawn = "fouls_drawn"
            case offensiveFouls = "offensive_fouls"
            case pointsInPaint = "points_in_paint"
            case pointsInPaintAtt = "points_in_paint_att"
            case pointsInPaintMade = "points_in_paint_made"
            case pointsOffTurnovers = "points_off_turnovers"
            case secondChanceAtt = "second_chance_att"
            case secondChanceMade = "second_chance_made"
            case secondChancePts = "second_chance_pts"
        }
    }
}

/// Sportradar Standings Response
struct SportradarStandingsDTO: Codable {
    let season: String?
    let teams: [SportradarTeamStandingDTO]?
    
    struct SportradarTeamStandingDTO: Codable {
        let team: SportradarTeamDTO?
        let teamId: String?
        let wins: Int?
        let losses: Int?
        let winPercentage: Double?
        let conference: String?
        let division: String?
        let rank: Int?
    }
}

/// Sportradar Schedule Response
struct SportradarScheduleDTO: Codable {
    let date: String?
    let league: SportradarLeagueDTO?
    let games: [SportradarGameDTO]?
}

/// Sportradar Daily Changes Response
struct SportradarDailyChangesDTO: Codable {
    let date: String?
    let teams: [String]? // Array of team IDs
    let players: [String]? // Array of player IDs
    let games: [String]? // Array of game IDs
    let standings: Bool?
    let statistics: Bool?
}

// MARK: - Player Profile DTOs

/// Sportradar Player Profile Response - matches actual API structure
struct SportradarPlayerProfileDTO: Codable {
    let id: String
    let status: String?
    let fullName: String?
    let firstName: String?
    let lastName: String?
    let abbrName: String?
    let height: Int? // Height in inches
    let weight: Int? // Weight in pounds
    let position: String?
    let primaryPosition: String?
    let jerseyNumber: String?
    let college: String?
    let highSchool: String?
    let birthPlace: String?
    let birthdate: String? // YYYY-MM-DD format
    let updated: String? // ISO 8601 date string
    let league: SportradarLeagueDTO?
    let team: SportradarTeamReferenceDTO?
    let references: [SportradarPlayerReferenceDTO]?
    let seasons: [SportradarPlayerSeasonDTO]?
    
    enum CodingKeys: String, CodingKey {
        case id, status, position, college, league, team, references, seasons
        case fullName = "full_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case abbrName = "abbr_name"
        case height, weight
        case primaryPosition = "primary_position"
        case jerseyNumber = "jersey_number"
        case highSchool = "high_school"
        case birthPlace = "birth_place"
        case birthdate, updated
    }
    
    /// Map to app PlayerDTO
    /// - Parameter teamDTO: Team DTO for the player (fetched separately or from team reference)
    func toPlayerDTO(teamDTO: TeamDTO? = nil) -> PlayerDTO {
        let name = fullName ?? "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespaces)
        let jerseyNum = jerseyNumber.flatMap { Int($0) }
        
        // Convert height from inches to string format (e.g., "6'1\"")
        let heightString: String?
        if let heightInches = height {
            let feet = heightInches / 12
            let inches = heightInches % 12
            heightString = "\(feet)'\(inches)\""
        } else {
            heightString = nil
        }
        
        // Map statistics from seasons (use most recent season's averages)
        let stats = mapStatisticsFromSeasons()
        
        // Use provided teamDTO or create from team reference
        let finalTeamDTO: TeamDTO
        if let teamDTO = teamDTO {
            finalTeamDTO = teamDTO
        } else if let teamRef = team {
            finalTeamDTO = TeamDTO(
                id: teamRef.id,
                name: teamRef.name ?? "Unknown Team",
                abbreviation: teamRef.alias ?? "UNK",
                logoURL: nil,
                city: nil,
                conference: nil,
                division: nil,
                wins: nil,
                losses: nil,
                winPercentage: nil
            )
        } else {
            finalTeamDTO = TeamDTO(
                id: "unknown",
                name: "Unknown Team",
                abbreviation: "UNK",
                logoURL: nil,
                city: nil,
                conference: nil,
                division: nil,
                wins: nil,
                losses: nil,
                winPercentage: nil
            )
        }
        
        return PlayerDTO(
            id: id,
            name: name,
            team: finalTeamDTO,
            position: position ?? "Unknown",
            statistics: stats,
            jerseyNumber: jerseyNum,
            height: heightString,
            weight: weight,
            age: calculateAge(from: birthdate),
            college: college,
            photoURL: nil
        )
    }
    
    /// Map statistics from seasons (prefer most recent regular season)
    private func mapStatisticsFromSeasons() -> [StatisticDTO] {
        guard let seasons = seasons else { return [] }
        
        // Find most recent regular season
        let regularSeasons = seasons.filter { $0.type == "REG" }
        guard let mostRecentSeason = regularSeasons.sorted(by: { ($0.year ?? 0) > ($1.year ?? 0) }).first else {
            // Fallback to most recent season of any type
            guard let mostRecentSeason = seasons.sorted(by: { ($0.year ?? 0) > ($1.year ?? 0) }).first else {
                return []
            }
            return mapStatisticsFromSeason(mostRecentSeason)
        }
        
        return mapStatisticsFromSeason(mostRecentSeason)
    }
    
    /// Map statistics from a single season
    private func mapStatisticsFromSeason(_ season: SportradarPlayerSeasonDTO) -> [StatisticDTO] {
        guard let teams = season.teams, let firstTeam = teams.first else { return [] }
        
        // Prefer averages over totals for per-game stats
        let stats = firstTeam.total

        // Ensure total exists for gamesPlayed reference
        let total = firstTeam.total
        
        var statisticDTOs: [StatisticDTO] = []
        
        // Points per game (always include, even if 0)
        statisticDTOs.append(StatisticDTO(
            id: UUID().uuidString,
            name: "Points Per Game",
            value: stats.points,
            category: "scoring",
            unit: "points",
            season: "\(season.year ?? 0) \(season.type ?? "")",
            gamesPlayed: firstTeam.total.gamesPlayed
        ))
        
        // Rebounds per game (always include, even if 0)
        statisticDTOs.append(StatisticDTO(
            id: UUID().uuidString,
            name: "Rebounds Per Game",
            value: stats.rebounds,
            category: "rebounding",
            unit: "rebounds",
            season: "\(season.year ?? 0) \(season.type ?? "")",
            gamesPlayed: firstTeam.total.gamesPlayed
        ))
        
        // Assists per game (always include, even if 0)
        statisticDTOs.append(StatisticDTO(
            id: UUID().uuidString,
            name: "Assists Per Game",
            value: stats.assists,
            category: "scoring",
            unit: "assists",
            season: "\(season.year ?? 0) \(season.type ?? "")",
            gamesPlayed: firstTeam.total.gamesPlayed
        ))
        
        // Steals per game (always include, even if 0)
        statisticDTOs.append(StatisticDTO(
            id: UUID().uuidString,
            name: "Steals Per Game",
            value: stats.steals,
            category: "defense",
            unit: "steals",
            season: "\(season.year ?? 0) \(season.type ?? "")",
            gamesPlayed: firstTeam.total.gamesPlayed
        ))
        
        // Blocks per game (always include, even if 0)
        statisticDTOs.append(StatisticDTO(
            id: UUID().uuidString,
            name: "Blocks Per Game",
            value: stats.blocks,
            category: "defense",
            unit: "blocks",
            season: "\(season.year ?? 0) \(season.type ?? "")",
            gamesPlayed: firstTeam.total.gamesPlayed
        ))
        
        // Field goal percentage (always include if attempts > 0)
        if firstTeam.total.fieldGoalsAtt > 0 {
            statisticDTOs.append(StatisticDTO(
                id: UUID().uuidString,
                name: "Field Goal Percentage",
                value: firstTeam.total.fieldGoalsPct * 100, // Convert to percentage
                category: "shooting",
                unit: "percentage",
                season: "\(season.year ?? 0) \(season.type ?? "")",
                gamesPlayed: firstTeam.total.gamesPlayed
            ))
        }
        
        // Three point percentage (always include if attempts > 0)
        if firstTeam.total.threePointsAtt > 0 {
            statisticDTOs.append(StatisticDTO(
                id: UUID().uuidString,
                name: "Three Point Percentage",
                value: firstTeam.total.threePointsPct * 100, // Convert to percentage
                category: "shooting",
                unit: "percentage",
                season: "\(season.year ?? 0) \(season.type ?? "")",
                gamesPlayed: firstTeam.total.gamesPlayed
            ))
        }
        
        // Free throw percentage (always include if attempts > 0)
        if firstTeam.total.freeThrowsAtt > 0 {
            statisticDTOs.append(StatisticDTO(
                id: UUID().uuidString,
                name: "Free Throw Percentage",
                value: firstTeam.total.freeThrowsPct * 100, // Convert to percentage
                category: "shooting",
                unit: "percentage",
                season: "\(season.year ?? 0) \(season.type ?? "")",
                gamesPlayed: firstTeam.total.gamesPlayed
            ))
        }
        
        return statisticDTOs
    }
    
    /// Calculate age from birthdate
    private func calculateAge(from birthdate: String?) -> Int? {
        guard let birthdate = birthdate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let birthDate = formatter.date(from: birthdate) else { return nil }
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year
    }
}

struct SportradarPlayerReferenceDTO: Codable {
    let sourceId: String?
    let scope: String?
    let idType: String?
    
    enum CodingKeys: String, CodingKey {
        case scope
        case sourceId = "source_id"
        case idType = "id_type"
    }
}

struct SportradarPlayerSeasonDTO: Codable {
    let id: String?
    let year: Int?
    let type: String? // "REG", "PRE", "PST"
    let teams: [SportradarPlayerSeasonTeamDTO]?
}

struct SportradarPlayerSeasonTeamDTO: Codable {
    let id: String?
    let name: String?
    let alias: String?
    let total: SportradarPlayerSeasonStatisticsDTO
    let average: SportradarPlayerSeasonStatisticsDTO
}

struct SportradarPlayerSeasonStatisticsDTO: Codable {
    // Games - Core stats, always present
    let gamesPlayed: Int
    let gamesStarted: Int
    let minutes: Double
    
    // Shooting - Core stats, always present
    let fieldGoalsMade: Double
    let fieldGoalsAtt: Double
    let fieldGoalsPct: Double
    let twoPointsMade: Double
    let twoPointsAtt: Double
    let twoPointsPct: Double
    let threePointsMade: Double
    let threePointsAtt: Double
    let threePointsPct: Double
    let blockedAtt: Double
    let freeThrowsMade: Double
    let freeThrowsAtt: Double
    let freeThrowsPct: Double
    
    // Rebounding - Core stats, always present
    let offensiveRebounds: Double
    let defensiveRebounds: Double
    let rebounds: Double
    
    // Core stats - Always present
    let assists: Double
    let turnovers: Double
    let assistsTurnoverRatio: Double
    let steals: Double
    let blocks: Double
    let personalFouls: Double
    let points: Double
    
    // Optional stats - Rare events or advanced metrics
    let techFouls: Double?
    let flagrantFouls: Double?
    let ejections: Double?
    let foulouts: Double?
    let techFoulsNonUnsportsmanlike: Double?
    
    // Advanced stats
    let trueShootingAtt: Double?
    let trueShootingPct: Double?
    let efficiency: Double?
    let fieldGoalsAtRimMade: Double?
    let fieldGoalsAtRimAtt: Double?
    let fieldGoalsAtRimPct: Double?
    let fieldGoalsAtMidrangeMade: Double?
    let fieldGoalsAtMidrangeAtt: Double?
    let fieldGoalsAtMidrangePct: Double?
    let usagePct: Double?
    let awardedPoints: Double?
    let coachEjections: Double?
    let coachTechFouls: Double?
    let doubleDoubles: Double?
    let effectiveFgPct: Double?
    let fastBreakAtt: Double?
    let fastBreakMade: Double?
    let fastBreakPct: Double?
    let fastBreakPts: Double?
    let foulsDrawn: Double?
    let freeThrowPoints: Double?
    let minus: Double?
    let offensiveFouls: Double?
    let plus: Double?
    let pointsInPaint: Double?
    let pointsInPaintAtt: Double?
    let pointsInPaintMade: Double?
    let pointsInPaintPct: Double?
    let pointsOffTurnovers: Double?
    let secondChanceAtt: Double?
    let secondChanceMade: Double?
    let secondChancePct: Double?
    let secondChancePts: Double?
    let tripleDoubles: Double?
    let winningBaskets: Double?
    
    // Average-specific fields (may use different naming)
    let offRebounds: Double? // For averages
    let defRebounds: Double? // For averages
    
    // Custom decoder to provide defaults for non-optional fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Core stats with defaults
        gamesPlayed = try container.decodeIfPresent(Int.self, forKey: .gamesPlayed) ?? 0
        gamesStarted = try container.decodeIfPresent(Int.self, forKey: .gamesStarted) ?? 0
        minutes = try container.decodeIfPresent(Double.self, forKey: .minutes) ?? 0.0
        
        // Shooting stats with defaults
        fieldGoalsMade = try container.decodeIfPresent(Double.self, forKey: .fieldGoalsMade) ?? 0.0
        fieldGoalsAtt = try container.decodeIfPresent(Double.self, forKey: .fieldGoalsAtt) ?? 0.0
        fieldGoalsPct = try container.decodeIfPresent(Double.self, forKey: .fieldGoalsPct) ?? 0.0
        twoPointsMade = try container.decodeIfPresent(Double.self, forKey: .twoPointsMade) ?? 0.0
        twoPointsAtt = try container.decodeIfPresent(Double.self, forKey: .twoPointsAtt) ?? 0.0
        twoPointsPct = try container.decodeIfPresent(Double.self, forKey: .twoPointsPct) ?? 0.0
        threePointsMade = try container.decodeIfPresent(Double.self, forKey: .threePointsMade) ?? 0.0
        threePointsAtt = try container.decodeIfPresent(Double.self, forKey: .threePointsAtt) ?? 0.0
        threePointsPct = try container.decodeIfPresent(Double.self, forKey: .threePointsPct) ?? 0.0
        blockedAtt = try container.decodeIfPresent(Double.self, forKey: .blockedAtt) ?? 0.0
        freeThrowsMade = try container.decodeIfPresent(Double.self, forKey: .freeThrowsMade) ?? 0.0
        freeThrowsAtt = try container.decodeIfPresent(Double.self, forKey: .freeThrowsAtt) ?? 0.0
        freeThrowsPct = try container.decodeIfPresent(Double.self, forKey: .freeThrowsPct) ?? 0.0
        
        // Rebounding stats with defaults
        let offReb = try container.decodeIfPresent(Double.self, forKey: .offensiveRebounds) ?? (try container.decodeIfPresent(Double.self, forKey: .offRebounds) ?? 0.0)
        let defReb = try container.decodeIfPresent(Double.self, forKey: .defensiveRebounds) ?? (try container.decodeIfPresent(Double.self, forKey: .defRebounds) ?? 0.0)
        offensiveRebounds = offReb
        defensiveRebounds = defReb
        rebounds = try container.decodeIfPresent(Double.self, forKey: .rebounds) ?? (offReb + defReb)
        
        // Core stats with defaults
        assists = try container.decodeIfPresent(Double.self, forKey: .assists) ?? 0.0
        turnovers = try container.decodeIfPresent(Double.self, forKey: .turnovers) ?? 0.0
        assistsTurnoverRatio = try container.decodeIfPresent(Double.self, forKey: .assistsTurnoverRatio) ?? 0.0
        steals = try container.decodeIfPresent(Double.self, forKey: .steals) ?? 0.0
        blocks = try container.decodeIfPresent(Double.self, forKey: .blocks) ?? 0.0
        personalFouls = try container.decodeIfPresent(Double.self, forKey: .personalFouls) ?? 0.0
        points = try container.decodeIfPresent(Double.self, forKey: .points) ?? 0.0
        
        // Optional stats
        techFouls = try container.decodeIfPresent(Double.self, forKey: .techFouls)
        flagrantFouls = try container.decodeIfPresent(Double.self, forKey: .flagrantFouls)
        ejections = try container.decodeIfPresent(Double.self, forKey: .ejections)
        foulouts = try container.decodeIfPresent(Double.self, forKey: .foulouts)
        techFoulsNonUnsportsmanlike = try container.decodeIfPresent(Double.self, forKey: .techFoulsNonUnsportsmanlike)
        
        // Advanced stats (optional)
        trueShootingAtt = try container.decodeIfPresent(Double.self, forKey: .trueShootingAtt)
        trueShootingPct = try container.decodeIfPresent(Double.self, forKey: .trueShootingPct)
        efficiency = try container.decodeIfPresent(Double.self, forKey: .efficiency)
        fieldGoalsAtRimMade = try container.decodeIfPresent(Double.self, forKey: .fieldGoalsAtRimMade)
        fieldGoalsAtRimAtt = try container.decodeIfPresent(Double.self, forKey: .fieldGoalsAtRimAtt)
        fieldGoalsAtRimPct = try container.decodeIfPresent(Double.self, forKey: .fieldGoalsAtRimPct)
        fieldGoalsAtMidrangeMade = try container.decodeIfPresent(Double.self, forKey: .fieldGoalsAtMidrangeMade)
        fieldGoalsAtMidrangeAtt = try container.decodeIfPresent(Double.self, forKey: .fieldGoalsAtMidrangeAtt)
        fieldGoalsAtMidrangePct = try container.decodeIfPresent(Double.self, forKey: .fieldGoalsAtMidrangePct)
        usagePct = try container.decodeIfPresent(Double.self, forKey: .usagePct)
        awardedPoints = try container.decodeIfPresent(Double.self, forKey: .awardedPoints)
        coachEjections = try container.decodeIfPresent(Double.self, forKey: .coachEjections)
        coachTechFouls = try container.decodeIfPresent(Double.self, forKey: .coachTechFouls)
        doubleDoubles = try container.decodeIfPresent(Double.self, forKey: .doubleDoubles)
        effectiveFgPct = try container.decodeIfPresent(Double.self, forKey: .effectiveFgPct)
        fastBreakAtt = try container.decodeIfPresent(Double.self, forKey: .fastBreakAtt)
        fastBreakMade = try container.decodeIfPresent(Double.self, forKey: .fastBreakMade)
        fastBreakPct = try container.decodeIfPresent(Double.self, forKey: .fastBreakPct)
        fastBreakPts = try container.decodeIfPresent(Double.self, forKey: .fastBreakPts)
        foulsDrawn = try container.decodeIfPresent(Double.self, forKey: .foulsDrawn)
        freeThrowPoints = try container.decodeIfPresent(Double.self, forKey: .freeThrowPoints)
        minus = try container.decodeIfPresent(Double.self, forKey: .minus)
        offensiveFouls = try container.decodeIfPresent(Double.self, forKey: .offensiveFouls)
        plus = try container.decodeIfPresent(Double.self, forKey: .plus)
        pointsInPaint = try container.decodeIfPresent(Double.self, forKey: .pointsInPaint)
        pointsInPaintAtt = try container.decodeIfPresent(Double.self, forKey: .pointsInPaintAtt)
        pointsInPaintMade = try container.decodeIfPresent(Double.self, forKey: .pointsInPaintMade)
        pointsInPaintPct = try container.decodeIfPresent(Double.self, forKey: .pointsInPaintPct)
        pointsOffTurnovers = try container.decodeIfPresent(Double.self, forKey: .pointsOffTurnovers)
        secondChanceAtt = try container.decodeIfPresent(Double.self, forKey: .secondChanceAtt)
        secondChanceMade = try container.decodeIfPresent(Double.self, forKey: .secondChanceMade)
        secondChancePct = try container.decodeIfPresent(Double.self, forKey: .secondChancePct)
        secondChancePts = try container.decodeIfPresent(Double.self, forKey: .secondChancePts)
        tripleDoubles = try container.decodeIfPresent(Double.self, forKey: .tripleDoubles)
        winningBaskets = try container.decodeIfPresent(Double.self, forKey: .winningBaskets)
        offRebounds = try container.decodeIfPresent(Double.self, forKey: .offRebounds)
        defRebounds = try container.decodeIfPresent(Double.self, forKey: .defRebounds)
    }
    
    enum CodingKeys: String, CodingKey {
        case gamesPlayed = "games_played"
        case gamesStarted = "games_started"
        case minutes
        case fieldGoalsMade = "field_goals_made"
        case fieldGoalsAtt = "field_goals_att"
        case fieldGoalsPct = "field_goals_pct"
        case twoPointsMade = "two_points_made"
        case twoPointsAtt = "two_points_att"
        case twoPointsPct = "two_points_pct"
        case threePointsMade = "three_points_made"
        case threePointsAtt = "three_points_att"
        case threePointsPct = "three_points_pct"
        case blockedAtt = "blocked_att"
        case freeThrowsMade = "free_throws_made"
        case freeThrowsAtt = "free_throws_att"
        case freeThrowsPct = "free_throws_pct"
        case offensiveRebounds = "offensive_rebounds"
        case defensiveRebounds = "defensive_rebounds"
        case rebounds
        case assists, turnovers
        case assistsTurnoverRatio = "assists_turnover_ratio"
        case steals, blocks
        case personalFouls = "personal_fouls"
        case techFouls = "tech_fouls"
        case points, flagrantFouls = "flagrant_fouls"
        case ejections, foulouts
        case techFoulsNonUnsportsmanlike = "tech_fouls_non_unsportsmanlike"
        case trueShootingAtt = "true_shooting_att"
        case trueShootingPct = "true_shooting_pct"
        case efficiency
        case fieldGoalsAtRimMade = "field_goals_at_rim_made"
        case fieldGoalsAtRimAtt = "field_goals_at_rim_att"
        case fieldGoalsAtRimPct = "field_goals_at_rim_pct"
        case fieldGoalsAtMidrangeMade = "field_goals_at_midrange_made"
        case fieldGoalsAtMidrangeAtt = "field_goals_at_midrange_att"
        case fieldGoalsAtMidrangePct = "field_goals_at_midrange_pct"
        case usagePct = "usage_pct"
        case awardedPoints = "awarded_points"
        case coachEjections = "coach_ejections"
        case coachTechFouls = "coach_tech_fouls"
        case doubleDoubles = "double_doubles"
        case effectiveFgPct = "effective_fg_pct"
        case fastBreakAtt = "fast_break_att"
        case fastBreakMade = "fast_break_made"
        case fastBreakPct = "fast_break_pct"
        case fastBreakPts = "fast_break_pts"
        case foulsDrawn = "fouls_drawn"
        case freeThrowPoints = "free_throw_points"
        case minus, offensiveFouls = "offensive_fouls"
        case plus
        case pointsInPaint = "points_in_paint"
        case pointsInPaintAtt = "points_in_paint_att"
        case pointsInPaintMade = "points_in_paint_made"
        case pointsInPaintPct = "points_in_paint_pct"
        case pointsOffTurnovers = "points_off_turnovers"
        case secondChanceAtt = "second_chance_att"
        case secondChanceMade = "second_chance_made"
        case secondChancePct = "second_chance_pct"
        case secondChancePts = "second_chance_pts"
        case tripleDoubles = "triple_doubles"
        case winningBaskets = "winning_baskets"
        case offRebounds = "off_rebounds"
        case defRebounds = "def_rebounds"
    }
}

// MARK: - Injuries Response DTOs

/// Sportradar Injuries Response - matches actual API structure
struct SportradarInjuriesResponseDTO: Codable {
    let league: SportradarLeagueDTO?
    let teams: [SportradarTeamInjuriesDTO]
    
    /// Map to domain model
    func toDomain() throws -> LeagueInjuries {
        guard let leagueDTO = league else {
            throw SportradarDTOMappingError.missingRequiredField("league", context: "injuries response")
        }
        
        let teams = try self.teams.map { try $0.toDomain() }
        
        return LeagueInjuries(
            id: leagueDTO.id ?? UUID().uuidString,
            name: leagueDTO.name ?? "Unknown League",
            alias: leagueDTO.alias,
            teams: teams
        )
    }
}

/// Sportradar Team Injuries DTO
struct SportradarTeamInjuriesDTO: Codable {
    let id: String
    let name: String
    let franchiseId: String?
    let players: [SportradarPlayerInjuriesDTO]
    
    enum CodingKeys: String, CodingKey {
        case id, name, players
        case franchiseId = "franchise_id"
    }
    
    /// Map to domain model
    func toDomain() throws -> TeamInjuries {
        let players = try self.players.map { try $0.toDomain() }
        
        return TeamInjuries(
            id: id,
            name: name,
            franchiseId: franchiseId,
            players: players
        )
    }
}

/// Sportradar Player with Injuries DTO
struct SportradarPlayerInjuriesDTO: Codable {
    let id: String
    let fullName: String
    let firstName: String?
    let lastName: String?
    let position: String
    let primaryPosition: String?
    let jerseyNumber: String?
    let injuries: [SportradarInjuryDTO]
    
    enum CodingKeys: String, CodingKey {
        case id, position, injuries
        case fullName = "full_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case primaryPosition = "primary_position"
        case jerseyNumber = "jersey_number"
    }
    
    /// Map to domain model
    func toDomain() throws -> PlayerWithInjuries {
        let injuries = try self.injuries.map { try $0.toDomain() }
        
        return PlayerWithInjuries(
            id: id,
            fullName: fullName,
            firstName: firstName,
            lastName: lastName,
            position: position,
            primaryPosition: primaryPosition,
            jerseyNumber: jerseyNumber,
            injuries: injuries
        )
    }
}

/// Sportradar Injury DTO
struct SportradarInjuryDTO: Codable {
    let id: String
    let comment: String?
    let desc: String
    let status: String
    let startDate: String?
    let updateDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id, comment, desc, status
        case startDate = "start_date"
        case updateDate = "update_date"
    }
    
    /// Map to domain model
    func toDomain() throws -> Injury {
        // Parse injury status
        guard let injuryStatus = InjuryStatus(rawValue: status) else {
            throw SportradarDTOMappingError.invalidStatus(status, context: "injury '\(id)'")
        }
        
        // Parse dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startDateParsed = startDate.flatMap { dateFormatter.date(from: $0) }
        let updateDateParsed = updateDate.flatMap { dateFormatter.date(from: $0) }
        
        return Injury(
            id: id,
            comment: comment,
            description: desc,
            status: injuryStatus,
            startDate: startDateParsed,
            updateDate: updateDateParsed
        )
    }
}

// MARK: - League Hierarchy Response DTOs

/// Sportradar League Hierarchy Response - matches actual API structure
struct SportradarLeagueHierarchyDTO: Codable {
    let league: SportradarLeagueDTO?
    let conferences: [SportradarConferenceDTO]
    
    /// Map to array of TeamDTO
    func toTeamDTOs() -> [TeamDTO] {
        conferences.flatMap { conference in
            conference.teams.map { team in
                team.toTeamDTO(conference: conference.name)
            }
        }
    }
}

/// Sportradar Conference DTO
struct SportradarConferenceDTO: Codable {
    let id: String?
    let name: String?
    let alias: String?
    let teams: [SportradarHierarchyTeamDTO]
}

/// Sportradar Team in Hierarchy - includes detailed team information
struct SportradarHierarchyTeamDTO: Codable {
    let id: String
    let name: String
    let alias: String?
    let franchiseId: String?
    let founded: Int?
    let sponsor: String?
    let championshipsWon: Int?
    let championshipSeasons: String?
    let playoffAppearances: Int?
    let teamColors: [SportradarTeamColorDTO]?
    let venue: SportradarVenueDetailDTO?
    
    enum CodingKeys: String, CodingKey {
        case id, name, alias, founded, sponsor, venue
        case franchiseId = "franchise_id"
        case championshipsWon = "championships_won"
        case championshipSeasons = "championship_seasons"
        case playoffAppearances = "playoff_appearances"
        case teamColors = "team_colors"
    }
    
    /// Map to app TeamDTO
    func toTeamDTO(conference: String?) -> TeamDTO {
        TeamDTO(
            id: id,
            name: name,
            abbreviation: alias ?? name.prefix(3).uppercased(),
            logoURL: nil, // Hierarchy doesn't include logo URL
            city: venue?.city,
            conference: conference,
            division: nil, // Hierarchy doesn't include division
            wins: nil,
            losses: nil,
            winPercentage: nil
        )
    }
}

/// Sportradar Team Color DTO
struct SportradarTeamColorDTO: Codable {
    let type: String? // "primary" or "secondary"
    let hexColor: String?
    let rgbColor: SportradarRGBColorDTO?
    
    enum CodingKeys: String, CodingKey {
        case type
        case hexColor = "hex_color"
        case rgbColor = "rgb_color"
    }
}

/// Sportradar RGB Color DTO
struct SportradarRGBColorDTO: Codable {
    let red: Int?
    let green: Int?
    let blue: Int?
}
