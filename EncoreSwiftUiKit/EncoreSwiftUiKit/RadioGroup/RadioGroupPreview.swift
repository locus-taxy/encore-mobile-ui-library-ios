import SwiftUI

#Preview("RadioGroupViewPreview") {
    let options = ["Option A", "Option B", "Option C"]
    return ScrollView {
        VStack(alignment: .leading, spacing: Spacing.spacing24) {
            // 1. Column, enabled, with helper text, selectedIndex = 0
            RadioGroupView(
                options: options,
                selectedIndex: 0,
                isDisabled: false,
                isRow: false,
                label: "Choose an option",
                helperText: "Select one of the above",
                isError: false,
                onSelect: { _ in }
            )

            // 2. Column, disabled
            RadioGroupView(
                options: options,
                selectedIndex: 1,
                isDisabled: true,
                isRow: false,
                label: "Disabled group",
                helperText: nil,
                isError: false,
                onSelect: { _ in }
            )

            // 3. Column, error state with helper text
            RadioGroupView(
                options: options,
                selectedIndex: nil,
                isDisabled: false,
                isRow: false,
                label: "Required selection",
                helperText: "Please choose an option",
                isError: true,
                onSelect: { _ in }
            )

            // 4. Individual RadioView placements
            VStack(alignment: .leading, spacing: Spacing.spacing16) {
                Text("End placement").typography(Typography.body1)
                RadioView(label: "End — checked", isSelected: true, labelPlacement: .end, onTap: {})
                RadioView(label: "End — unchecked", isSelected: false, labelPlacement: .end, onTap: {})

                Text("Start placement").typography(Typography.body1)
                RadioView(label: "Start — checked", isSelected: true, labelPlacement: .start, onTap: {})
                RadioView(label: "Start — unchecked", isSelected: false, labelPlacement: .start, onTap: {})

                Text("Top placement").typography(Typography.body1)
                HStack {
                    RadioView(label: "Top — checked", isSelected: true, labelPlacement: .top, onTap: {})
                    RadioView(label: "Top — unchecked", isSelected: false, labelPlacement: .top, onTap: {})
                }

                Text("Bottom placement").typography(Typography.body1)
                HStack {
                    RadioView(label: "Bottom — checked", isSelected: true, labelPlacement: .bottom, onTap: {})
                    RadioView(label: "Bottom — unchecked", isSelected: false, labelPlacement: .bottom, onTap: {})
                }
            }
        }
        .padding(Spacing.spacing16)
    }
}
