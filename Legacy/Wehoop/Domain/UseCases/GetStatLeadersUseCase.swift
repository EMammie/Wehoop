//
//  GetStatLeadersUseCase.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Use case for retrieving statistic leaders
class GetStatLeadersUseCase {
    private let leagueLeadersRepository: LeagueLeadersRepository
    
    init(leagueLeadersRepository: LeagueLeadersRepository) {
        self.leagueLeadersRepository = leagueLeadersRepository
    }
    
    func execute(category: StatCategory, limit: Int = 10) async throws -> [Player] {
        return try await leagueLeadersRepository.getLeagueLeaders(category: category, limit: limit)
    }
}
