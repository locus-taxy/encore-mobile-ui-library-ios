import SwiftUI

// Screen 15 — Customer Stop, resting state. App bar shows only close (no kebab); no popover.
// Verified "Arrived" stop, Navigate + Facing issues? pills, Tasks(2) order cards.
// Reuses HFStop* from HFScreen07.
struct HFScreen15: View {
    // Flow-coordinator interaction contract. Resting state has no swipe/primary CTA, so
    // onPrimary stays unwired.
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}
    var body: some View {
        VStack(spacing: 0) {
            HFStopAppBar(showMenu: false, onClose: onClose)
            ScrollView {
                VStack(spacing: 0) {
                    HFStopHeader(statusText: "Arrived", statusFill: Color.encore("Status/BlueBold"))
                    HF15Tasks(onSelect: onSecondary)
                }
            }
            .background(HFColor.screen)
        }
        .background(HFColor.surface.ignoresSafeArea())
    }
}

private struct HF15Tasks: View {
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
