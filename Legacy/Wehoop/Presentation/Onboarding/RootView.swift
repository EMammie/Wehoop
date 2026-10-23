//
//  RootView.swift
//  Wehoop
//
//  Created by E on 1/26/26.
//

import SwiftUI

/// Root view that conditionally shows onboarding or main app based on feature flag and completion state
struct RootView: View {
    @Environment(\.featureFlagService) private var featureFlagService
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    
    var body: some View {
        Group {
            if shouldShowOnboarding {
                if onboardingViewModel.showIntroPage {
                    // Show IntroPage after completing or skipping onboarding cards
                    IntroPage(onComplete: {
                        onboardingViewModel.completeOnboarding()
                    })
                } else {
                    // Show onboarding cards
                    OnboardingView(viewModel: onboardingViewModel)
                }
            } else {
                MainTabView()
            }
        }
    }
    
    /// Determine if onboarding should be shown
    private var shouldShowOnboarding: Bool {
        // Only show onboarding if:
        // 1. Feature flag is enabled
        // 2. User hasn't completed onboarding yet
        featureFlagService.isEnabled(.onboardingScreen) && onboardingViewModel.shouldShowOnboarding
    }
}

#Preview("Root View - Onboarding") {
    let featureFlagService = UserDefaultsFeatureFlagService()
    featureFlagService.setEnabled(.onboardingScreen, enabled: true)
    
    return RootView()
        .environment(\.featureFlagService, featureFlagService)
        .environment(\.theme, Theme.wehoop)
        .environment(\.dependencyContainer, configureDependencyContainer())
}

#Preview("Root View - Main App") {
    let featureFlagService = UserDefaultsFeatureFlagService()
    featureFlagService.setEnabled(.onboardingScreen, enabled: false)
    
    return RootView()
        .environment(\.featureFlagService, featureFlagService)
        .environment(\.theme, Theme.wehoop)
        .environment(\.dependencyContainer, configureDependencyContainer())
}
