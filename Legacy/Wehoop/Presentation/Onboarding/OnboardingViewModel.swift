//
//  OnboardingViewModel.swift
//  Wehoop
//
//  Created by E on 1/26/26.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing onboarding state
@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    @Published var hasCompletedOnboarding: Bool = false
    @Published var showIntroPage: Bool = false
    
    private let userDefaults: UserDefaults
    private let hasCompletedOnboardingKey = "has_completed_onboarding"
    
    let cards: [OnboardingCard]
    
    init(
        cards: [OnboardingCard] = OnboardingCard.defaultCards,
        userDefaults: UserDefaults = .standard
    ) {
        self.cards = cards
        self.userDefaults = userDefaults
        self.hasCompletedOnboarding = userDefaults.bool(forKey: hasCompletedOnboardingKey)
    }
    
    /// Check if user has completed onboarding
    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding
    }
    
    /// Move to next page
    func nextPage() {
        if currentPage < cards.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboardingCards()
        }
    }
    
    /// Move to previous page
    func previousPage() {
        if currentPage > 0 {
            withAnimation {
                currentPage -= 1
            }
        }
    }
    
    /// Skip onboarding cards (will show IntroPage)
    func skipOnboarding() {
        showIntroPage = true
    }
    
    /// Complete onboarding cards (will show IntroPage)
    func completeOnboardingCards() {
        showIntroPage = true
    }
    
    /// Complete onboarding and mark as done (called from IntroPage)
    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: hasCompletedOnboardingKey)
    }
    
    /// Reset onboarding (useful for testing)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentPage = 0
        showIntroPage = false
        userDefaults.removeObject(forKey: hasCompletedOnboardingKey)
    }
    
    /// Check if we're on the last page
    var isLastPage: Bool {
        currentPage == cards.count - 1
    }
    
    /// Check if we're on the first page
    var isFirstPage: Bool {
        currentPage == 0
    }
}
