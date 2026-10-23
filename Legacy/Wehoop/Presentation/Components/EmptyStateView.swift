//
//  EmptyStateView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Reusable empty state view
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    
    init(title: String = "No Data", message: String, systemImage: String) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
