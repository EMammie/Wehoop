//
//  LeadersViewV2.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// LeadersView variant matching mockup design
struct LeadersViewV2: View {
  @StateObject private var viewModel: LeadersViewModel
  @State private var selectedCategory: StatCategory = .scoring
  @Environment(\.theme) private var theme

  init(viewModel: LeadersViewModel? = nil) {
      if let viewModel = viewModel {
          _viewModel = StateObject(wrappedValue: viewModel)
      } else {
        _viewModel = StateObject(wrappedValue: LeadersViewModel(getStatLeadersUseCase: GetStatLeadersUseCase(leagueLeadersRepository: LeagueLeadersRepositoryImpl(leagueLeaderDataSource:MockLeagueLeadersDataStore(bundle: nil, simulatedDelay: 0.01), localDataSource: JSONLocalDataSource(), cacheService: MemoryCacheService()))))
      }
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
          // Category picker
        StatCategoryPicker(selectedCategory: $selectedCategory) { category in
          withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            viewModel.loadLeaders(category: category)
          }
        }
          .padding(.horizontal)
          .padding(.top, 8)
          .background(Color.clear) // Ensure it has a background
            // Category Picker pinned at the top

            // Content area - takes remaining space
              leadersListView
              .frame(maxWidth: .infinity, maxHeight: .infinity) // Take remaining space
        }

    }
          .navigationTitle("Top Players")
          .task {
              if viewModel.leaders.isEmpty {
                  viewModel.loadLeaders(category: selectedCategory)
              }
          }
      }
  
@ViewBuilder
  private var leadersListView : some View {
        if viewModel.isLoading && viewModel.leaders.isEmpty {
            LoadingView()
        } else if let error = viewModel.error {
            ErrorView(error: error) {
                viewModel.loadLeaders(category: selectedCategory)
            }
        } else if !viewModel.hasLeaders {
            EmptyStateView(
                title: "No Leaders",
                message: "No players found.",
                systemImage: "trophy"
            )
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    // Top 5 ranked list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Players")
                            .font(theme.typography.headline)
                            .foregroundColor(theme.colorScheme.foreground)
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))

                        ForEach(Array(viewModel.leaders.prefix(5).enumerated()), id: \.element.id) { index, player in
                            TopPlayerRowView(
                                player: player,
                                rank: index + 1,
                                statValue: player.statistic(for: selectedCategory)?.formattedValue ?? "0.0",
                                statLabel: statLabel(for: selectedCategory)
                            )
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                        }
                    }
                    .padding(.top)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedCategory)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.leaders.map { $0.id })

                    // Featured player section
                    if let topPlayer = viewModel.leaders.first,
                       let stat = topPlayer.statistic(for: selectedCategory) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Players")
                                .font(theme.typography.headline)
                                .foregroundColor(theme.colorScheme.foreground)
                                .padding(.horizontal)
                                .transition(.opacity)

                            FeaturedPlayerCard(
                                player: topPlayer,
                                statValue: stat.formattedValue,
                                statLabel: statLabel(for: selectedCategory)
                            )
                            .padding(.horizontal)
                            .transition(.scale.combined(with: .opacity))
                        }
                        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: selectedCategory)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: topPlayer.id)
                    }
                }
                .padding(.vertical)
            }
            .refreshable {
                viewModel.refreshLeaders()
            }
        }

  }
  
  /// Get stat label for a category
  private func statLabel(for category: StatCategory) -> String {
      switch category {
      case .scoring: return "PPG"
      case .rebounding: return "RPG"
      case .assists: return "APG"
      case .defense: return "SPG"
      case .efficiency: return "EFF"
      case .shooting: return "FG%"
      case .turnovers: return "TO"
      }
  }
}



/// Row view for top player in ranked list
struct TopPlayerRowView: View {
    let player: Player
    let rank: Int
    let statValue: String
    let statLabel: String
    @Environment(\.theme) private var theme
    @Environment(\.teamThemeProvider) private var teamThemeProvider
    
    var body: some View {
        let teamTheme = teamThemeProvider.theme(for: player.team)
        
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundColor(rankColor)
                .frame(width: 40)
                .contentTransition(.numericText())
            
            // Profile picture placeholder
            ZStack {
                Circle()
                    .fill(teamTheme.colorScheme.primary.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(player.name.prefix(1))
                    .font(theme.typography.headline)
                    .foregroundColor(teamTheme.colorScheme.primary)
            }
            
            // Player info
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colorScheme.foreground)
                
                Text(player.team.abbreviation)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colorScheme.secondary)
            }
            
            Spacer()
            
            // Stat value
            VStack(alignment: .trailing, spacing: 4) {
                Text(statValue)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colorScheme.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: statValue)
                
                Text(statLabel)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colorScheme.secondary)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(theme.colorScheme.background)
        .cornerRadius(12)
        .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return theme.colorScheme.primary
        }
    }
}

#Preview {
    let mockRepo = LeagueLeadersRepositoryImpl(
        leagueLeaderDataSource: MockLeagueLeadersDataStore(),
        localDataSource: JSONLocalDataSource(),
        cacheService: MemoryCacheService()
    )
    let viewModel = LeadersViewModel(getStatLeadersUseCase: GetStatLeadersUseCase(leagueLeadersRepository: mockRepo))
    return LeadersViewV2(viewModel: viewModel)
        .environment(\.theme, Theme.wehoop)
        .environment(\.teamThemeProvider, TeamThemeProvider())
}
