import SwiftUI

// Screen 25 — Pickup Task detail. White app bar (back + title + close), white identity
// header (Order ID + Failed status, contact name, org, call action), then a grey list with
// the single logistic unit card.
struct HFScreen25: View {
    var body: some View {
        VStack(spacing: 0) {
            HF25AppBar(title: "Pickup Task")

            HF25TaskHeader()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HFSectionHeader(text: "Logistic unit (1)")
                    HF25LogisticUnitCard()
                        .padding(.horizontal, Spacing.spacing16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, Spacing.spacing24)
            }
            .background(HFColor.screen)
        }
        .background(HFColor.surface.ignoresSafeArea())
    }
}

// MARK: - App bar

private struct HF25AppBar: View {
    let title: String
    var body: some View {
        HFTitleBar(title: title, leading: .back, trailing: .close)
    }
}

// MARK: - Task identity header

private struct HF25TaskHeader: View {
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.spacing16) {
            VStack(alignment: .leading, spacing: Spacing.spacing4) {
                HStack(spacing: Spacing.spacing8) {
                    HF25Eyebrow(text: "ORDER ID 2")
                    HFStatusChip(text: "Failed", fill: Color.encore("Status/RedBold"))
                }
                Text("Rohit Mehta")
                    .typography(Typography.h6)
                    .foregroundColor(HFColor.textPrimary)
                Text("Locus - Logistics Optimization & Decision-making Platform")
                    .typography(Typography.body2)
                    .foregroundColor(HFColor.textSecondary)
            }
            HF25CircleAction(icon: "LCall")
        }
        .padding(Spacing.spacing16)
        .background(HFColor.surface)
    }
}

// MARK: - Logistic unit card

private struct HF25LogisticUnitCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            Text("LU ID 1")
                .typography(Typography.label1)
                .foregroundColor(HFColor.textPrimary)
            Text("1 item")
                .typography(Typography.body2)
                .foregroundColor(HFColor.textSecondary)
            HFPillChip(text: "Fragile", bg: HFColor.screen, fg: HFColor.textSecondary, dot: false)
                .padding(.top, Spacing.spacing4)
        }
        .padding(Spacing.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(HFColor.divider, lineWidth: 0.5))
    }
}

// MARK: - Shared bits (private to screen 25)

private struct HF25CircleAction: View {
    let icon: String
    var body: some View {
        EncoreIcon(iconName: icon, size: 20)
            .foregroundColor(HFColor.primary)
            .frame(width: 40, height: 40)
            .background(HFColor.primary.opacity(0.08))
            .clipShape(Circle())
    }
}

// ORDER ID eyebrow: overline2, no underline (the dotted underline is reserved for STOP headers).
private struct HF25Eyebrow: View {
    let text: String
    var body: some View {
        Text(text)
            .typography(Typography.overline2)
            .foregroundColor(HFColor.textSecondary)
    }
}

#Preview("HF 25 — Pickup Task") {
    HFScreen25()
}
