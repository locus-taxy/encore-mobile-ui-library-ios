import SwiftUI

/// Date and Time checklist item matching Figma design specifications.
/// Composes ChecklistHeader + EncoreDateTimeView.
/// Mirrors Android's `DateTimeCheckListItem` composable.
public struct DateTimeCheckListItem: View {
    let title: String
    let initialDateValue: String
    let initialTimeValue: String
    let onDateTimeChanged: (String) -> Void
    let isRequired: Bool
    let dateFormat: String
    let timeFormat: String

    @State private var dateValue: String
    @State private var timeValue: String

    public init(
        title: String,
        initialDateValue: String,
        initialTimeValue: String,
        onDateTimeChanged: @escaping (String) -> Void,
        isRequired: Bool,
        dateFormat: String = "MM/dd/yyyy",
        timeFormat: String = "HH:mm"
    ) {
        self.title = title
        self.initialDateValue = initialDateValue
        self.initialTimeValue = initialTimeValue
        self.onDateTimeChanged = onDateTimeChanged
        self.isRequired = isRequired
        self.dateFormat = dateFormat
        self.timeFormat = timeFormat
        self._dateValue = State(initialValue: initialDateValue)
        self._timeValue = State(initialValue: initialTimeValue)
    }

    private var combinedDateTime: String {
        switch (dateValue.isEmpty, timeValue.isEmpty) {
        case (false, false): return "\(dateValue) \(timeValue)"
        case (false, true): return dateValue
        case (true, false): return timeValue
        case (true, true): return ""
        }
    }

    private var isValid: Bool {
        ChecklistValidator.validateDateTime(combinedDateTime, isRequired: isRequired)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired && !isValid
            )

            EncoreDateTimeView(
                dateValue: dateValue,
                timeValue: timeValue,
                onDateSelected: { date in
                    dateValue = DateTimeHelper.formatDate(date, format: dateFormat)
                    let combined = !timeValue.isEmpty ? "\(dateValue) \(timeValue)" : dateValue
                    onDateTimeChanged(combined)
                },
                onTimeSelected: { hour, minute in
                    timeValue = DateTimeHelper.formatTime(hour: hour, minute: minute)
                    let combined = !dateValue.isEmpty ? "\(dateValue) \(timeValue)" : timeValue
                    onDateTimeChanged(combined)
                },
                dateFormat: dateFormat,
                timeFormat: timeFormat
            )
        }
        .padding(ChecklistItemConstants.itemPadding)
        .onChange(of: initialDateValue) { newValue in
            dateValue = newValue
        }
        .onChange(of: initialTimeValue) { newValue in
            timeValue = newValue
        }
    }
}

