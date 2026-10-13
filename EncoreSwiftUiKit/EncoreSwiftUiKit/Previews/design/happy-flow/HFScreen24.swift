import SwiftUI

// Screen 24 — POD (incomplete): Figma placeholder/stub frame, rendered as drawn.
// Centered "…." + "POD (incomplete)" label, and a bottom circular "next" affordance
// (blue chevron on a primary-tint disc) that carries the flow forward.
struct HFScreen24: View {
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}

    var body: some View {
        ZStack {
            HFColor.screen.ignoresSafeArea()

            VStack(spacing: Spacing.spacing8) {
                Text("….")
                    .typography(Typography.h6)
                    .foregroundColor(HFColor.textPrimary)
                Text("POD (incomplete)")
                    .typography(Typography.h5)
                    .foregroundColor(HFColor.textPrimary)
            }

            VStack {
                Spacer()
                Button(action: onPrimary) {
                    HF24NextButton()
                }
                .buttonStyle(.plain)
                .padding(.bottom, Spacing.spacing56)
            }
        }
    }
}

// MARK: - Circular forward affordance

private struct HF24NextButton: View {
    var body: some View {
        EncoreIcon(iconName: "LArrowChevronRight", size: 20)
            .foregroundColor(HFColor.primary)
            .frame(width: 48, height: 48)
            .background(HFColor.primary.opacity(0.08))
            .clipShape(Circle())
    }
}

#Preview("HF 24 — POD (incomplete)") {
    HFScreen24()
}
