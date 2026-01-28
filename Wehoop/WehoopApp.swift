//
//  WehoopApp.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

@main
struct WehoopApp: App {
    // Dependency container configured at app startup
    private let container: DependencyContainer = configureDependencyContainer()
    
    // Shared team theme provider instance (singleton)
    private let teamThemeProvider = TeamThemeProvider()

  init() {
      // Test API Configuration
      if let config = APIConfiguration.load() {
          print("✅ API Configuration loaded successfully")
          print("   Base URL: \(config.baseURL)")
          print("   API Version: \(config.apiVersion)")

          // Test URL building
          let testURL = config.url(for: "teams")
          print("   Test URL: \(testURL)")

          // Verify API key header
          let headers = config.apiKeyHeader()
          print("   API Key Header: \(headers.keys.first ?? "none")")
      } else {
          print("⚠️ API Configuration not available - check Config.xcconfig setup")
      }
  }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.dependencyContainer, container)
                .environment(\.theme, Theme.wehoop)
                .environment(\.teamThemeProvider, teamThemeProvider)
                .environment(\.featureFlagService, container.resolve() as FeatureFlagService)
                .environmentObject(AppCoordinator())
        }
    }
}

// Environment key for dependency container
private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue: DependencyContainer = configureDependencyContainer()
}

extension EnvironmentValues {
    var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
    
    var viewModelFactory: ViewModelFactory {
        ViewModelFactory(container: dependencyContainer)
    }
}

// MARK: - Theme Environment

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = Theme.wehoop
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Team Theme Provider Environment

private struct TeamThemeProviderKey: EnvironmentKey {
    static let defaultValue: TeamThemeProvider = TeamThemeProvider()
}

extension EnvironmentValues {
    var teamThemeProvider: TeamThemeProvider {
        get { self[TeamThemeProviderKey.self] }
        set { self[TeamThemeProviderKey.self] = newValue }
    }
}

// MARK: - Feature Flag Service Environment

private struct FeatureFlagServiceKey: EnvironmentKey {
    static let defaultValue: FeatureFlagService = UserDefaultsFeatureFlagService()
}

extension EnvironmentValues {
    var featureFlagService: FeatureFlagService {
        get { self[FeatureFlagServiceKey.self] }
        set { self[FeatureFlagServiceKey.self] = newValue }
    }
}
