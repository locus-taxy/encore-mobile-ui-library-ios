import SwiftUI

public enum LabelPlacement {
    case end, start, top, bottom
}

public struct EncoreSwitchFormControlLabel: View {
    public let isOn: Bool
    public let onToggle: (Bool) -> Void
    public let label: String
    public let labelPlacement: LabelPlacement
    public let isDisabled: Bool
    public let size: EncoreSwitchSize

    public init(
        isOn: Bool,
        onToggle: @escaping (Bool) -> Void,
        label: String,
        labelPlacement: LabelPlacement = .end,
        isDisabled: Bool = false,
        size: EncoreSwitchSize = .medium
    ) {
        self.isOn = isOn
        self.onToggle = onToggle
        self.label = label
        self.labelPlacement = labelPlacement
        self.isDisabled = isDisabled
        self.size = size
    }

    public var body: some View {
        let switchView = EncoreSwitch(isOn: isOn, onToggle: onToggle, size: size, isDisabled: isDisabled)
        let labelView = Text(label)
            .typography(Typography.body1)
            .foregroundColor(isDisabled ? Color.encore("Text/Disabled") : Color.encore("Text/Primary"))

        switch labelPlacement {
        case .end:
            HStack {
                switchView
                labelView
            }
        case .start:
            HStack {
                labelView
                switchView
            }
        case .top:
            VStack(alignment: .center) {
                labelView
                switchView
            }
        case .bottom:
            VStack(alignment: .center) {
                switchView
                labelView
            }
        }
    }
}
