import SwiftUI

// Screen 18 — POD (Success) placeholder/stub. Figma leaves this frame as a centered label with a
// forward chevron button; rendered as drawn.
struct HFScreen18: View {
    // Flow-coordinator interaction contract. Success stub: the forward-chevron advances the flow.
    // No close affordance or cards in this stub, so onClose/onSecondary stay unwired.
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}
    var body: some View {
        ZStack {
            HFColor.screen.ignoresSafeArea()

            VStack(spacing: Spacing.spacing8) {
                Text("....")
                    .typography(Typography.h5)
                    .foregroundColor(HFColor.textPrimary)
                Text("POD (Success)")
                    .typography(Typography.h5)
                    .foregroundColor(HFColor.textPrimary)
            }

            VStack {
                Spacer()
                Button(action: onPrimary) {
                    EncoreIcon(iconName: "LArrowChevronRight", size: 20)
                        .foregroundColor(HFColor.primary)
                        .frame(width: 20, height: 20)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(HFColor.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .padding(.bottom, Spacing.spacing96)
            }
        }
    }
}
