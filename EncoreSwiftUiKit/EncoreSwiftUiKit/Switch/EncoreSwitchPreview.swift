import SwiftUI

#Preview("EncoreSwitchPreview") {
    EncoreSwitchPreviewLayout()
}

private struct EncoreSwitchPreviewLayout: View {
    @State private var mediumCheckedEnabled = true
    @State private var mediumUncheckedEnabled = false
    @State private var smallCheckedEnabled = true
    @State private var smallUncheckedEnabled = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.spacing24) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.spacing24) {
                    EncoreSwitch(isOn: mediumCheckedEnabled, onToggle: { mediumCheckedEnabled = $0 }, size: .medium)
                    EncoreSwitch(isOn: smallCheckedEnabled, onToggle: { smallCheckedEnabled = $0 }, size: .small)
                    EncoreSwitch(isOn: mediumUncheckedEnabled, onToggle: { mediumUncheckedEnabled = $0 }, size: .medium)
                    EncoreSwitch(isOn: smallUncheckedEnabled, onToggle: { smallUncheckedEnabled = $0 }, size: .small)
                    EncoreSwitch(isOn: true, onToggle: { _ in }, size: .medium, isDisabled: true)
                    EncoreSwitch(isOn: true, onToggle: { _ in }, size: .small, isDisabled: true)
                    EncoreSwitch(isOn: false, onToggle: { _ in }, size: .medium, isDisabled: true)
                    EncoreSwitch(isOn: false, onToggle: { _ in }, size: .small, isDisabled: true)
                }
            }
            .padding(Spacing.spacing16)
        }
        .preferredColorScheme(.light)
    }
}
