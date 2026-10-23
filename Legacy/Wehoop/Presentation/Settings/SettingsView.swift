//
//  SettingsView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Settings view for app configuration
struct SettingsView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        List {
            #if DEBUG
            Section {
                NavigationLink {
                    FeatureFlagsDebugView()
                } label: {
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundColor(theme.colorScheme.accent)
                            Text("Feature Flags")
                            .font(theme.typography.body)
                    }
                }
            } header: {
                Text("Development")
                    .font(theme.typography.headline)
            } footer: {
                Text("Debug options for development and testing.")
                    .font(theme.typography.caption)
            }
            #endif
            
            Section {
                HStack {
                    Text("Version")
                        .font(theme.typography.body)
                    Spacer()
                    Text("1.0.0")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colorScheme.secondary)
                }
            } header: {
                Text("About")
                    .font(theme.typography.headline)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environment(\.theme, Theme.wehoop)
            .environment(\.featureFlagService, UserDefaultsFeatureFlagService())
    }
}
