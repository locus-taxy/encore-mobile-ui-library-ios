import SwiftUI

#Preview("EncoreButton-Contained") {
    EncoreButtonPreviewLayout(variant: .contained)
}

#Preview("EncoreButton-Outlined") {
    EncoreButtonPreviewLayout(variant: .outlined)
}

#Preview("EncoreButton-Text") {
    EncoreButtonPreviewLayout(variant: .text)
}

private struct EncoreButtonPreviewLayout: View {
    let variant: EncoreButtonVariant

    private let colors: [EncoreButtonColor] = [.primary, .error, .success]
    private let sizes: [EncoreButtonSize] = [.xlarge, .large, .medium]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.spacing24) {
                ForEach(sizes.indices, id: \.self) { si in
                    let size = sizes[si]
                    VStack(alignment: .leading, spacing: Spacing.spacing8) {
                        Text("\(String(describing: size))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(colors.indices, id: \.self) { ci in
                            EncoreButton(
                                label: "Label",
                                startIconName: "LAdd",
                                color: colors[ci],
                                variant: variant,
                                size: size,
                                action: {}
                            )
                        }
                        ForEach(colors.indices, id: \.self) { ci in
                            EncoreButton(
                                label: "Label",
                                startIconName: "LAdd",
                                color: colors[ci],
                                variant: variant,
                                size: size,
                                action: {}
                            )
                            .disabled(true)
                        }
                    }
                }
            }
            .padding(Spacing.spacing16)
        }
        .preferredColorScheme(.light)
    }
}
