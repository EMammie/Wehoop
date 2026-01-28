//
//  TeamsViewModel.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine

/// ViewModel for TeamsView
@MainActor
class TeamsViewModel: ObservableObject {
    @Published var teams: [Team] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText: String = ""
    
    private let teamRepository: TeamRepository
    
    init(teamRepository: TeamRepository) {
        self.teamRepository = teamRepository
    }
    
    func loadTeams() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let loadedTeams = try await teamRepository.getTeams()
                self.teams = loadedTeams.sorted { $0.name < $1.name }
                self.isLoading = false
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func refreshTeams() {
        loadTeams()
    }
    
    var filteredTeams: [Team] {
        if searchText.isEmpty {
            return teams
        }
        return teams.filter { team in
            team.name.localizedCaseInsensitiveContains(searchText) ||
            team.abbreviation.localizedCaseInsensitiveContains(searchText) ||
            (team.city?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var hasTeams: Bool {
        !filteredTeams.isEmpty
    }
}
