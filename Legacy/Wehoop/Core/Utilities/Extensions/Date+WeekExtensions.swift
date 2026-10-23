//
//  Date+WeekExtensions.swift
//  Unrivaled
//
//  Created by E on 1/14/26.
//

import Foundation

/// Represents a weekday with its date
struct WeekDay: Identifiable {
    let id = UUID()
    let date: Date
}

extension Date {
    /// Check if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Format date with a custom format string
    /// - Parameter format: Date format string (e.g., "MMMM", "YYYY", "dd", "E")
    /// - Returns: Formatted date string
    func format(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    /// Fetch the current week (7 days starting from Sunday)
    /// - Returns: Array of WeekDay objects for the current week
    func fetchWeek() -> [WeekDay] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: self)?.start ?? self
        
        var week: [WeekDay] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                week.append(WeekDay(date: date))
            }
        }
        
        return week
    }
    
    /// Create the previous week
    /// - Returns: Array of WeekDay objects for the previous week
    func createPreviousWeek() -> [WeekDay] {
        let calendar = Calendar.current
        guard let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: self) else {
            return fetchWeek()
        }
        return previousWeekStart.fetchWeek()
    }
    
    /// Create the next week
    /// - Returns: Array of WeekDay objects for the next week
    func createNextWeek() -> [WeekDay] {
        let calendar = Calendar.current
        guard let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: self) else {
            return fetchWeek()
        }
        return nextWeekStart.fetchWeek()
    }
}

/// Helper function to check if two dates are the same day
func isSameDate(_ date1: Date, _ date2: Date) -> Bool {
    Calendar.current.isDate(date1, inSameDayAs: date2)
}
