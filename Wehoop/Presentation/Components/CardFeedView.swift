//
//  CardFeedView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Reusable card feed component for consistent feed UI across features
struct CardFeedView<Item: Identifiable, Content: View>: View {
    // MARK: - Properties
    let items: [Item]
    let cardContent: (Item) -> Content
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let onRefresh: (() -> Void)?
    let emptyStateTitle: String?
    let emptyStateMessage: String?
    let emptyStateImage: String?
    
    // MARK: - Initialization
    init(
        items: [Item],
        spacing: CGFloat = 12,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 16,
        onRefresh: (() -> Void)? = nil,
        emptyStateTitle: String? = nil,
        emptyStateMessage: String? = nil,
        emptyStateImage: String? = nil,
        @ViewBuilder cardContent: @escaping (Item) -> Content
    ) {
        self.items = items
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.onRefresh = onRefresh
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateMessage = emptyStateMessage
        self.emptyStateImage = emptyStateImage
        self.cardContent = cardContent
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if items.isEmpty {
                emptyStateView
            } else {
                feedContent
            }
        }
    }
    
    // MARK: - Feed Content
    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: spacing) {
                ForEach(items) { item in
                    cardContent(item)
                        .padding(.horizontal, horizontalPadding)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .padding(.vertical, verticalPadding)
            .animation(.easeInOut(duration: 0.3), value: items.count)
        }
        .refreshable {
            onRefresh?()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        EmptyStateView(
            title: emptyStateTitle ?? "No Items",
            message: emptyStateMessage ?? "There are no items to display.",
            systemImage: emptyStateImage ?? "list.bullet"
        )
    }
}

// MARK: - Convenience Extensions
extension CardFeedView {
    /// Creates a card feed with default empty state
    static func withEmptyState(
        items: [Item],
        emptyStateTitle: String,
        emptyStateMessage: String,
        emptyStateImage: String = "list.bullet",
        spacing: CGFloat = 12,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 16,
        onRefresh: (() -> Void)? = nil,
        @ViewBuilder cardContent: @escaping (Item) -> Content
    ) -> CardFeedView {
        CardFeedView(
            items: items,
            spacing: spacing,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding,
            onRefresh: onRefresh,
            emptyStateTitle: emptyStateTitle,
            emptyStateMessage: emptyStateMessage,
            emptyStateImage: emptyStateImage,
            cardContent: cardContent
        )
    }
}
