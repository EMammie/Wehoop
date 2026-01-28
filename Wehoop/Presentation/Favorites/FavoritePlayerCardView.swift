//
//  FavoritePlayerCardView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Card view for displaying a favorite player
struct FavoritePlayerCardView: View {
    let player: Player
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Player info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(player.displayName)
                        .font(.headline)
                }
                
                HStack(spacing: 12) {
                    Text(player.team.abbreviation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                
                        Text("• \(player.positionAbbreviation)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                }
                
                // Key stats
                HStack(spacing: 16) {
                    if player.pointsPerGame > 0 {
                        statBadge(label: "PTS", value: String(format: "%.1f", player.pointsPerGame))
                    }
                    if player.reboundsPerGame > 0 {
                        statBadge(label: "REB", value: String(format: "%.1f", player.reboundsPerGame))
                    }
                    if player.assistsPerGame > 0 {
                        statBadge(label: "AST", value: String(format: "%.1f", player.assistsPerGame))
                    }
                }
            }
            
            Spacer()
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: player.id)
    }
    
    private func statBadge(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
