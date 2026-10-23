//
//  MockTeamRepository.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import Foundation
@testable import Wehoop

/// Mock implementation of TeamRepository for testing
class MockTeamRepository: TeamRepository {
    var teams: [Team] = []
    var getTeamsError: Error?
    var getTeamError: Error?
    var getTeamsCallCount = 0
    var getTeamCallCount = 0
    
    func getTeams() async throws -> [Team] {
        getTeamsCallCount += 1
        if let error = getTeamsError {
            throw error
        }
        return teams
    }
    
    func getTeam(id: String) async throws -> Team {
        getTeamCallCount += 1
        if let error = getTeamError {
            throw error
        }
        guard let team = teams.first(where: { $0.id == id }) else {
            throw NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Team not found"])
        }
        return team
    }
}
