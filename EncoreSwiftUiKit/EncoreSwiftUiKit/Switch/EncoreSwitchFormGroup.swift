import SwiftUI

public struct EncoreSwitchItem: Identifiable {
    public let id: String
    public let label: String
    public var isOn: Bool

    public init(id: String, label: String, isOn: Bool) {
        self.id = id
        self.label = label
        self.isOn = isOn
    }
}

public struct EncoreSwitchFormGroup: View {
    public let items: [EncoreSwitchItem]
    public let onToggle: (String, Bool) -> Void
    public let isDisabled: Bool
    public let errorMessage: String?
    public let labelPlacement: LabelPlacement

    public init(
        items: [EncoreSwitchItem],
        onToggle: @escaping (String, Bool) -> Void,
        isDisabled: Bool = false,
        errorMessage: String? = nil,
        labelPlacement: LabelPlacement = .end
    ) {
        self.items = items
        self.onToggle = onToggle
        self.isDisabled = isDisabled
        self.errorMessage = errorMessage
        self.labelPlacement = labelPlacement
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                EncoreSwitchFormControlLabel(
                    isOn: item.isOn,
                    onToggle: { newValue in onToggle(item.id, newValue) },
                    label: item.label,
                    labelPlacement: labelPlacement,
                    isDisabled: isDisabled
                )
            }
            if let errorMessage {
                Spacer().frame(height: Spacing.spacing4)
                Text(errorMessage)
                    .typography(Typography.body2)
                    .foregroundColor(Color.encore("Error/Main"))
            }
        }
    }
}
