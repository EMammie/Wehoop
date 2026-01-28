//
//  TeamRepository.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Protocol for team repository operations
protocol TeamRepository {
    func getTeams() async throws -> [Team]
    func getTeam(id: String) async throws -> Team
}
