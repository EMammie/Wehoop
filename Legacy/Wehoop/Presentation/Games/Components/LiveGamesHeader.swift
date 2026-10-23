//
//  LiveGamesHeader.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Header view for live games section
struct LiveGamesHeader: View {
    var body: some View {
        HStack {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            Text("Live")
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

#Preview {
    LiveGamesHeader()
        .padding()
        .background(Color(.systemBackground))
}
