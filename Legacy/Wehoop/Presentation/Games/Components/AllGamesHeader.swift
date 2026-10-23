//
//  AllGamesHeader.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Header view for all games section
struct AllGamesHeader: View {
    let hasLiveGames: Bool
    
    var body: some View {
        HStack {
            Text("All Games")
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, hasLiveGames ? 16 : 8)
    }
}

#Preview("With Live Games") {
    AllGamesHeader(hasLiveGames: true)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Without Live Games") {
    AllGamesHeader(hasLiveGames: false)
        .padding()
        .background(Color(.systemBackground))
}
