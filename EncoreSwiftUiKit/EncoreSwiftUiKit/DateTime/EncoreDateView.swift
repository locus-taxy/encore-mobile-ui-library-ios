import SwiftUI

/// Reusable date picker view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `DateView` composable.
public struct EncoreDateView: View {
    let dateValue: String
    let onDateSelected: (Date) -> Void
    var dateFormat: String
    var dateHint: String
    var dateRange: ClosedRange<Date>?
    var showRelativeDayPrefix: Bool

    @State private var showDatePicker = false
    @State private var isSheetVisible = false
    @State private var selectedDate = Date()

    public init(
        dateValue: String,
        onDateSelected: @escaping (Date) -> Void,
        dateFormat: String = "MM/dd/yyyy",
        dateHint: String = "Select date",
        dateRange: ClosedRange<Date>? = nil,
        showRelativeDayPrefix: Bool = false
    ) {
        self.dateValue = dateValue
        self.onDateSelected = onDateSelected
        self.dateFormat = dateFormat
        self.dateHint = dateHint
        self.dateRange = dateRange
        self.showRelativeDayPrefix = showRelativeDayPrefix
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

    // MARK: - Shortcut visibility

    private var yesterdayDate: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    }

    private var showYesterdayShortcut: Bool {
        guard let range = dateRange else { return true }
        return range.contains(yesterdayDate)
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    showDatePicker = true
                }
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
            .fullScreenCover(isPresented: $showDatePicker) {
                ZStack(alignment: .bottom) {
                    Color.encore("Backdrop/Fill")
                        .opacity(isSheetVisible ? 0.5 : 0)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.22), value: isSheetVisible)
                    pickerSheet
                        .background(Color.encore("Background/Default"))
                        .offset(y: isSheetVisible ? 0 : 1000)
                        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isSheetVisible)
                        .allowsHitTesting(isSheetVisible)
                }
                .background(TransparentBackground())
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        isSheetVisible = true
                    }
                }
            }
        }
        .onAppear { syncSelectedDate(from: dateValue) }
        .onChange(of: dateValue) { syncSelectedDate(from: $0) }
    }

    // MARK: - Helpers

    private func closeSheet() {
        isSheetVisible = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.none) { showDatePicker = false }
        }
    }

    private func syncSelectedDate(from value: String) {
        guard !value.isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        if let date = formatter.date(from: value) {
            selectedDate = date
        }
    }

    // MARK: - Picker sheet

    private var pickerSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 0) {
                Button {
                    closeSheet()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.encore("Text/Primary"))
                        .frame(width: 48, height: 48)
                }
                Spacer()
                Text("Pick a date")
                    .typography(Typography.h5)
                    .foregroundColor(Color.encore("Text/Primary"))
                Spacer()
                // Mirror for optical centering
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 48, height: 48)
                    .opacity(0)
                    .allowsHitTesting(false)
            }
            .padding(8)

            // Calendar + shortcuts
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    if let dateRange {
                        DatePicker(
                            "Pick a date",
                            selection: $selectedDate,
                            in: dateRange,
                            displayedComponents: .date
                        )
                    } else {
                        DatePicker(
                            "Pick a date",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                    }
                }
                .datePickerStyle(.graphical)
                .tint(Color.encore("Primary/Main"))
                .padding(.vertical, -8)

                if showYesterdayShortcut {
                    EncoreButton(
                        label: "Yesterday",
                        startIconName: nil,
                        endIconName: nil,
                        color: .primary,
                        variant: .text,
                        size: .medium,
                        action: { selectedDate = yesterdayDate }
                    )
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
            .padding(16)

            // Actions
            VStack(spacing: 0) {
                EncoreButton(label: "Apply") {
                    onDateSelected(selectedDate)
                    closeSheet()
                }
                .padding(16)
            }
            .background(Color.encore("Background/Default"))
            .shadow(color: Color.black.opacity(0.16), radius: 4, x: 0, y: 0)
        }
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

// MARK: - TransparentBackground

private struct TransparentBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
