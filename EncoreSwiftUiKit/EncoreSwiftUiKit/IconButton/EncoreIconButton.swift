import SwiftUI

public enum EncoreIconButtonColor {
    case defaultColor
    case primary
    case error
    case success
}

public enum EncoreIconButtonSize {
    case small
    case medium
    case large
}

public struct EncoreIconButton: View {
    @Environment(\.isEnabled) private var isEnabled

    private let iconName: String
    private let color: EncoreIconButtonColor
    private let size: EncoreIconButtonSize
    private let action: () -> Void

    public init(
        iconName: String,
        color: EncoreIconButtonColor = .defaultColor,
        size: EncoreIconButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.color = color
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            EncoreIcon(iconName: iconName, size: 24)
                .foregroundColor(iconColor)
                .padding(innerPadding)
        }
        .buttonStyle(.plain)
        .frame(width: 48, height: 48)
    }

    private var iconColor: Color {
        encoreIconButtonIconColor(color: color, isEnabled: isEnabled)
    }

    private var innerPadding: CGFloat {
        switch size {
        case .large: return Spacing.spacing12
        case .medium: return Spacing.spacing8
        case .small: return 5
        }
    }
}
