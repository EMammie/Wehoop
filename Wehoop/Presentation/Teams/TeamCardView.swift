//
//  TeamCardView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Card view for displaying a team
struct TeamCardView: View {
    let team: Team
    @Environment(\.teamThemeProvider) private var teamThemeProvider
    
    var body: some View {
        HStack(spacing: 16) {
            // Team logo with fallback to abbreviation circle
            TeamLogoView(team: team, size: 50)
            
            // Team info
            VStack(alignment: .leading, spacing: 8) {
                Text(team.fullName)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    if let conference = team.conference {
                        Text(conference.abbreviation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let record = team.record {
                        Text("• \(record)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: team.id)
    }
}

// MARK: - Team Logo View

/// Reusable team logo view with support for local assets and remote URLs
private struct TeamLogoView: View {
    let team: Team
    let size: CGFloat
    @Environment(\.teamThemeProvider) private var teamThemeProvider
    
    var body: some View {
        let teamTheme = teamThemeProvider.theme(for: team)
        
        ZStack {
            Circle()
                .fill(teamTheme.colorScheme.primary.opacity(0.2))
                .frame(width: size, height: size)
            
            // Priority 1: Try to load from local asset catalog
            if hasLocalAsset(for: team) {
                Image(localAssetName(for: team))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.7, height: size * 0.7)
                    .clipShape(Circle())
            }
            // Priority 2: Try to load from remote URL
            else if let logoURL = team.logoURL, let url = URL(string: logoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: size * 0.6, height: size * 0.6)
                        
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: size * 0.7, height: size * 0.7)
                            .clipShape(Circle())
                        
                    case .failure:
                        fallbackLogoView(teamTheme: teamTheme)
                        
                    @unknown default:
                        fallbackLogoView(teamTheme: teamTheme)
                    }
                }
            }
            // Priority 3: Show fallback
            else {
                fallbackLogoView(teamTheme: teamTheme)
            }
        }
    }
    
    private func fallbackLogoView(teamTheme: Theme) -> some View {
        Text(team.abbreviation)
            .font(.system(size: size * 0.35, weight: .bold))
            .foregroundColor(teamTheme.colorScheme.primary)
    }
    
    /// Returns the asset name for a team logo
    private func localAssetName(for team: Team) -> String {
        "logo-\(team.id)"
    }
    
    /// Checks if a local asset exists for the team
    private func hasLocalAsset(for team: Team) -> Bool {
        let assetName = localAssetName(for: team)
        #if os(iOS)
        return UIImage(named: assetName) != nil
        #elseif os(macOS)
        return NSImage(named: assetName) != nil
        #else
        return false
        #endif
    }
}
// MARK: - Preview

#Preview("Mist BC") {
    TeamCardView(team: GameFixtures.mistBC())
        .padding()
        .environment(\.theme, Theme.wehoop)
        .environment(\.teamThemeProvider, TeamThemeProvider())
}

#Preview("Multiple Teams") {
    VStack(spacing: 12) {
        TeamCardView(team: GameFixtures.mistBC())
        TeamCardView(team: GameFixtures.lunarOwlsBC())
        TeamCardView(team: GameFixtures.roseBC())
        TeamCardView(team: GameFixtures.vinylBC())
    }
    .padding()
    .environment(\.theme, Theme.wehoop)
    .environment(\.teamThemeProvider, TeamThemeProvider())
}

#Preview("Long Team Names") {
    VStack(spacing: 12) {
        TeamCardView(
            team: Team(
                id: "test-1",
                name: "Super Long Team Name Basketball Club",
                abbreviation: "SLTN",
                logoURL: nil,
                city: "Los Angeles",
                conference: .western,
                division: "Pacific",
                wins: 15,
                losses: 5,
                winPercentage: 0.750
            )
        )
        TeamCardView(team: GameFixtures.phantomBC())
    }
    .padding()
    .environment(\.theme, Theme.wehoop)
    .environment(\.teamThemeProvider, TeamThemeProvider())
}

