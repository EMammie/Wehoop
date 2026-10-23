//
//  TeamsView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// View for displaying teams list
struct TeamsView: View {
    @StateObject private var viewModel: TeamsViewModel
    @Environment(\.viewModelFactory) private var factory
    
    init(viewModel: TeamsViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            // Fallback - should be provided by parent
            _viewModel = StateObject(wrappedValue: TeamsViewModel(teamRepository: TeamRepositoryImpl(remoteDataSource: MockRemoteDataSource(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService())))
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Teams list
                Group {
                    if viewModel.isLoading && viewModel.teams.isEmpty {
                        LoadingView()
                    } else if let error = viewModel.error {
                        ErrorView(error: error) {
                            viewModel.loadTeams()
                        }
                    } else if !viewModel.hasTeams {
                        EmptyStateView(
                            title: "No Teams",
                            message: viewModel.searchText.isEmpty ? "No teams found." : "No teams match your search.",
                            systemImage: "shield"
                        )
                    } else {
                        CardFeedView(
                            items: viewModel.filteredTeams,
                            spacing: 12,
                            onRefresh: {
                                viewModel.refreshTeams()
                            },
                            emptyStateTitle: "No Teams",
                            emptyStateMessage: viewModel.searchText.isEmpty ? "No teams found." : "No teams match your search.",
                            emptyStateImage: "shield"
                        ) { team in
                            NavigationLink(destination: TeamPageView(teamId: team.id, viewModel: factory.makeTeamPageViewModel(teamId: team.id))) {
                                TeamCardView(team: team)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("Teams")
            .task {
                if viewModel.teams.isEmpty {
                    viewModel.loadTeams()
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search teams...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
// MARK: - Preview

#Preview("Teams List") {
    let teamRepo = TeamRepositoryImpl(
        remoteDataSource: MockRemoteDataSource(),
        localDataSource: JSONLocalDataSource(),
        cacheService: MemoryCacheService()
    )
    let viewModel = TeamsViewModel(teamRepository: teamRepo)
    
    return TeamsView(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.dependencyContainer, configureDependencyContainer())
        .environment(\.teamThemeProvider, TeamThemeProvider())
        .task {
            await viewModel.loadTeams()
        }
}

#Preview("Loading State") {
    let teamRepo = TeamRepositoryImpl(
        remoteDataSource: MockRemoteDataSource(),
        localDataSource: JSONLocalDataSource(),
        cacheService: MemoryCacheService()
    )
    let viewModel = TeamsViewModel(teamRepository: teamRepo)
    
    return TeamsView(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.dependencyContainer, configureDependencyContainer())
        .environment(\.teamThemeProvider, TeamThemeProvider())
}

#Preview("With Search") {
    let teamRepo = TeamRepositoryImpl(
        remoteDataSource: MockRemoteDataSource(),
        localDataSource: JSONLocalDataSource(),
        cacheService: MemoryCacheService()
    )
    let viewModel = TeamsViewModel(teamRepository: teamRepo)
    viewModel.searchText = "Mist"
    
   return TeamsView(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.dependencyContainer, configureDependencyContainer())
        .environment(\.teamThemeProvider, TeamThemeProvider())
        .task {
            await viewModel.loadTeams()
        }
}

