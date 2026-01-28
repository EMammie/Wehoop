//
//  FeatureFlagService.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Enum representing available feature flags
enum FeatureFlag: String, CaseIterable {
    case newGamesUI = "new_games_ui"
    case newLeadersUI = "new_leaders_ui"
    case newPlayerProfileUI = "new_player_profile_ui"
    case newTeamProfileUI = "new_team_profile_ui"
    case teamLeadersView = "team_leaders_view"
    case weekBasedDatePicker = "week_based_date_picker"
    case onboardingScreen = "onboarding_screen"
}

/// Protocol for feature flag service
protocol FeatureFlagService {
    /// Check if a feature flag is enabled
    func isEnabled(_ flag: FeatureFlag) -> Bool
    
    /// Set a feature flag value
    func setEnabled(_ flag: FeatureFlag, enabled: Bool)
    
    /// Reset all feature flags to defaults
    func resetAll()
}

/// UserDefaults-based implementation of FeatureFlagService
class UserDefaultsFeatureFlagService: FeatureFlagService {
    private let userDefaults: UserDefaults
    private let prefix = "feature_flag_"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func isEnabled(_ flag: FeatureFlag) -> Bool {
        // Default: all flags enabled
        // If the key doesn't exist, return true (enabled by default)
        if userDefaults.object(forKey: key(for: flag)) == nil {
            return true
        }
        return userDefaults.bool(forKey: key(for: flag))
    }
    
    func setEnabled(_ flag: FeatureFlag, enabled: Bool) {
        userDefaults.set(enabled, forKey: key(for: flag))
    }
    
    func resetAll() {
        FeatureFlag.allCases.forEach { flag in
            userDefaults.removeObject(forKey: key(for: flag))
        }
    }
    
    private func key(for flag: FeatureFlag) -> String {
        return "\(prefix)\(flag.rawValue)"
    }
}
