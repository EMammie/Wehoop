//
//  DatePickerViewV2.swift
//  Unrivaled
//
//  Created by E on 1/14/26.
//

import SwiftUI

/// Week-based date picker component (TabView style with pagination)
/// Based on Task Management project design
struct DatePickerViewV2: View {
    @Environment(\.theme) private var theme
    
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    @State private var weekSlider: [[WeekDay]] = []
    @State private var currentWeekIndex: Int = 1
    @State private var createWeek: Bool = false
    
    /// Animation namespace for smooth transitions
    @Namespace private var animation
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month/Year Header
            HStack(spacing: 5) {
                Text(selectedDate.format("MMMM"))
                    .foregroundColor(theme.colorScheme.primary)
                
                Text(selectedDate.format("yyyy"))
                    .foregroundColor(theme.colorScheme.secondary)
            }
            .font(theme.typography.title)
            .animation(.none, value: selectedDate) // Prevent header animation
            
            // Full date display
            Text(selectedDate.formatted(date: .complete, time: .omitted))
                .font(theme.typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(theme.colorScheme.secondary)
                .animation(.none, value: selectedDate) // Prevent date text animation
            
            // Week Slider (TabView)
            TabView(selection: $currentWeekIndex) {
                ForEach(weekSlider.indices, id: \.self) { index in
                    let week = weekSlider[index]
                    WeekView(week: week)
                        .padding(.horizontal, 15)
                        .tag(index)
                }
            }
            .padding(.horizontal, -15)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 90)
            .onChange(of: currentWeekIndex) { oldValue, newValue in
                // Create new week when reaching first/last page
                if newValue == 0 || newValue == (weekSlider.count - 1) {
                    createWeek = true
                }
            }
        }
        .padding(.vertical, 8)
        .background(theme.colorScheme.background)
        .cornerRadius(12)
        .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            if weekSlider.isEmpty {
                initializeWeeks()
            }
        }
    }
    
    /// Initialize week slider with current week and adjacent weeks
    private func initializeWeeks() {
        let currentWeek = Date().fetchWeek()
        
        if let firstDate = currentWeek.first?.date {
            weekSlider.append(firstDate.createPreviousWeek())
        }
        
        weekSlider.append(currentWeek)
        
        if let lastDate = currentWeek.last?.date {
            weekSlider.append(lastDate.createNextWeek())
        }
        
        // Set initial week index to current week (middle)
        currentWeekIndex = 1
    }
    
    /// Week View - displays 7 days in a row
    @ViewBuilder
    private func WeekView(week: [WeekDay]) -> some View {
        HStack(spacing: 0) {
            ForEach(week) { day in
                VStack(spacing: 8) {
                    // Day abbreviation (E, Mon, Tue, etc.)
                    Text(day.date.format("E"))
                        .font(theme.typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colorScheme.secondary)
                    
                    // Day number
                    Text(day.date.format("dd"))
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isSameDate(day.date, selectedDate) ? .white : theme.colorScheme.foreground)
                        .frame(width: 35, height: 35)
                        .background {
                            // Selected date indicator
                            if isSameDate(day.date, selectedDate) {
                                Circle()
                                    .fill(theme.colorScheme.primary)
                                    .matchedGeometryEffect(id: "TABINDICATOR", in: animation)
                            }
                            
                            // Today indicator (small dot at bottom)
                            if day.date.isToday {
                                Circle()
                                    .fill(theme.colorScheme.accent)
                                    .frame(width: 5, height: 5)
                                    .offset(y: 12)
                            }
                        }
                        .background(
                            Circle()
                                .fill(theme.colorScheme.background)
                                .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 1)
                        )
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Update selected date with smooth animation
                    let newDate = day.date
                    
                    // Use transaction to control animation scope
                    var transaction = Transaction(animation: .spring(response: 0.3, dampingFraction: 0.7))
                    transaction.disablesAnimations = false
                    
                    withTransaction(transaction) {
                        selectedDate = newDate
                    }
                    
                    // Call callback after a small delay to avoid layout shifts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onDateSelected(newDate)
                    }
                }
            }
        }
        .background {
            GeometryReader { geometry in
                Color.clear
                    .preference(key: OffsetKey.self, value: geometry.frame(in: .global).minX)
                    .onPreferenceChange(OffsetKey.self) { value in
                        // When offset reaches threshold, paginate week
                        if value.rounded() == 15 && createWeek {
                            paginateWeek()
                            createWeek = false
                        }
                    }
            }
        }
    }
    
    /// Paginate week - add new weeks when reaching edges
    private func paginateWeek() {
        guard weekSlider.indices.contains(currentWeekIndex) else { return }
        
        if let firstDate = weekSlider[currentWeekIndex].first?.date, currentWeekIndex == 0 {
            // Insert new week at beginning, remove last
            weekSlider.insert(firstDate.createPreviousWeek(), at: 0)
            weekSlider.removeLast()
            currentWeekIndex = 1
        }
        
        if let lastDate = weekSlider[currentWeekIndex].last?.date, currentWeekIndex == (weekSlider.count - 1) {
            // Append new week at end, remove first
            weekSlider.append(lastDate.createNextWeek())
            weekSlider.removeFirst()
            currentWeekIndex = weekSlider.count - 2
        }
    }
}

/// Preference key for tracking scroll offset
private struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview("Week-Based Date Picker") {
    @Previewable @State var selectedDate = Date()
    
    DatePickerViewV2(
        selectedDate: $selectedDate,
        onDateSelected: { date in
            selectedDate = date
        }
    )
    .environment(\.theme, Theme.wehoop)
    .padding()
}
