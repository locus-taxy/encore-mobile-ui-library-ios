import SwiftUI

// Screen 22 — Pickup Task (start): task-detail before starting. White head (order identifier,
// recipient, address, Call action) over the grey "LOGISTIC UNIT (1)" list, with a bottom
// slide-to-confirm "Swipe to start task". Copy quoted from the Figma render.
struct HFScreen22: View {
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HFTitleBar(title: "Pickup Task", leading: .back, trailing: .close,
                       onBack: onClose, onClose: onClose)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: Spacing.spacing12) {
                        HF22Identifier(text: "Order ID 2")
                        Text("Rohit Mehta")
                            .typography(Typography.h6)
                            .foregroundColor(HFColor.textPrimary)
                        Text("Mayur Greens, 4th Floor, 87-148, Koramangala, Bengaluru, 560034")
                            .typography(Typography.body2)
                            .foregroundColor(HFColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Divider().overlay(HFColor.divider)

                        HF22ActionPill(icon: "LCall", label: "Call")
                    }
                    .padding(Spacing.spacing16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HFColor.surface)

                    HFSectionHeader(text: "Logistic unit (1)")
                    VStack(spacing: Spacing.spacing12) {
                        HF22LUCard(id: "LU ID 1", count: "1 item", tag: "Fragile")
                    }
                    .padding(.horizontal, Spacing.spacing16)
                    .padding(.bottom, Spacing.spacing24)
                }
            }
            .background(HFColor.screen)

            // Slide-to-confirm footer (standardized to the shared 16-all-sides CTA padding)
            HFSheetFooter {
                SlidingButtonView(label: "Swipe to start task", onSlideComplete: { onPrimary() })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HFColor.surface.ignoresSafeArea())
    }
}

// MARK: - Screen-local subviews

// ORDER ID eyebrow: overline2, no underline (the dotted underline is reserved for STOP headers).
private struct HF22Identifier: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .typography(Typography.overline2)
            .foregroundColor(HFColor.textSecondary)
    }
}

private struct HF22ActionPill: View {
    var icon: String? = nil
    let label: String
    var body: some View {
        HStack(spacing: Spacing.spacing4) {
            if let icon {
                EncoreIcon(iconName: icon, size: 14)
                    .foregroundColor(HFColor.primary)
            }
            Text(label)
                .typography(Typography.Button.small)
                .foregroundColor(HFColor.primary)
        }
        .padding(.horizontal, Spacing.spacing12)
        .padding(.vertical, Spacing.spacing6)
        .background(HFColor.primary.opacity(0.08))
        .overlay(Capsule().stroke(Color.encore("Primary/FocusVisible"), lineWidth: 0.5))
        .clipShape(Capsule())
    }
}

private struct HF22LUCard: View {
    let id: String
    let count: String
    var tag: String?
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            Text(id)
                .typography(Typography.label1)
                .foregroundColor(HFColor.textPrimary)
            Text(count)
                .typography(Typography.body1)
                .foregroundColor(HFColor.textSecondary)
            if let tag {
                HFPillChip(text: tag, bg: HFColor.screen, fg: HFColor.textSecondary, dot: false)
            }
        }
        .padding(Spacing.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(HFColor.divider, lineWidth: 0.5))
    }
}
