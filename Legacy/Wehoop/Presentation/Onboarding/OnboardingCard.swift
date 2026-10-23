//
//  OnboardingCard.swift
//  Wehoop
//
//  Created by E on 1/26/26.
//

import SwiftUI

/// Model representing a single onboarding card
struct OnboardingCard {
    let id: UUID
    let title: String
    let description: String
    let systemImageName: String
    let color: Color
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        systemImageName: String,
        color: Color
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.systemImageName = systemImageName
        self.color = color
    }
}

/// Default onboarding cards for the app
extension OnboardingCard {
    static let defaultCards: [OnboardingCard] = [
        OnboardingCard(
            title: "Welcome to Wehoop",
            description: "Your ultimate destination for WNBA, Unrivaled and NCAA games, stats, and player insights.",
            systemImageName: "sportscourt.fill",
            color: Color(red: 0.2, green: 0.1, blue: 0.4) // Deep purple
        ),
        OnboardingCard(
            title: "Live Game Updates",
            description: "Stay up to date with real-time scores, stats, and game highlights as they happen.",
            systemImageName: "chart.line.uptrend.xyaxis",
            color: Color(red: 1.0, green: 0.6, blue: 0.2) // Orange accent
        ),
        OnboardingCard(
            title: "Player & Team Stats",
            description: "Explore detailed statistics, leaderboards, and profiles for all your favorite players and teams.",
            systemImageName: "person.3.fill",
            color: Color(red: 0.4, green: 0.3, blue: 0.6) // Lighter purple
        ),
        OnboardingCard(
            title: "Get Started",
            description: "Start exploring games, players, and teams. Swipe to see what's happening in the Women's Basketball today!",
            systemImageName: "star.fill",
            color: Color(red: 0.2, green: 0.1, blue: 0.4) // Deep purple
        )
    ]
}
