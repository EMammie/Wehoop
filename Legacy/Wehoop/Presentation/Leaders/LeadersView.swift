//
//  LeadersView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// View for displaying statistic leaders
struct LeadersView: View {
    @StateObject private var viewModel: LeadersViewModel
    @Environment(\.theme) private var theme
    @Environment(\.featureFlagService) private var featureFlagService
    
    init(viewModel: LeadersViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            // Fallback - should be provided by parent
          _viewModel = StateObject(wrappedValue: LeadersViewModel(getStatLeadersUseCase: GetStatLeadersUseCase(leagueLeadersRepository: LeagueLeadersRepositoryImpl(leagueLeaderDataSource:MockLeagueLeadersDataStore(), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService()))))
        }
    }
    
    var body: some View {
        if featureFlagService.isEnabled(.newLeadersUI) {
            LeadersViewV2(viewModel: viewModel)
        } else {
            leadersViewContent
        }
    }
    
    private var leadersViewContent: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category picker
                categoryPicker
                .padding(.horizontal)
                .padding(.top, 8)
                .background(Color.clear) // Ensure it has a background
                  // Category Picker pinned at the top

                  // Content area - takes remaining space
                    leaderListView
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Take remaining space
              }

        }
    .navigationTitle("Leaders")
    .task {
    if viewModel.leaders.isEmpty {
        viewModel.loadLeaders(category: .scoring)
    }
}
  }

  @ViewBuilder
  private var leaderListView: some View {
    // Leaders list

        if viewModel.isLoading && viewModel.leaders.isEmpty {
            LoadingView()
        } else if let error = viewModel.error {
            ErrorView(error: error) {
                viewModel.loadLeaders(category: viewModel.selectedCategory)
            }
        } else if !viewModel.hasLeaders {
            EmptyStateView(
                title: "No Leaders",
                message: "No players found for this category.",
                systemImage: "trophy"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(viewModel.leaders.enumerated()), id: \.element.id) { index, player in
                        LeaderCardView(
                            player: player,
                            rank: index + 1,
                            category: viewModel.selectedCategory
                        )
                        .padding(.horizontal, 16)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.vertical, 16)
            }
            .refreshable {
                viewModel.refreshLeaders()
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedCategory)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.leaders.map { $0.id })
        }
    }

  private var categoryPicker: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(StatCategory.allCases, id: \.self) { category in
          Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
              viewModel.loadLeaders(category: category)
            }
          }) {
            Text(category.displayName)
              .font(theme.typography.caption)
              .fontWeight(viewModel.selectedCategory == category ? .semibold : .regular)
              .foregroundColor(viewModel.selectedCategory == category ? .white : theme.colorScheme.foreground)
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(viewModel.selectedCategory == category ? theme.colorScheme.accent : theme.colorScheme.secondary.opacity(0.2))
              .cornerRadius(20)
              .scaleEffect(viewModel.selectedCategory == category ? 1.05 : 1.0)
          }
          .buttonStyle(.plain)
          .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.selectedCategory)
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 8)
    }
    .background(theme.colorScheme.background)
  }
}


#Preview ("No ViewModel") {
  LeadersView(viewModel: nil)
}
