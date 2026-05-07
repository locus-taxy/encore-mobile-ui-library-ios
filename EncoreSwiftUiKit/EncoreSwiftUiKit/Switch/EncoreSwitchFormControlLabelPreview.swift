import SwiftUI

#Preview("EncoreSwitchFormControlLabelPreview") {
    EncoreSwitchFormControlLabelPreviewLayout()
}

private struct EncoreSwitchFormControlLabelPreviewLayout: View {
    @State private var endOn = true
    @State private var startOn = false
    @State private var topOn = true
    @State private var bottomOn = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.spacing24) {
                EncoreSwitchFormControlLabel(isOn: endOn, onToggle: { endOn = $0 }, label: "End (enabled)", labelPlacement: .end)
                EncoreSwitchFormControlLabel(isOn: false, onToggle: { _ in }, label: "End (disabled)", labelPlacement: .end, isDisabled: true)
                EncoreSwitchFormControlLabel(isOn: startOn, onToggle: { startOn = $0 }, label: "Start (enabled)", labelPlacement: .start)
                EncoreSwitchFormControlLabel(isOn: false, onToggle: { _ in }, label: "Start (disabled)", labelPlacement: .start, isDisabled: true)
                EncoreSwitchFormControlLabel(isOn: topOn, onToggle: { topOn = $0 }, label: "Top (enabled)", labelPlacement: .top)
                EncoreSwitchFormControlLabel(isOn: false, onToggle: { _ in }, label: "Top (disabled)", labelPlacement: .top, isDisabled: true)
                EncoreSwitchFormControlLabel(isOn: bottomOn, onToggle: { bottomOn = $0 }, label: "Bottom (enabled)", labelPlacement: .bottom)
                EncoreSwitchFormControlLabel(isOn: false, onToggle: { _ in }, label: "Bottom (disabled)", labelPlacement: .bottom, isDisabled: true)
            }
            .padding(Spacing.spacing16)
        }
        .preferredColorScheme(.light)
    }
}
