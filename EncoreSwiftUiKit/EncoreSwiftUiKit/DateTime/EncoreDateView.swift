import SwiftUI

/// Reusable date picker view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `DateView` composable.
///
/// Renders as a bordered input box — value (or hint) on the leading edge, and a
/// trailing icon cluster of an optional clear (×) button followed by the calendar
/// glyph. Tapping the box opens the shared graphical date picker provided by
/// `EncoreDatePickerModifier`.
public struct EncoreDateView: View {
    let dateValue: String
    let onDateSelected: (Date) -> Void
    /// When non-nil AND a value is present, a trailing clear (×) button is shown;
    /// tapping it invokes this closure. Nil (default) hides the clear affordance.
    var onClear: (() -> Void)?
    var dateFormat: String
    var dateHint: String
    var dateRange: ClosedRange<Date>?
    var showRelativeDayPrefix: Bool
    var showTodayShortcut: Bool

    @State private var showDatePicker = false

    public init(
        dateValue: String,
        onDateSelected: @escaping (Date) -> Void,
        onClear: (() -> Void)? = nil,
        dateFormat: String = "MM/dd/yyyy",
        dateHint: String = "Select date",
        dateRange: ClosedRange<Date>? = nil,
        showRelativeDayPrefix: Bool = false,
        showTodayShortcut: Bool = false
    ) {
        self.dateValue = dateValue
        self.onDateSelected = onDateSelected
        self.onClear = onClear
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

    private var hasValue: Bool { !dateValue.isEmpty }

    private var displayText: String {
        guard hasValue else { return dateHint }
        guard showRelativeDayPrefix, let relative = relativeDay else { return dateValue }
        return "\(relative.label), \(dateValue)"
    }

    private var valueColor: Color {
        hasValue ? Color.encore("Text/Primary") : Color.encore("Text/Secondary")
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 8) {
            Text(displayText)
                .typography(Typography.body1)
                .foregroundColor(valueColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            if hasValue, let onClear {
                Button(action: onClear) {
                    EncoreIcon(iconName: "LCrossCircle", size: 20)
                        .foregroundColor(Color.encore("Text/Secondary"))
                }
                .buttonStyle(.plain)
            }

            EncoreIcon(iconName: "LCalendarToday", size: 20)
                .foregroundColor(Color.encore("Text/Secondary"))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.encore("Input/OutlinedEnabledBorder"), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { showDatePicker = true }
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
