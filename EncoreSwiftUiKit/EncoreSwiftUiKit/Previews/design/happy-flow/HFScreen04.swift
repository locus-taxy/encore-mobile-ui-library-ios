import SwiftUI

// Screen 04 — Trip detail just after starting (In transit). Full header gains an "In transit" status
// chip, a progress bar and a "0/1 stop completed" line; the stop card gains a navigate action. A dark
// "Trip 1 started" toast sits pinned near the bottom.
struct HFScreen04: View {
    var onPrimary: () -> Void = {}          // the main forward action
    var onSecondary: (Int) -> Void = { _ in } // drill-in taps (cards), indexed 0,1,…
    var onClose: () -> Void = {}            // X / back

    var body: some View {
        VStack(spacing: 0) {
            HF04AppBar(title: "Trip", onClose: onClose)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HF04Summary()

                    HFSectionHeader(text: "Stops (1)")
                    Button { onSecondary(0) } label: {
                        HFStopCard(showNavigate: true)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.spacing16)
                    .padding(.bottom, Spacing.spacing24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(HFColor.screen)

            // "Trip 1 started" feedback rises from behind this footer (framework toast).
            HF04StartHubPickupBar(onPrimary: onPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HFColor.surface.ignoresSafeArea())
    }
}

// MARK: - App bar

private struct HF04AppBar: View {
    let title: String
    var onClose: () -> Void = {}
    var body: some View {
        HFTitleBar(title: title, leading: .back, onBack: onClose)
    }
}

// MARK: - Summary header (in transit)

private struct HF04Summary: View {
    @Environment(\.hfViewDetails) private var viewDetails
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            HStack(spacing: Spacing.spacing8) {
                HFCopyableEyebrow(text: "TRIP 1", entity: "Trip", id: HFEntityID.trip)
                HFStatusChip(text: "In transit", fill: HFColor.primary)
            }
            Text("08:30-11:00 · ~17 kms")
                .typography(Typography.h5)
                .foregroundColor(HFColor.textPrimary)
            HF04ProgressBar(fraction: 0)
            HStack(spacing: Spacing.spacing8) {
                EncoreIcon(iconName: "LCheckCircle", size: 16)
                    .foregroundColor(HFColor.success)
                Text("0/1 stop completed")
                    .typography(Typography.body2)
                    .foregroundColor(HFColor.textSecondary)
            }
            HStack(spacing: Spacing.spacing8) {
                HFPillChip(text: "1 Pickup", glyph: .pickup)
                HFPillChip(text: "1 Delivery", glyph: .deliver)
            }
            .padding(.top, Spacing.spacing2)

            Divider().overlay(HFColor.divider)
                .padding(.vertical, Spacing.spacing8)

            HStack(spacing: Spacing.spacing12) {
                HFTintButton(label: "Map", icon: "LLocationMap")
                HFTintButton(label: "View details", action: viewDetails)
            }
        }
        .padding(Spacing.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.surface)
    }
}

private struct HF04ProgressBar: View {
    let fraction: CGFloat
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(HFColor.primary.opacity(0.15))
                Capsule().fill(HFColor.primary)
                    .frame(width: max(0, geo.size.width * fraction))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Bottom action (swipe to start the hub pickup)

private struct HF04StartHubPickupBar: View {
    var onPrimary: () -> Void = {}
    var body: some View {
        HFSheetFooter {
            SlidingButtonView(label: "Swipe to start hub pickup", onSlideComplete: onPrimary)
        }
    }
}

#Preview("HF 04 — Trip started") {
    HFScreen04()
}
