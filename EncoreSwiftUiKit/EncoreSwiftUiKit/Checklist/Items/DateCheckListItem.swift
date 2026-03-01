import SwiftUI

/// Date checklist item with built-in date picker matching Figma design specifications.
/// Composes ChecklistHeader + EncoreDateView.
/// Mirrors Android's `DateCheckListItem` composable.
public struct DateCheckListItem: View {
    let title: String
    let initialDateValue: String
    let onDateSelected: (Date) -> Void
    let isRequired: Bool
    let dateFormat: String

    @State private var dateValue: String

    public init(
        title: String,
        initialDateValue: String,
        onDateSelected: @escaping (Date) -> Void,
        isRequired: Bool,
        dateFormat: String = "MM/dd/yyyy"
    ) {
        self.title = title
        self.initialDateValue = initialDateValue
        self.onDateSelected = onDateSelected
        self.isRequired = isRequired
        self.dateFormat = dateFormat
        self._dateValue = State(initialValue: initialDateValue)
    }

    private var isValid: Bool {
        ChecklistValidator.validateDate(dateValue, isRequired: isRequired)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired && !isValid
            )

            EncoreDateView(
                dateValue: dateValue,
                onDateSelected: { date in
                    dateValue = DateTimeHelper.formatDate(date, format: dateFormat)
                    onDateSelected(date)
                },
                dateFormat: dateFormat
            )
        }
        .padding(ChecklistItemConstants.itemPadding)
        .onChange(of: initialDateValue) { newValue in
            dateValue = newValue
        }
    }
}

