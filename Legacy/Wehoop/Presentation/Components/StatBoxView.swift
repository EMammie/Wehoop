//
//  StatBoxView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// White box component for displaying stats
struct StatBoxView: View {
    let value: String
    let label: String
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundColor(theme.colorScheme.foreground)
            
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colorScheme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HStack(spacing: 12) {
        StatBoxView(value: "10-5", label: "Record")
        StatBoxView(value: "4th", label: "Standings")
        StatBoxView(value: "W+2", label: "Win Streak")
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .environment(\.theme, Theme.wehoop)
}
