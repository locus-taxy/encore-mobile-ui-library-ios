import Foundation

/// Helper functions for date/time formatting.
/// Mirrors Android's `DateTimeHelper.kt` utility functions.
public enum DateTimeHelper {
    /// Formats a Date to a string using the given format.
    public static func formatDate(_ date: Date, format: String = "MM/dd/yyyy") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    /// Formats hour and minute into a time string (e.g., "14:30").
    public static func formatTime(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }
}

