import SwiftUI

// Screen 28 — Delivery home, end of flow. Same shift app bar / tabs / bottom nav as Home,
// but Trip 1 now shows the Completed status chip and "1 stop completed" progress — the trip
// the rider just finished. Remaining trips render in their pending state.
struct HFScreen28: View {
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HFHomeAppBar()
            HFTabs(tabs: ["Today (2)", "Tomorrow (1)"], selection: .constant(0))

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HFSectionHeader(text: "Today (2)")
                    VStack(spacing: Spacing.spacing8) {
                        HF28CompletedTripCard(
                            eyebrow: "Trip 1",
                            title: "08:30-11:00 · ~17 kms",
                            progress: "1 stop completed",
                            chips: ["1 Pickup", "1 Delivery"]
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { onSecondary(0) }
                        HFTripCard(eyebrow: "Trip 2", title: "14:30-18:00 · ~17 kms", sub: "6 stops",
                                   chips: [("5 Pickup", true), ("9 Deliveries", false)])
                        .contentShape(Rectangle())
                        .onTapGesture { onSecondary(1) }
                    }
                    .padding(.horizontal, Spacing.spacing16)

                    HFSectionHeader(text: "Tomorrow (1)")
                    VStack(spacing: Spacing.spacing8) {
                        HFTripCard(eyebrow: "Trip 1", title: "14:30-18:00 · ~17 kms", sub: "6 stops",
                                   chips: [("5 Pickup", true), ("9 Deliveries", false)])
                        .contentShape(Rectangle())
                        .onTapGesture { onSecondary(2) }
                    }
                    .padding(.horizontal, Spacing.spacing16)
                    .padding(.bottom, Spacing.spacing24)
                }
            }
            .background(HFColor.screen)

            HFBottomNav(activeIndex: 2)
        }
        .background(HFColor.surface.ignoresSafeArea())
    }
}

// MARK: - Completed trip card (status chip + progress row)

private struct HF28CompletedTripCard: View {
    let eyebrow: String
    let title: String
    let progress: String
    let chips: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            HStack(spacing: Spacing.spacing8) {
                Text(eyebrow.uppercased())
                    .typography(Typography.overline2)
                    .foregroundColor(HFColor.textSecondary)
                HFStatusChip(text: "Completed", fill: HFColor.success)
            }
            Text(title)
                .typography(Typography.h6)
                .foregroundColor(HFColor.textPrimary)
            HStack(spacing: Spacing.spacing8) {
                EncoreIcon(iconName: "LCheckCircle", size: 16)
                    .foregroundColor(HFColor.success)
                Text(progress)
                    .typography(Typography.body2)
                    .foregroundColor(HFColor.textSecondary)
            }
            HStack(spacing: Spacing.spacing8) {
                ForEach(chips, id: \.self) { c in
                    HFPillChip(text: c, glyph: c.contains("Pickup") ? .pickup : .deliver)
                }
            }
            .padding(.top, Spacing.spacing4)
        }
        .padding(Spacing.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(HFColor.divider, lineWidth: 0.5))
    }
}

#Preview("HF 28 — Delivery (trip complete)") {
    HFScreen28()
}
