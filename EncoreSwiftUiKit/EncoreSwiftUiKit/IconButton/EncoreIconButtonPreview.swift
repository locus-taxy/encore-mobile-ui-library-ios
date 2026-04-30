import SwiftUI

#Preview("EncoreIconButton-Primary") {
    EncoreIconButtonPreviewLayout(color: .primary)
}

#Preview("EncoreIconButton-Default") {
    EncoreIconButtonPreviewLayout(color: .defaultColor)
}

#Preview("EncoreIconButton-Error") {
    EncoreIconButtonPreviewLayout(color: .error)
}

#Preview("EncoreIconButton-Success") {
    EncoreIconButtonPreviewLayout(color: .success)
}

private struct EncoreIconButtonPreviewLayout: View {
    let color: EncoreIconButtonColor

    private let sizes: [EncoreIconButtonSize] = [.large, .medium, .small]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.spacing24) {
                ForEach(sizes.indices, id: \.self) { si in
                    let size = sizes[si]
                    VStack(alignment: .leading, spacing: Spacing.spacing8) {
                        Text("\(String(describing: size))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        EncoreIconButton(
                            iconName: "LAdd",
                            color: color,
                            size: size,
                            action: {}
                        )
                        EncoreIconButton(
                            iconName: "LAdd",
                            color: color,
                            size: size,
                            action: {}
                        )
                        .disabled(true)
                    }
                }
            }
            .padding(Spacing.spacing16)
        }
        .preferredColorScheme(.light)
    }
}
