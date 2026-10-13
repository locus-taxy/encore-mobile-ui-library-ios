import SwiftUI

// Screen 17 — Delivery Task, in progress. ORDER ID carries an "In progress" chip and the head adds
// a "Facing issues?" pill beside Call. A dark "Task 1 started" toast is pinned to the bottom
// (replacing the swipe control once the task has started). Reuses HFDelivery* from HFScreen16.
struct HFScreen17: View {
    // Flow-coordinator interaction contract. Task already started (toast shown, no swipe control),
    // so onPrimary stays unwired; the toast dismiss is a V1 no-op. onSecondary unused (no order cards).
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}
    var body: some View {
        VStack(spacing: 0) {
            HFDeliveryAppBar(title: "Delivery Task", onClose: onClose)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HFDeliveryHeader(status: "In progress",
                                     statusFill: Color.encore("Status/BlueBold"),
                                     showFacingIssues: true)
                    HFDeliveryUnits()
                }
            }
            .background(HFColor.screen)
            .contentShape(Rectangle())
            .onTapGesture { onPrimary() }   // task started → capture proof of delivery
        }
        .background(HFColor.surface.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            HF17Toast(text: "Task 1 started")
        }
    }
}

// Dark bottom toast with a leading check and trailing dismiss.
private struct HF17Toast: View {
    let text: String
    var body: some View {
        HStack(spacing: Spacing.spacing12) {
            EncoreIcon(iconName: "LCheckCircle", size: 24)
                .foregroundColor(HFColor.onPrimary)
            Text(text)
                .typography(Typography.body1)
                .foregroundColor(HFColor.onPrimary)
            Spacer(minLength: Spacing.spacing8)
            EncoreIcon(iconName: "LCross", size: 20)
                .foregroundColor(HFColor.onPrimary)
        }
        .padding(Spacing.spacing16)
        .background(HFColor.toast)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, Spacing.spacing16)
        .padding(.bottom, Spacing.spacing16)
    }
}
