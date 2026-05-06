import SwiftUI

public enum EncoreButtonColor {
    case primary
    case error
    case success
}

public enum EncoreButtonVariant {
    case contained
    case outlined
    case text
}

public enum EncoreButtonSize {
    case medium
    case large
    case xlarge
}

public struct EncoreButton: View {
    @Environment(\.isEnabled) private var isEnabled

    private let label: String
    private let startIconName: String?
    private let color: EncoreButtonColor
    private let variant: EncoreButtonVariant
    private let size: EncoreButtonSize
    private let action: () -> Void

    public init(
        label: String,
        startIconName: String? = nil,
        color: EncoreButtonColor = .primary,
        variant: EncoreButtonVariant = .contained,
        size: EncoreButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.startIconName = startIconName
        self.color = color
        self.variant = variant
        self.size = size
        self.action = action
    }

    public var body: some View {
        let contentColor = encoreButtonContentColor(color: color, variant: variant, isEnabled: isEnabled)
        let backgroundColor = encoreButtonBackgroundColor(color: color, variant: variant, isEnabled: isEnabled)
        let borderColor = encoreButtonBorderColor(color: color, isEnabled: isEnabled)

        Button(action: action) {
            HStack(spacing: 0) {
                if let startIconName {
                    EncoreIcon(iconName: startIconName, size: iconSize)
                        .foregroundColor(contentColor)
                        .frame(width: iconSize, height: iconSize)
                        .clipped()
                }
                Text(label)
                    .typography(font)
                    .foregroundColor(contentColor)
                    .lineLimit(1)
                    .padding(.horizontal, labelHPadding)
                EncoreIcon(iconName: "LArrowDropDown", size: iconSize)
                    .foregroundColor(contentColor)
                    .frame(width: iconSize, height: iconSize)
                    .clipped()
            }
            .padding(.vertical, vPadding)
            .padding(.horizontal, hPadding)
        }
        .buttonStyle(.plain)
        .background(backgroundColor)
        .overlay(
            Group {
                if variant == .outlined {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: 1)
                }
            }
        )
        .cornerRadius(4)
        .clipped()
        .frame(minWidth: 64, minHeight: 48)
    }

    private var vPadding: CGFloat {
        switch size {
        case .xlarge: return Spacing.spacing12
        case .large: return Spacing.spacing8
        case .medium: return Spacing.spacing6
        }
    }

    private var hPadding: CGFloat {
        switch size {
        case .xlarge: return Spacing.spacing16
        case .large: return Spacing.spacing12
        case .medium: return Spacing.spacing8
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .xlarge, .large: return Spacing.spacing24
        case .medium: return Spacing.spacing20
        }
    }

    private var labelHPadding: CGFloat {
        switch size {
        case .xlarge: return Spacing.spacing8
        case .large: return Spacing.spacing6
        case .medium: return Spacing.spacing4
        }
    }

    private var font: TypographyStyle {
        switch size {
        case .xlarge, .large: return Typography.Button.large
        case .medium: return Typography.Button.medium
        }
    }
}
