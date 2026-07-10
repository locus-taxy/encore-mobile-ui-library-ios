import SwiftUI

/// Reusable date picker view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `DateView` composable.
///
/// The picker sheet itself is provided by `EncoreDatePickerModifier`; this view
/// is the tappable date label that opens it.
public struct EncoreDateView: View {
    let dateValue: String
    let onDateSelected: (Date) -> Void
    var dateFormat: String
    var dateHint: String
    var dateRange: ClosedRange<Date>?
    var showRelativeDayPrefix: Bool
    var showTodayShortcut: Bool

    @State private var showDatePicker = false

    public init(
        dateValue: String,
        onDateSelected: @escaping (Date) -> Void,
        dateFormat: String = "MM/dd/yyyy",
        dateHint: String = "Select date",
        dateRange: ClosedRange<Date>? = nil,
        showRelativeDayPrefix: Bool = false,
        showTodayShortcut: Bool = false
    ) {
        self.dateValue = dateValue
        self.onDateSelected = onDateSelected
        self.dateFormat = dateFormat
        self.dateHint = dateHint
        self.dateRange = dateRange
        self.showRelativeDayPrefix = showRelativeDayPrefix
        self.showTodayShortcut = showTodayShortcut
    }

    // MARK: - Derived date state

    private var parsedDate: Date? {
        guard !dateValue.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.date(from: dateValue)
    }

    private var relativeDay: RelativeDay? {
        guard let date = parsedDate else { return nil }
        if Calendar.current.isDateInToday(date) { return .today }
        if Calendar.current.isDateInYesterday(date) { return .yesterday }
        if Calendar.current.isDateInTomorrow(date) { return .tomorrow }
        return nil
    }

    private var displayText: String {
        guard !dateValue.isEmpty else { return dateHint }
        guard showRelativeDayPrefix, let relative = relativeDay else { return dateValue }
        return "\(relative.label), \(dateValue)"
    }

    private var buttonTextColor: Color {
        guard !dateValue.isEmpty else { return Color.encore("Text/Secondary") }
        return relativeDay == .yesterday
            ? Color.encore("Text/Secondary")
            : Color.encore("Primary/Main")
    }

    // MARK: - Body

    public var body: some View {
        Button {
            showDatePicker = true
        } label: {
            HStack(spacing: 8) {
                Text(displayText)
                    .typography(Typography.Button.large)
                EncoreIcon(iconName: "LEdit", size: 20)
            }
            .foregroundColor(buttonTextColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .encoreDatePicker(
            isPresented: $showDatePicker,
            selectedDate: parsedDate ?? Date(),
            dateRange: dateRange,
            showTodayShortcut: showTodayShortcut,
            showYesterdayShortcut: true,
            onDateSelected: onDateSelected
        )
    }
}

// MARK: - RelativeDay

private enum RelativeDay {
    case today, yesterday, tomorrow

    var label: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .tomorrow: return "Tomorrow"
        }
    }
}
