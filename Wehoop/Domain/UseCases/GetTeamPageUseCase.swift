//
//  GetTeamPageUseCase.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Use case for retrieving a team's page data
class GetTeamPageUseCase {
    private let teamRepository: TeamRepository
    private let teamId: String
    
    init(teamRepository: TeamRepository, teamId: String) {
        self.teamRepository = teamRepository
        self.teamId = teamId
    }
    
    func execute() async throws -> Team {
        return try await teamRepository.getTeam(id: teamId)
    }
}
