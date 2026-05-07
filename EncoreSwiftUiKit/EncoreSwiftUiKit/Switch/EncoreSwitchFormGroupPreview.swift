import SwiftUI

#Preview("EncoreSwitchFormGroupPreview") {
    EncoreSwitchFormGroupPreviewLayout()
}

private struct EncoreSwitchFormGroupPreviewLayout: View {
    @State private var enabledItems = [
        EncoreSwitchItem(id: "1", label: "Option one", isOn: true),
        EncoreSwitchItem(id: "2", label: "Option two", isOn: false),
        EncoreSwitchItem(id: "3", label: "Option three", isOn: true)
    ]
    @State private var errorItems = [
        EncoreSwitchItem(id: "4", label: "Option one", isOn: true),
        EncoreSwitchItem(id: "5", label: "Option two", isOn: false),
        EncoreSwitchItem(id: "6", label: "Option three", isOn: false)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.spacing24) {
                EncoreSwitchFormGroup(
                    items: enabledItems,
                    onToggle: { id, value in
                        if let idx = enabledItems.firstIndex(where: { $0.id == id }) {
                            enabledItems[idx].isOn = value
                        }
                    }
                )
                EncoreSwitchFormGroup(
                    items: [
                        EncoreSwitchItem(id: "7", label: "Option one", isOn: true),
                        EncoreSwitchItem(id: "8", label: "Option two", isOn: false),
                        EncoreSwitchItem(id: "9", label: "Option three", isOn: true)
                    ],
                    onToggle: { _, _ in },
                    isDisabled: true
                )
                EncoreSwitchFormGroup(
                    items: errorItems,
                    onToggle: { id, value in
                        if let idx = errorItems.firstIndex(where: { $0.id == id }) {
                            errorItems[idx].isOn = value
                        }
                    },
                    errorMessage: "Please select at least two options"
                )
            }
            .padding(Spacing.spacing16)
        }
        .preferredColorScheme(.light)
    }
}
