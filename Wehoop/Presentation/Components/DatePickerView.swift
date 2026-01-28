//
//  DatePickerView.swift
//  wehoop
//
//  Created by E on 1/14/26.
//

import SwiftUI

/// Configuration for DatePickerView date range
struct DatePickerConfiguration {
    /// Number of weeks to go back from today (default: 4)
    let weeksBack: Int
    
    /// Number of weeks to go forward from today (default: 4)
    let weeksForward: Int
    
    /// Default configuration: 4 weeks back, 4 weeks forward
    static let `default` = DatePickerConfiguration(weeksBack: 4, weeksForward: 4)
}

/// Horizontal scrollable date picker component
/// Displays dates within a configurable range past and future, with weekend highlighting
/// Feature-flagged to support week-based variant (DatePickerViewV2)
struct DatePickerView: View {
    @Environment(\.theme) private var theme
    @Environment(\.featureFlagService) private var featureFlagService
    
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    let configuration: DatePickerConfiguration
    
    /// Initialize with custom configuration
    /// - Parameters:
    ///   - selectedDate: Binding to currently selected date
    ///   - onDateSelected: Callback when date is selected
    ///   - configuration: Date range configuration (defaults to 4 weeks back/forward)
    init(
        selectedDate: Binding<Date>,
        onDateSelected: @escaping (Date) -> Void,
        configuration: DatePickerConfiguration = .default
    ) {
        self._selectedDate = selectedDate
        self.onDateSelected = onDateSelected
        self.configuration = configuration
    }
    
    /// Legacy initializer for backward compatibility
    /// - Parameters:
    ///   - selectedDate: Currently selected date (non-binding)
    ///   - onDateSelected: Callback when date is selected
    ///   - configuration: Date range configuration
    init(
        selectedDate: Date,
        onDateSelected: @escaping (Date) -> Void,
        configuration: DatePickerConfiguration = .default
    ) {
        self._selectedDate = .constant(selectedDate)
        self.onDateSelected = onDateSelected
        self.configuration = configuration
    }
    
    var body: some View {
        if featureFlagService.isEnabled(.weekBasedDatePicker) {
            // Week-based date picker (V2)
            DatePickerViewV2(
                selectedDate: $selectedDate,
                onDateSelected: onDateSelected
            )
        } else {
            // Original date picker (V1)
            datePickerV1
        }
    }
    
    /// Original date picker implementation
    @ViewBuilder
    private var datePickerV1: some View {
        VStack(spacing: 8) {
            // Month title
            HStack {
                Text(monthTitle)
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colorScheme.foreground)
                Spacer()
            }
            .padding(.horizontal)
            
            // Date picker scroll view
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dates, id: \.self) { date in
                        DateItemView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            theme: theme,
                            onTap: {
                                selectedDate = date
                                onDateSelected(date)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(theme.colorScheme.background)
        .cornerRadius(12)
        .shadow(color: theme.colorScheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // Generate dates based on configuration
    private var dates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -configuration.weeksBack, to: today),
              let endDate = calendar.date(byAdding: .weekOfYear, value: configuration.weeksForward, to: today) else {
            return [today]
        }
        
        var dateArray: [Date] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            dateArray.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return dateArray
    }
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private let calendar = Calendar.current
}

/// Individual date item in the picker
private struct DateItemView: View {
    let date: Date
    let isSelected: Bool
    let theme: Theme
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    private var dayAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var isWeekend: Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // Sunday or Saturday
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayAbbreviation)
                .font(theme.typography.caption)
                .foregroundColor(textColor)
            
            Text(dayNumber)
                .font(theme.typography.headline)
                .foregroundColor(textColor)
        }
        .frame(width: 60, height: 70)
        .background(backgroundColor)
        .cornerRadius(8)
        .onTapGesture {
            onTap()
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isWeekend {
            return .red
        } else {
            return theme.colorScheme.foreground
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return theme.colorScheme.primary
        } else {
            return Color.clear
        }
    }
}

#Preview("Light Theme - Today Selected") {
    DatePickerView(
        selectedDate: Date(),
        onDateSelected: { _ in }
    )
    .environment(\.theme, Theme.wehoop)
    .padding()
}

#Preview("Dark Theme - Future Date Selected") {
    let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
    
    DatePickerView(
        selectedDate: futureDate,
        onDateSelected: { _ in }
    )
    .environment(\.theme, Theme.wehoop)
    .preferredColorScheme(.dark)
    .padding()
}

#Preview("Light Theme - Past Date Selected") {
    let pastDate = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
    
    DatePickerView(
        selectedDate: pastDate,
        onDateSelected: { _ in }
    )
    .environment(\.theme, Theme.wehoop)
    .preferredColorScheme(.light)
    .padding()
}

#Preview("Weekend Date Selected") {
    let calendar = Calendar.current
    let today = Date()
    // Find next Saturday
    let weekday = calendar.component(.weekday, from: today)
    let daysUntilSaturday: Int = {
        if weekday == 7 { // Today is Saturday
            return 7 // Next Saturday
        } else {
            let days = (7 - weekday) % 7
            return days == 0 ? 7 : days
        }
    }()
    let saturday = calendar.date(byAdding: .day, value: daysUntilSaturday, to: today) ?? today
    
    DatePickerView(
        selectedDate: saturday,
        onDateSelected: { _ in }
    )
    .environment(\.theme, Theme.wehoop)
    .preferredColorScheme(.light)
    .padding()
}
