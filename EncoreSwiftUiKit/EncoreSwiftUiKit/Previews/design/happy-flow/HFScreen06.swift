import SwiftUI

// Screen 06 — Trip detail (In transit) with the end-trip action blocked. Same in-transit header and
// stop card as screen 04, but the bottom shows a disabled "Swipe to end trip 1" control with a
// helper line explaining the remaining stops must be visited first.
struct HFScreen06: View {
    var onPrimary: () -> Void = {}          // the main forward action
    var onSecondary: (Int) -> Void = { _ in } // drill-in taps (cards), indexed 0,1,…
    var onClose: () -> Void = {}            // X / back

    var body: some View {
        VStack(spacing: 0) {
            HF06AppBar(title: "Trip", onClose: onClose)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HF06Summary()

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

            HF06EndTripBar(onPrimary: onPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HFColor.surface.ignoresSafeArea())
    }
}

// MARK: - App bar

private struct HF06AppBar: View {
    let title: String
    var onClose: () -> Void = {}
    var body: some View {
        HFTitleBar(title: title, leading: .back, onBack: onClose)
    }
}

// MARK: - Summary header (in transit)

private struct HF06Summary: View {
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
            HF06ProgressBar(fraction: 0)
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

private struct HF06ProgressBar: View {
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

// MARK: - Bottom action (disabled) + helper

// Bespoke footer (not HFSheetFooter): a disabled swipe + a centered helper line with its own
// vertical rhythm (top12 / helper top8 bottom12). Left un-refactored — two stacked elements with
// distinct padding don't fit the single-content HFSheetFooter.
private struct HF06EndTripBar: View {
    var onPrimary: () -> Void = {}
    var body: some View {
        HFSheetFooter(caption: "Visit N remaining stops before ending trip") {
            SlidingButtonView(label: "Swipe to end trip 1", onSlideComplete: {})
                .disabled(true)
                .contentShape(Rectangle())
                .onTapGesture { onPrimary() }   // test shortcut past the disabled swipe
        }
    }
}

#Preview("HF 06 — Trip (end blocked)") {
    HFScreen06()
}
