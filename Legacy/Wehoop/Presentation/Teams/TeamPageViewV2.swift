//
//  TeamPageViewV2.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// TeamPageView variant matching mockup design
struct TeamPageViewV2: View {
    @StateObject private var viewModel: TeamPageViewModel
    @Environment(\.theme) private var theme
    @Environment(\.teamThemeProvider) private var themeProvider
    @Environment(\.viewModelFactory) private var factory
    @Environment(\.featureFlagService) private var featureFlagService
    @State private var keyPlayers: [Player] = []
    
    init(teamId: String, viewModel: TeamPageViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            let teamRepo = TeamRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService())
            _viewModel = StateObject(wrappedValue: TeamPageViewModel(teamId: teamId, getTeamPageUseCase: GetTeamPageUseCase(teamRepository: teamRepo, teamId: teamId)))
        }
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    viewModel.loadTeam()
                }
            } else if let team = viewModel.team {
                let teamTheme = themeProvider.theme(for: team)
                
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [
                            teamTheme.colorScheme.primary.opacity(0.3),
                            teamTheme.colorScheme.secondary.opacity(0.2),
                            theme.colorScheme.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Team logo and name
                            teamHeaderSection(team: team, teamTheme: teamTheme)
                            
                            // Team stats in white boxes
                            teamStatsSection(team: team)
                            
                            // Key players or team leaders section (feature flagged)
                            if !keyPlayers.isEmpty {
                                if featureFlagService.isEnabled(.teamLeadersView) {
                                    keyLeadersSection(players: keyPlayers, teamTheme: teamTheme, team: team)
                                } else {
                                    keyPlayersSection(players: keyPlayers, teamTheme: teamTheme)
                                }
                            }
                        }
                        .padding()
                    }
                }
            } else {
                EmptyStateView(
                    title: "Team Not Found",
                    message: "Unable to load team information.",
                    systemImage: "shield"
                )
            }
        }
        .task {
            viewModel.loadTeam()
            await loadKeyPlayers()
        }
    }
    
    private func teamHeaderSection(team: Team, teamTheme: Theme) -> some View {
        VStack(spacing: 16) {
            // Team logo placeholder
            ZStack {
                Circle()
                    .fill(teamTheme.colorScheme.primary.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Text(team.abbreviation)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(teamTheme.colorScheme.primary)
            }
            
            // Team name
            Text(team.name.uppercased())
                .font(theme.typography.title)
                .fontWeight(.bold)
                .foregroundColor(theme.colorScheme.foreground)
        }
        .padding(.top, 20)
    }
    
    private func teamStatsSection(team: Team) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Team Stats")
                .font(theme.typography.headline)
                .foregroundColor(theme.colorScheme.foreground)
            
            HStack(spacing: 12) {
                StatBoxView(
                  value: "\(team.wins ?? 0)-\(team.losses ?? 0)",
                    label: "Record"
                )
                
                StatBoxView(
                    value: calculateStandings(team: team),
                    label: "Standings"
                )
                
                StatBoxView(
                    value: "W+2",
                    label: "Win Streak"
                )
            }
        }
        .padding()
        .background(theme.colorScheme.background)
        .cornerRadius(12)
        .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func keyPlayersSection(players: [Player], teamTheme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Players")
                .font(theme.typography.headline)
                .foregroundColor(theme.colorScheme.foreground)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(players.prefix(4)) { player in
                        VStack(spacing: 8) {
                            // Profile picture placeholder
                            ZStack {
                                Circle()
                                    .fill(teamTheme.colorScheme.primary.opacity(0.2))
                                    .frame(width: 70, height: 70)
                                
                                Text(player.name.prefix(1))
                                    .font(theme.typography.headline)
                                    .foregroundColor(teamTheme.colorScheme.primary)
                            }
                            
                            Text(player.name)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colorScheme.foreground)
                                .lineLimit(1)
                                .frame(width: 80)
                            
                            if let ppg = player.statistic(for: .scoring) {
                                Text("PPG")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colorScheme.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(theme.colorScheme.background)
        .cornerRadius(12)
        .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func keyLeadersSection(players: [Player], teamTheme: Theme, team: Team) -> some View {
        let leadersManager = TeamLeadersManager(players: players)
        let defaultLeaders = leadersManager.defaultLeaders()
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Team Leaders")
                .font(theme.typography.headline)
                .foregroundColor(theme.colorScheme.foreground)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(defaultLeaders, id: \.player.id) { leaderInfo in
//                        LeaderCardView(
//                            player: leaderInfo.player,
//                            category: leaderInfo.category.abbreviation,
//                            value: leaderInfo.category.value(for: leaderInfo.player),
//                            teamTheme: teamTheme
//                        )
                      Text(leaderInfo.player.name)
                    }
                }
            }
        }
        .padding()
        .background(theme.colorScheme.background)
        .cornerRadius(12)
        .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func calculateStandings(team: Team) -> String {
        // Simple calculation - in real app this would come from repository
      guard let winPercentage = team.winPercentage else { return "5th+" }
        if winPercentage >= 0.7 {
            return "1st"
        } else if winPercentage >= 0.6 {
            return "2nd"
        } else if winPercentage >= 0.5 {
            return "3rd"
        } else if winPercentage >= 0.4 {
            return "4th"
        } else {
            return "5th+"
        }
    }
    
    private func loadKeyPlayers() async {
        guard let team = viewModel.team else { return }
        
        do {
            let container: DependencyContainer = factory.container
            let playerRepository: PlayerRepository = container.resolve()
            let allPlayers = try await playerRepository.getPlayers()
            
            // Filter players by team and get top scorers
            let teamPlayers = allPlayers.filter { $0.team.id == team.id }
            let sortedByPPG = teamPlayers.sorted { $0.pointsPerGame > $1.pointsPerGame }
            keyPlayers = Array(sortedByPPG.prefix(4))
        } catch {
            keyPlayers = []
        }
    }
}

