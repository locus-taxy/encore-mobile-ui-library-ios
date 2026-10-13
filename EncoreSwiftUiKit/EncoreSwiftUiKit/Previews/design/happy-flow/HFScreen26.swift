import SwiftUI

// Screen 26 — Customer Stop (completed). Shared app bar + a compact stop header: STOP 1 + green
// "Completed" chip, verified title, address, window, and a circular Navigate affordance top-right
// (this state has no divider/pill row, unlike 07/21). Grey "TASKS (2)" list below.
//
// SCOPE NOTE: Figma 26 shows Order 2 as "Failed" (red) — a mixed-outcome stop. V1 does not carry a
// failed-task state, so Order 2 is rendered "Completed" here. See the residual-gaps report.
// Reuses HFStop* (app bar, tasks, dotted eyebrow, verified title) from HFScreen07.
struct HFScreen26: View {
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HFStopAppBar(onClose: onClose)
            ScrollView {
                VStack(spacing: 0) {
                    HF26StopHeader()
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onPrimary)
                    HFStopTasks(onSelect: onSecondary,
                                order1Status: "Completed", order1StatusFill: HFColor.success,
                                order2Status: "Completed", order2StatusFill: HFColor.success)
                }
            }
            .background(HFColor.screen)
        }
        .background(HFColor.surface.ignoresSafeArea())
    }
}

// MARK: - Compact stop header (completed): text block + circular Navigate on the right.

private struct HF26StopHeader: View {
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.spacing16) {
            VStack(alignment: .leading, spacing: Spacing.spacing12) {
                HStack(spacing: Spacing.spacing8) {
                    HFDottedEyebrow(text: "STOP 1")
                    HFStatusChip(text: "Completed", fill: HFColor.success)
                }
                HFStopTitle()
                Text("Mayur Greens, 4th Floor, 87-148, Koramangala, Bengaluru, 560034")
                    .typography(Typography.body2)
                    .foregroundColor(HFColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("08:30 - 10:00")
                    .typography(Typography.body2)
                    .foregroundColor(HFColor.textSecondary)
            }
            HF26CircleNavigate()
        }
        .padding(Spacing.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.surface)
    }
}

private struct HF26CircleNavigate: View {
    var body: some View {
        EncoreIcon(iconName: "LNavigationOutlined", size: 20)
            .foregroundColor(HFColor.primary)
            .frame(width: 40, height: 40)
            .background(HFColor.primary.opacity(0.08))
            .clipShape(Circle())
    }
}

#Preview("HF 26 — Customer Stop · Completed") {
    HFScreen26()
}
