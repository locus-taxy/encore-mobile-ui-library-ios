import SwiftUI

/// A modifier that applies `.presentationDetents([.medium])` on iOS 16+ and is a no-op on earlier versions.
private struct MediumDetentModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.presentationDetents([.medium])
        } else {
            content
        }
    }
}

/// Reusable date picker view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `DateView` composable.
public struct EncoreDateView: View {
    let dateValue: String
    let onDateSelected: (Date) -> Void
    var dateFormat: String
    var dateHint: String

    @State private var showDatePicker = false
    @State private var selectedDate = Date()

    public init(
        dateValue: String,
        onDateSelected: @escaping (Date) -> Void,
        dateFormat: String = "MM/dd/yyyy",
        dateHint: String = "Select date"
    ) {
        self.dateValue = dateValue
        self.onDateSelected = onDateSelected
        self.dateFormat = dateFormat
        self.dateHint = dateHint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                showDatePicker = true
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text(dateValue.isEmpty ? dateHint : dateValue)
                        .foregroundColor(dateValue.isEmpty ? .secondary : .primary)
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showDatePicker) {
                NavigationView {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    .navigationTitle("Select Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showDatePicker = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("OK") {
                                onDateSelected(selectedDate)
                                showDatePicker = false
                            }
                        }
                    }
                }
                .modifier(MediumDetentModifier())
            }
        }
        .onAppear {
            if !dateValue.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = dateFormat
                if let date = formatter.date(from: dateValue) {
                    selectedDate = date
                }
            }
        }
    }
}

