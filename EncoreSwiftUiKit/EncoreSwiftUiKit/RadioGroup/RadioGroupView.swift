import SwiftUI

/// Placement of the label relative to the radio icon in `RadioView`.
public enum RadioLabelPlacement {
    case end
    case start
    case top
    case bottom
}

/// Internal radio icon. Renders an SF Symbol with the appropriate color token
/// for the (selected, disabled) state combination.
struct RadioIcon: View {
    let isSelected: Bool
    let isDisabled: Bool

    var body: some View {
        Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
            .foregroundColor(iconColor)
            .padding(Spacing.spacing6)
            .frame(width: Spacing.spacing48, height: Spacing.spacing48)
    }

    private var iconColor: Color {
        if isDisabled { return Color.encore("Action/Disabled") }
        return isSelected ? Color.encore("Primary/Main") : Color.encore("Action/Active")
    }
}

/// A single radio option with a label and optional secondary label. The radio
/// icon position is configurable via `labelPlacement`. State (selected,
/// disabled) is parent-driven; tap fires `onTap` only when not disabled.
public struct RadioView: View {
    let label: String
    let secondaryLabel: String?
    let isSelected: Bool
    let isDisabled: Bool
    let labelPlacement: RadioLabelPlacement
    let onTap: () -> Void

    public init(
        label: String,
        secondaryLabel: String? = nil,
        isSelected: Bool,
        isDisabled: Bool = false,
        labelPlacement: RadioLabelPlacement = .end,
        onTap: @escaping () -> Void
    ) {
        self.label = label
        self.secondaryLabel = secondaryLabel
        self.isSelected = isSelected
        self.isDisabled = isDisabled
        self.labelPlacement = labelPlacement
        self.onTap = onTap
    }

    public var body: some View {
        layout
            .contentShape(Rectangle())
            .onTapGesture {
                if !isDisabled { onTap() }
            }
    }

    @ViewBuilder
    private var layout: some View {
        switch labelPlacement {
        case .end:
            HStack(spacing: 0) {
                radioIcon.padding(.trailing, -Spacing.spacing8)
                labelStack(alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .start:
            HStack(spacing: 0) {
                labelStack(alignment: .trailing)
                radioIcon.padding(.leading, -Spacing.spacing8)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        case .top:
            VStack(alignment: .center, spacing: 0) {
                labelStack(alignment: .center)
                radioIcon
            }
            .frame(maxWidth: .infinity, alignment: .center)
        case .bottom:
            VStack(alignment: .center, spacing: 0) {
                radioIcon
                labelStack(alignment: .center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var radioIcon: some View {
        RadioIcon(isSelected: isSelected, isDisabled: isDisabled)
    }

    private func labelStack(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 0) {
            Text(label)
                .typography(Typography.body1)
                .foregroundColor(isDisabled ? Color.encore("Text/Disabled") : Color.encore("Text/Primary"))
            if let secondaryLabel {
                Text(secondaryLabel)
                    .typography(Typography.body2)
                    .foregroundColor(isDisabled ? Color.encore("Text/Disabled") : Color.encore("Text/Secondary"))
            }
        }
    }
}
