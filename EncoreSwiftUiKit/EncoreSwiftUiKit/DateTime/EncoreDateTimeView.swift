import SwiftUI

/// Reusable date and time picker view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `DateTimeView` composable.
public struct EncoreDateTimeView: View {
    let dateValue: String
    let timeValue: String
    let onDateSelected: (Date) -> Void
    let onTimeSelected: (Int, Int) -> Void
    var dateFormat: String
    var timeFormat: String
    var dateHint: String
    var timeHint: String

    public init(
        dateValue: String,
        timeValue: String,
        onDateSelected: @escaping (Date) -> Void,
        onTimeSelected: @escaping (Int, Int) -> Void,
        dateFormat: String = "MM/dd/yyyy",
        timeFormat: String = "HH:mm",
        dateHint: String = "Select date",
        timeHint: String = "Select time"
    ) {
        self.dateValue = dateValue
        self.timeValue = timeValue
        self.onDateSelected = onDateSelected
        self.onTimeSelected = onTimeSelected
        self.dateFormat = dateFormat
        self.timeFormat = timeFormat
        self.dateHint = dateHint
        self.timeHint = timeHint
    }

    public var body: some View {
        HStack(spacing: 5) {
            EncoreDateView(
                dateValue: dateValue,
                onDateSelected: onDateSelected,
                dateFormat: dateFormat,
                dateHint: dateHint
            )

            EncoreTimeView(
                timeValue: timeValue,
                onTimeSelected: onTimeSelected,
                timeFormat: timeFormat,
                timeHint: timeHint
            )
        }
        .padding(.vertical, 10)
    }
}

