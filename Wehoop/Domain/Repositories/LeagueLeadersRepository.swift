//
//  LeagueLeadersRepository.swift
//  Unrivaled
//
//  Created by E on 1/2/26.
//

import Foundation

/// Protocol for league leaders repository operations
protocol LeagueLeadersRepository {
    /// Get league leaders for a specific statistical category
    /// - Parameters:
    ///   - category: The statistical category to get leaders for
    ///   - limit: Maximum number of leaders to return (default: 10)
    /// - Returns: Array of players sorted by their statistic value in descending order
    func getLeagueLeaders(category: StatCategory, limit: Int) async throws -> [Player]
}
