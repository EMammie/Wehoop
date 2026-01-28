//
//  StatCategoryPicker.swift
//  Unrivaled
//
//  Created by E on 1/18/26.
//

import Foundation
import SwiftUI

struct StatCategoryPicker: View {
  @Environment(\.theme) private var theme

      /// Binding to the currently selected category
      @Binding var selectedCategory: StatCategory

      /// Callback when a category is selected
      let onCategorySelected: ((StatCategory) -> Void)?

      /// Optional list of categories to display (defaults to all cases)
      let categories: [StatCategory]

      /// Initializer with binding and optional callback
      init(
          selectedCategory: Binding<StatCategory>,
          categories: [StatCategory] = StatCategory.allCases,
          onCategorySelected: ((StatCategory) -> Void)? = nil
      ) {
        self._selectedCategory = selectedCategory
        self.categories = categories
        self.onCategorySelected = onCategorySelected
      }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(StatCategory.allCases, id: \.self) { category in
          Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
              selectedCategory = category
              onCategorySelected?(category)
            }
          }) {
            Text(category.displayName)
              .font(theme.typography.caption)
              .fontWeight(selectedCategory == category ? .semibold : .regular)
              .foregroundColor(selectedCategory == category ? .white : theme.colorScheme.foreground)
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(selectedCategory == category ? theme.colorScheme.accent : theme.colorScheme.secondary.opacity(0.2))
              .cornerRadius(20)
              .scaleEffect(selectedCategory == category ? 1.05 : 1.0)
          }
          .buttonStyle(.plain)
          .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCategory)
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 8)
    }
    .background(theme.colorScheme.background)
  }
}
#Preview {
    struct PreviewWrapper: View {
        @State private var selectedCategory: StatCategory = .scoring

        var body: some View {
            VStack {
                StatCategoryPicker(selectedCategory: $selectedCategory)
                Text("Selected: \(selectedCategory.displayName)")
                    .padding()
            }
            .environment(\.theme, Theme.wehoop)
        }
    }

    return PreviewWrapper()
}
