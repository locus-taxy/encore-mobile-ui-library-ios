import SwiftUI

/// A modifier that applies `.presentationDetents([.medium])` on iOS 16+ and is a no-op on earlier versions.
private struct TimeMediumDetentModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.presentationDetents([.medium])
        } else {
            content
        }
    }
}

/// Reusable time picker view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `TimeView` composable.
///
/// Renders as a bordered input box — value (or hint) on the leading edge, and a
/// trailing icon cluster of an optional clear (×) button followed by the clock
/// glyph. Tapping the box opens the wheel time picker.
public struct EncoreTimeView: View {
    let timeValue: String
    let onTimeSelected: (Int, Int) -> Void
    /// When non-nil AND a value is present, a trailing clear (×) button is shown;
    /// tapping it invokes this closure. Nil (default) hides the clear affordance.
    var onClear: (() -> Void)?
    var timeFormat: String
    var timeHint: String

    @State private var showTimePicker = false
    @State private var selectedTime = Date()

    public init(
        timeValue: String,
        onTimeSelected: @escaping (Int, Int) -> Void,
        onClear: (() -> Void)? = nil,
        timeFormat: String = "HH:mm",
        timeHint: String = "Select time"
    ) {
        self.timeValue = timeValue
        self.onTimeSelected = onTimeSelected
        self.onClear = onClear
        self.timeFormat = timeFormat
        self.timeHint = timeHint
    }

    private var hasValue: Bool { !timeValue.isEmpty }

    public var body: some View {
        HStack(spacing: 8) {
            Text(hasValue ? timeValue : timeHint)
                .typography(Typography.body1)
                .foregroundColor(hasValue ? Color.encore("Text/Primary") : Color.encore("Text/Secondary"))
                .frame(maxWidth: .infinity, alignment: .leading)

            if hasValue, let onClear {
                Button(action: onClear) {
                    EncoreIcon(iconName: "LCrossCircle", size: 20)
                        .foregroundColor(Color.encore("Text/Secondary"))
                }
                .buttonStyle(.plain)
            }

            EncoreIcon(iconName: "LClock", size: 20)
                .foregroundColor(Color.encore("Text/Secondary"))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.encore("Input/OutlinedEnabledBorder"), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { showTimePicker = true }
        .sheet(isPresented: $showTimePicker) {
            NavigationView {
                DatePicker(
                    "Select Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .navigationTitle("Select Time")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showTimePicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("OK") {
                            let calendar = Calendar.current
                            let hour = calendar.component(.hour, from: selectedTime)
                            let minute = calendar.component(.minute, from: selectedTime)
                            onTimeSelected(hour, minute)
                            showTimePicker = false
                        }
                    }
                }
            }
            .modifier(TimeMediumDetentModifier())
        }
        .onAppear {
            if !timeValue.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = timeFormat
                if let time = formatter.date(from: timeValue) {
                    selectedTime = time
                }
            }
        }
    }
}
