import SwiftUI

public struct MaterialFAB: View {
    var iconName: String
    var contentDescription: String
    var color: FABColor
    var action: () -> Void

    public init(
        iconName: String,
        contentDescription: String,
        color: FABColor = .primary,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.contentDescription = contentDescription
        self.color = color
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image.withName(iconName)
                .renderingMode(.template)
                .resizable()
                .frame(width: Spacing.spacing24, height: Spacing.spacing24)
                .foregroundColor(fabContentColor(color))
        }
        .buttonStyle(.plain)
        .frame(width: Spacing.spacing48, height: Spacing.spacing48)
        .background(fabBackgroundColor(color))
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.20), radius: 5, x: 0, y: 3)
        .shadow(color: .black.opacity(0.14), radius: 10, x: 0, y: 6)
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 1)
        .accessibilityLabel(contentDescription)
    }
}

public struct MaterialExtendedFAB: View {
    var iconName: String
    var label: String
    var contentDescription: String
    var color: FABColor
    var action: () -> Void

    public init(
        iconName: String,
        label: String,
        contentDescription: String,
        color: FABColor = .primary,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.label = label
        self.contentDescription = contentDescription
        self.color = color
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.spacing8) {
                Text(label)
                    .typography(Typography.Button.medium)
                    .foregroundColor(fabContentColor(color))
                Image.withName(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: Spacing.spacing24, height: Spacing.spacing24)
                    .foregroundColor(fabContentColor(color))
            }
            .padding(.horizontal, Spacing.spacing16)
            .padding(.vertical, Spacing.spacing8)
        }
        .buttonStyle(.plain)
        .frame(height: Spacing.spacing48)
        .background(fabBackgroundColor(color))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.20), radius: 5, x: 0, y: 3)
        .shadow(color: .black.opacity(0.14), radius: 10, x: 0, y: 6)
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 1)
        .accessibilityLabel(contentDescription)
    }
}

#Preview("MaterialFABPreview") {
    VStack(spacing: Spacing.spacing24) {
        HStack(spacing: Spacing.spacing24) {
            MaterialFAB(iconName: "LAdd", contentDescription: "Add", color: .primary, action: {})
            MaterialExtendedFAB(iconName: "LAdd", label: "Add", contentDescription: "Add", color: .primary, action: {})
        }
        HStack(spacing: Spacing.spacing24) {
            MaterialFAB(iconName: "LAdd", contentDescription: "Add", color: .secondary, action: {})
            MaterialExtendedFAB(iconName: "LAdd", label: "Add", contentDescription: "Add", color: .secondary, action: {})
        }
        HStack(spacing: Spacing.spacing24) {
            MaterialFAB(iconName: "LAdd", contentDescription: "Add", color: .default, action: {})
            MaterialExtendedFAB(iconName: "LAdd", label: "Add", contentDescription: "Add", color: .default, action: {})
        }
    }
    .padding(Spacing.spacing24)
    .preferredColorScheme(.light)
}
