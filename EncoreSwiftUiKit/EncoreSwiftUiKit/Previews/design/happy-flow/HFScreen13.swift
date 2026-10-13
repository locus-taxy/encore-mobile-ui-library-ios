import SwiftUI

// Screen 13 — Customer Stop (revised) with the app-bar overflow menu open. STOP 1 "Arrived",
// verified customer, Navigate + Facing issues? pills, Tasks(2) order cards. The kebab reveals a
// popover ("Undo arrival · 01:02m left") and a persistent bottom hint repeats the countdown.
// Reuses HFStop* from HFScreen07.
struct HFScreen13: View {
    // Flow-coordinator interaction contract. This micro-state has no swipe/primary CTA, so
    // onPrimary stays unwired (kebab "Undo arrival" and the bottom hint are V1 no-ops).
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}
    var body: some View {
        VStack(spacing: 0) {
            HFStopAppBar(showMenu: true, onClose: onClose)
            ScrollView {
                VStack(spacing: 0) {
                    HFStopHeader(statusText: "Arrived", statusFill: Color.encore("Status/BlueBold"))
                    HF13Tasks(onSelect: onSecondary)
                }
            }
            .background(HFColor.screen)

            Text("Undo stop arrival for 01:02m")
                .typography(Typography.body2)
                .foregroundColor(HFColor.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.spacing16)
                .background(HFColor.surface)
        }
        .background(HFColor.surface.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            HF13UndoPopover()
                .padding(.trailing, Spacing.spacing40)
                .padding(.top, Spacing.spacing48)
        }
    }
}

// Tasks(2) for this stop — Priya Sharma (Deliver) + Rohit Mehta (Pickup), per the Figma render.
private struct HF13Tasks: View {
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

// Overflow-menu popover anchored under the kebab.
private struct HF13UndoPopover: View {
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
