import SwiftUI

// Screen 14 — Customer Stop with the overflow "Undo arrival" popover open (no bottom hint bar).
// Same stop layout as 13; this state simply surfaces the kebab menu. Reuses HFStop* from HFScreen07.
struct HFScreen14: View {
    // Flow-coordinator interaction contract. No swipe/primary CTA in this micro-state, so
    // onPrimary stays unwired (kebab "Undo arrival" is a V1 no-op).
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}
    var body: some View {
        VStack(spacing: 0) {
            HFStopAppBar(showMenu: true, onClose: onClose)
            ScrollView {
                VStack(spacing: 0) {
                    HFStopHeader(statusText: "Arrived", statusFill: Color.encore("Status/BlueBold"))
                    HF14Tasks(onSelect: onSecondary)
                }
            }
            .background(HFColor.screen)
        }
        .background(HFColor.surface.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            HF14UndoPopover()
                .padding(.trailing, Spacing.spacing40)
                .padding(.top, Spacing.spacing48)
        }
    }
}

private struct HF14Tasks: View {
    var onSelect: (Int) -> Void = { _ in }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HFSectionHeader(text: "Tasks (2)")
            VStack(spacing: Spacing.spacing12) {
                HFStopOrderCard(eyebrow: "Order ID 1", quantity: "2 LUs",
                                type: "Deliver", attribute: "Big & bulky",
                                customer: "Priya Sharma", address: "23, Floor 4, Building 2",
                                action: { onSelect(0) })
                HFStopOrderCard(eyebrow: "Order ID 2", quantity: "1 LU",
                                type: "Pickup", attribute: "Fragile",
                                customer: "Rohit Mehta", address: "23, Floor 4, Building 2",
                                action: { onSelect(1) })
            }
            .padding(.horizontal, Spacing.spacing16)
            .padding(.bottom, Spacing.spacing24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.screen)
    }
}

private struct HF14UndoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing2) {
            Text("Undo arrival")
                .typography(Typography.label1)
                .foregroundColor(HFColor.textPrimary)
            Text("01:02m left")
                .typography(Typography.body2)
                .foregroundColor(Color.encore("Error/Main"))
        }
        .padding(Spacing.spacing12)
        .background(RoundedRectangle(cornerRadius: 8).fill(HFColor.surface))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(HFColor.divider, lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
    }
}
