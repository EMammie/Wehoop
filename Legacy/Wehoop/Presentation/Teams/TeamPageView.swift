//
//  TeamPageView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI
import Combine

/// View for displaying a team's detailed page
struct TeamPageView: View {
    @StateObject private var viewModel: TeamPageViewModel
    @Environment(\.viewModelFactory) private var factory
    @Environment(\.teamThemeProvider) private var themeProvider
    @Environment(\.featureFlagService) private var featureFlagService
    
    init(teamId: String, viewModel: TeamPageViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            // Fallback - should be provided by parent
            let teamRepo = TeamRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService())
            _viewModel = StateObject(wrappedValue: TeamPageViewModel(teamId: teamId, getTeamPageUseCase: GetTeamPageUseCase(teamRepository: teamRepo, teamId: teamId)))
        }
    }
    
    var body: some View {
        if featureFlagService.isEnabled(.newTeamProfileUI) {
            TeamPageViewV2(teamId: viewModel.teamId, viewModel: viewModel)
        } else {
            teamPageViewContent
        }
    }
    
    private var teamPageViewContent: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    viewModel.loadTeam()
                }
            } else if let team = viewModel.team {
                let teamTheme = themeProvider.theme(for: team)
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        headerSection(team: team, theme: teamTheme)
                        
                        // Team info
                        teamInfoSection(team: team, theme: teamTheme)
                    }
                    .padding()
                }
                .background(teamTheme.colorScheme.background)
            } else {
                EmptyStateView(
                    title: "Team Not Found",
                    message: "Unable to load team information.",
                    systemImage: "shield.slash"
                )
            }
        }
        .navigationTitle(viewModel.team?.name ?? "Team")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.loadTeam()
        }
    }
    
    private func headerSection(team: Team, theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(theme.colorScheme.primary.opacity(0.2))
                        .frame(width: 80, height: 80)
                    Text(team.abbreviation)
                        .font(theme.typography.title)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colorScheme.primary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(team.fullName)
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colorScheme.foreground)
                    
                    if let conference = team.conference {
                        Text(conference.rawValue)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colorScheme.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(theme.colorScheme.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func teamInfoSection(team: Team, theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Team Information")
                .font(theme.typography.headline)
                .foregroundColor(theme.colorScheme.foreground)
            
            if let record = team.record {
                infoRow(label: "Record", value: record, theme: theme)
            }
            
            if let winPercentage = team.formattedWinPercentage {
                infoRow(label: "Win Percentage", value: winPercentage, theme: theme)
            }
            
            if let division = team.division {
                infoRow(label: "Division", value: division, theme: theme)
            }
        }
        .padding()
        .background(theme.colorScheme.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func infoRow(label: String, value: String, theme: Theme) -> some View {
        HStack {
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colorScheme.secondary)
            Spacer()
            Text(value)
                .font(theme.typography.body)
                .fontWeight(.semibold)
                .foregroundColor(theme.colorScheme.foreground)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Team Page - Laces BC") {
    let teamRepo = TeamRepositoryImpl(
        remoteDataSource: MockRemoteDataSource(),
        localDataSource: JSONLocalDataSource(),
        cacheService: MemoryCacheService()
    )
    let viewModel = TeamPageViewModel(
        teamId: "team-6",
        getTeamPageUseCase: GetTeamPageUseCase(teamRepository: teamRepo, teamId: "team-6")
    )
    let container = configureDependencyContainer()
    let factory = ViewModelFactory(container: container)
    
    TeamPageView(teamId: "team-6", viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.teamThemeProvider, TeamThemeProvider())
        .environment(\.dependencyContainer, configureDependencyContainer())

}

#Preview("Team Page - Mist BC") {
    let teamRepo = TeamRepositoryImpl(
        remoteDataSource: MockRemoteDataSource(),
        localDataSource: JSONLocalDataSource(),
        cacheService: MemoryCacheService()
    )
    let viewModel = TeamPageViewModel(
        teamId: "team-1",
        getTeamPageUseCase: GetTeamPageUseCase(teamRepository: teamRepo, teamId: "team-1")
    )
    let container = configureDependencyContainer()
    let factory = ViewModelFactory(container: container)
    
    TeamPageView(teamId: "team-1", viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.teamThemeProvider, TeamThemeProvider())
        .environment(\.dependencyContainer, configureDependencyContainer())
}

#Preview("Loading State") {
    let teamRepo = TeamRepositoryImpl(
        remoteDataSource: MockRemoteDataSource(),
        localDataSource: JSONLocalDataSource(),
        cacheService: MemoryCacheService()
    )
    let viewModel = TeamPageViewModel(
        teamId: "team-1",
        getTeamPageUseCase: GetTeamPageUseCase(teamRepository: teamRepo, teamId: "team-1")
    )
    let container = configureDependencyContainer()
    let factory = ViewModelFactory(container: container)
    
    TeamPageView(teamId: "team-1", viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.teamThemeProvider, TeamThemeProvider())
        .environment(\.dependencyContainer, configureDependencyContainer())
}

/// ViewModel for TeamPageView
@MainActor
class TeamPageViewModel: ObservableObject {
    @Published var team: Team?
    @Published var isLoading = false
    @Published var error: Error?
    
    let teamId: String
    private let getTeamPageUseCase: GetTeamPageUseCase
    
    init(teamId: String, getTeamPageUseCase: GetTeamPageUseCase) {
        self.teamId = teamId
        self.getTeamPageUseCase = getTeamPageUseCase
    }
    
    func loadTeam() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let loadedTeam = try await getTeamPageUseCase.execute()
                self.team = loadedTeam
                self.isLoading = false
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
}
