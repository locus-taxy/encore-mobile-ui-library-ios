import SwiftUI

// Screen 20 — Delivery Task (Completed, resting): same task-detail as screen 19 but with the
// completion toast dismissed. White head (identifier + green "Completed", recipient, address,
// Call, info banner) over the grey "LOGISTIC UNITS (2)" list. Copy quoted from the Figma render.
struct HFScreen20: View {
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HF20NavHeader(title: "Delivery Task", onClose: onClose)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: Spacing.spacing12) {
                        HStack(alignment: .center, spacing: Spacing.spacing8) {
                            HF20Identifier(text: "Order ID 1")
                            HFStatusChip(text: "Completed", fill: HFColor.success)
                        }
                        Text("Priya Sharma")
                            .typography(Typography.h6)
                            .foregroundColor(HFColor.textPrimary)
                        Text("Mayur Greens, 4th Floor, 87-148, Koramangala, Bengaluru, 560034")
                            .typography(Typography.body2)
                            .foregroundColor(HFColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Divider().overlay(HFColor.divider)

                        HF20ActionPill(icon: "LCall", label: "Call")

                        HF20InfoBanner(text: "Call on arrival, don't ring the doorbell.")
                            .padding(.top, Spacing.spacing4)
                    }
                    .padding(Spacing.spacing16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HFColor.surface)

                    HFSectionHeader(text: "Logistic units (2)")
                    VStack(spacing: Spacing.spacing12) {
                        HF20LUCard(id: "LU ID 1", count: "1 item", tag: "Big & bulky")
                        HF20LUCard(id: "LU ID 2", count: "4 items", tag: nil)
                    }
                    .padding(.horizontal, Spacing.spacing16)
                    .padding(.bottom, Spacing.spacing24)
                }
                .contentShape(Rectangle())
                .onTapGesture { onPrimary() }
            }
            .background(HFColor.screen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HFColor.surface.ignoresSafeArea())
    }
}

// MARK: - Screen-local subviews

private struct HF20NavHeader: View {
    let title: String
    var onClose: () -> Void = {}
    var body: some View {
        HStack(spacing: Spacing.spacing16) {
            EncoreIcon(iconName: "LChevronLeft", size: 24)
                .foregroundColor(HFColor.textPrimary)
                .onTapGesture { onClose() }
            Text(title)
                .typography(Typography.label0)
                .foregroundColor(HFColor.textPrimary)
            Spacer()
            EncoreIcon(iconName: "LCross", size: 24)
                .foregroundColor(HFColor.textPrimary)
                .onTapGesture { onClose() }
        }
        .padding(.horizontal, Spacing.spacing16)
        .frame(height: 56)
        .background(HFColor.surface)
    }
}

// ORDER ID eyebrow: overline2, no underline (the dotted underline is reserved for STOP headers).
private struct HF20Identifier: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .typography(Typography.overline2)
            .foregroundColor(HFColor.textSecondary)
    }
}

private struct HF20ActionPill: View {
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

private struct HF20InfoBanner: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.spacing8) {
            EncoreIcon(iconName: "LInformation", size: 20)
                .foregroundColor(HFColor.infoText)
            Text(text)
                .typography(Typography.body1)
                .foregroundColor(HFColor.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(Spacing.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.infoBg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct HF20LUCard: View {
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
