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
public struct EncoreTimeView: View {
    let timeValue: String
    let onTimeSelected: (Int, Int) -> Void
    var timeFormat: String
    var timeHint: String

    @State private var showTimePicker = false
    @State private var selectedTime = Date()

    public init(
        timeValue: String,
        onTimeSelected: @escaping (Int, Int) -> Void,
        timeFormat: String = "HH:mm",
        timeHint: String = "Select time"
    ) {
        self.timeValue = timeValue
        self.onTimeSelected = onTimeSelected
        self.timeFormat = timeFormat
        self.timeHint = timeHint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                showTimePicker = true
            } label: {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(timeValue.isEmpty ? timeHint : timeValue)
                        .foregroundColor(timeValue.isEmpty ? .secondary : .primary)
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
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