// MARK: - Supporting Views

/// Card view for displaying a statistical leader
//private struct LeaderCardView: View {
//    let player: Player
//    let category: String
//    let value: Double
//    let teamTheme: Theme
//    
//    @Environment(\.theme) private var theme
//    
//    var body: some View {
//        VStack(spacing: 8) {
//            // Category badge
//            Text(category.uppercased())
//                .font(.system(size: 10, weight: .bold))
//                .foregroundColor(teamTheme.colorScheme.primary)
//                .padding(.horizontal, 8)
//                .padding(.vertical, 4)
//                .background(teamTheme.colorScheme.primary.opacity(0.15))
//                .cornerRadius(8)
//            
//            // Profile picture placeholder
//            ZStack {
//                Circle()
//                    .fill(teamTheme.colorScheme.primary.opacity(0.2))
//                    .frame(width: 70, height: 70)
//                
//                Text(player.name.prefix(1))
//                    .font(theme.typography.headline)
//                    .foregroundColor(teamTheme.colorScheme.primary)
//            }
//            
//            // Player name
//            Text(player.name)
//                .font(theme.typography.caption)
//                .foregroundColor(theme.colorScheme.foreground)
//                .lineLimit(1)
//                .frame(width: 90)
//            
//            // Stat value
//            Text(String(format: "%.1f", value))
//                .font(.system(size: 20, weight: .bold))
//                .foregroundColor(teamTheme.colorScheme.primary)
//            
//            // Category label
//            Text(category)
//                .font(.system(size: 11))
//                .foregroundColor(theme.colorScheme.secondary)
//        }
//        .padding(.vertical, 8)
//    }
//}

// MARK: - Previews

#Preview {
    let teamRepo = TeamRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService())
    let viewModel = TeamPageViewModel(teamId: "team-6", getTeamPageUseCase: GetTeamPageUseCase(teamRepository: teamRepo, teamId: "team-6"))
    TeamPageViewV2(teamId: "team-6", viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.teamThemeProvider, TeamThemeProvider())
        .environment(\.featureFlagService, UserDefaultsFeatureFlagService())
        .environment(\.dependencyContainer, configureDependencyContainer())
}

#Preview("Mist BC") {
    let teamRepo = TeamRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService())
    let viewModel = TeamPageViewModel(teamId: "team-1", getTeamPageUseCase: GetTeamPageUseCase(teamRepository: teamRepo, teamId: "team-1"))
    TeamPageViewV2(teamId: "team-1", viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.teamThemeProvider, TeamThemeProvider())
        .environment(\.featureFlagService, UserDefaultsFeatureFlagService())
        .environment(\.dependencyContainer, configureDependencyContainer())
}

#Preview("Rose BC") {
    let teamRepo = TeamRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService())
    let viewModel = TeamPageViewModel(teamId: "team-3", getTeamPageUseCase: GetTeamPageUseCase(teamRepository: teamRepo, teamId: "team-3"))
    TeamPageViewV2(teamId: "team-3", viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.teamThemeProvider, TeamThemeProvider())
        .environment(\.featureFlagService, UserDefaultsFeatureFlagService())
        .environment(\.dependencyContainer, configureDependencyContainer())
}

#Preview("Phantom BC") {
    let teamRepo = TeamRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService())
    let viewModel = TeamPageViewModel(teamId: "team-5", getTeamPageUseCase: GetTeamPageUseCase(teamRepository: teamRepo, teamId: "team-5"))
    TeamPageViewV2(teamId: "team-5", viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.teamThemeProvider, TeamThemeProvider())
        .environment(\.featureFlagService, UserDefaultsFeatureFlagService())
        .environment(\.dependencyContainer, configureDependencyContainer())
}

#Preview("With Key Players") {
    let teamRepo = TeamRepositoryImpl(
        remoteDataSource: MockRemoteDataSource(),
        localDataSource: JSONLocalDataSource(),
        cacheService: MemoryCacheService()
    )
    let viewModel = TeamPageViewModel(
        teamId: "team-1",
        getTeamPageUseCase: GetTeamPageUseCase(teamRepository: teamRepo, teamId: "team-1")
    )
    
    // Pre-load the team data so the view doesn't need to wait
    Task {
        await viewModel.loadTeam()
    }
    
    return TeamPageViewV2(teamId: "team-1", viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.teamThemeProvider, TeamThemeProvider())
        .environment(\.featureFlagService, UserDefaultsFeatureFlagService())
        .environment(\.dependencyContainer, configureDependencyContainer())
}

#Preview("With Team Leaders (Feature Flag)") {
    let teamRepo = TeamRepositoryImpl(
        remoteDataSource: MockRemoteDataSource(),
        localDataSource: JSONLocalDataSource(),
        cacheService: MemoryCacheService()
    )
    let viewModel = TeamPageViewModel(
        teamId: "team-1",
        getTeamPageUseCase: GetTeamPageUseCase(teamRepository: teamRepo, teamId: "team-1")
    )
    
    // Create a feature flag service with the feature enabled
    let featureFlagService = UserDefaultsFeatureFlagService()
    featureFlagService.setEnabled(.teamLeadersView, enabled: true)
    
    // Pre-load the team data
    Task {
        await viewModel.loadTeam()
    }
    
    return TeamPageViewV2(teamId: "team-1", viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.teamThemeProvider, TeamThemeProvider())
        .environment(\.featureFlagService, featureFlagService)
        .environment(\.dependencyContainer, configureDependencyContainer())
}

