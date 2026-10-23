//
//  FeatureFlagsDebugView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Debug view for toggling feature flags
struct FeatureFlagsDebugView: View {
    @Environment(\.featureFlagService) private var featureFlagService
    @Environment(\.theme) private var theme
    @State private var flags: [FeatureFlag: Bool] = [:]
    
    var body: some View {
        List {
            Section {
                ForEach(FeatureFlag.allCases, id: \.self) { flag in
                    Toggle(
                        flag.displayName,
                        isOn: Binding(
                            get: { flags[flag] ?? featureFlagService.isEnabled(flag) },
                            set: { newValue in
                                flags[flag] = newValue
                                featureFlagService.setEnabled(flag, enabled: newValue)
                            }
                        )
                    )
                    .font(theme.typography.body)
                }
            } header: {
                Text("Feature Flags")
                    .font(theme.typography.headline)
            } footer: {
                Text("Toggle feature flags to test new UI designs. Changes take effect immediately.")
                    .font(theme.typography.caption)
            }
            
            Section {
                Button(role: .destructive) {
                    featureFlagService.resetAll()
                    // Update local state - after reset, flags return to default (enabled)
                    for flag in FeatureFlag.allCases {
                        flags[flag] = true
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset All Flags")
                            .font(theme.typography.body)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            } header: {
                Text("Actions")
                    .font(theme.typography.headline)
            }
        }
        .navigationTitle("Feature Flags")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Initialize flags state
            for flag in FeatureFlag.allCases {
                flags[flag] = featureFlagService.isEnabled(flag)
            }
        }
    }
}

// MARK: - FeatureFlag Display Name Extension

extension FeatureFlag {
    var displayName: String {
        switch self {
        case .newGamesUI:
            return "New Games UI"
        case .newLeadersUI:
            return "New Leaders UI"
        case .newPlayerProfileUI:
            return "New Player Profile UI"
        case .newTeamProfileUI:
            return "New Team Profile UI"
        case .teamLeadersView:
            return "Team Leaders View"
        case .weekBasedDatePicker:
            return "Week-Based Date Picker"
        case .onboardingScreen:
            return "Onboarding Screen"
        }
    }
}

#Preview {
    NavigationView {
        FeatureFlagsDebugView()
            .environment(\.featureFlagService, UserDefaultsFeatureFlagService())
            .environment(\.theme, Theme.wehoop)
    }
}
