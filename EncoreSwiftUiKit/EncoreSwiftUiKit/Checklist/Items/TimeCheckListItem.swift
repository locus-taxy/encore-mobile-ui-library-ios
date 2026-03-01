import SwiftUI

/// Time checklist item with built-in time picker matching Figma design specifications.
/// Composes ChecklistHeader + EncoreTimeView.
/// Mirrors Android's `TimeCheckListItem` composable.
public struct TimeCheckListItem: View {
    let title: String
    let initialTimeValue: String
    let onTimeSelected: (Int, Int) -> Void
    let isRequired: Bool
    let timeFormat: String

    @State private var timeValue: String

    public init(
        title: String,
        initialTimeValue: String,
        onTimeSelected: @escaping (Int, Int) -> Void,
        isRequired: Bool,
        timeFormat: String = "HH:mm"
    ) {
        self.title = title
        self.initialTimeValue = initialTimeValue
        self.onTimeSelected = onTimeSelected
        self.isRequired = isRequired
        self.timeFormat = timeFormat
        self._timeValue = State(initialValue: initialTimeValue)
    }

    private var isValid: Bool {
        ChecklistValidator.validateTime(timeValue, isRequired: isRequired)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired && !isValid
            )

            EncoreTimeView(
                timeValue: timeValue,
                onTimeSelected: { hour, minute in
                    timeValue = DateTimeHelper.formatTime(hour: hour, minute: minute)
                    onTimeSelected(hour, minute)
                },
                timeFormat: timeFormat
            )
        }
        .padding(ChecklistItemConstants.itemPadding)
        .onChange(of: initialTimeValue) { newValue in
            timeValue = newValue
        }
    }
}

