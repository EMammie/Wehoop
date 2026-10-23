//
//  OnboardingView.swift
//  Wehoop
//
//  Created by E on 1/26/26.
//

import SwiftUI

/// Onboarding view with carousel of cards
struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: OnboardingViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: OnboardingViewModel())
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    theme.colorScheme.primary.opacity(0.1),
                    theme.colorScheme.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button (top trailing)
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.skipOnboarding()
                    }) {
                        Text("Skip")
                            .font(theme.typography.body)
                            .foregroundColor(theme.colorScheme.foreground.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }
                
                // Carousel of cards
                TabView(selection: $viewModel.currentPage) {
                    ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                        OnboardingCardView(card: card)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Page indicator and navigation buttons
                VStack(spacing: 24) {
                    // Custom page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<viewModel.cards.count, id: \.self) { index in
                            Circle()
                                .fill(
                                    index == viewModel.currentPage
                                        ? theme.colorScheme.accent
                                        : theme.colorScheme.secondary.opacity(0.3)
                                )
                                .frame(width: 8, height: 8)
                                .animation(.spring(response: 0.3), value: viewModel.currentPage)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        // Previous button (only show if not on first page)
                        if !viewModel.isFirstPage {
                            Button(action: {
                                viewModel.previousPage()
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                }
                                .font(theme.typography.body)
                                .foregroundColor(theme.colorScheme.foreground)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(theme.colorScheme.secondary.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        
                        Spacer()
                        
                        // Next/Get Started button
                        Button(action: {
                            if viewModel.isLastPage {
                                viewModel.completeOnboardingCards()
                            } else {
                                viewModel.nextPage()
                            }
                        }) {
                            HStack {
                                Text(viewModel.isLastPage ? "Get Started" : "Next")
                                if !viewModel.isLastPage {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(theme.typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(theme.colorScheme.accent)
                            .cornerRadius(12)
                            .shadow(color: theme.colorScheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

/// Individual onboarding card view
struct OnboardingCardView: View {
    let card: OnboardingCard
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon/Image
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                card.color.opacity(0.2),
                                card.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: card.systemImageName)
                    .font(.system(size: 64, weight: .medium))
                    .foregroundColor(card.color)
            }
            .padding(.bottom, 16)
            
            // Title
            Text(card.title)
                .font(theme.typography.title)
                .fontWeight(.bold)
                .foregroundColor(theme.colorScheme.foreground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Description
            Text(card.description)
                .font(theme.typography.body)
                .foregroundColor(theme.colorScheme.foreground.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Onboarding View") {
    OnboardingView()
        .environment(\.theme, Theme.wehoop)
}

#Preview("Onboarding Card") {
    OnboardingCardView(card: OnboardingCard.defaultCards[0])
        .environment(\.theme, Theme.wehoop)
        .padding()
}
