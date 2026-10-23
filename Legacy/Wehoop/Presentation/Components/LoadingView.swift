//
//  LoadingView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Reusable loading indicator view
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .opacity(isAnimating ? 1.0 : 0.5)
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .opacity(isAnimating ? 1.0 : 0.5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
