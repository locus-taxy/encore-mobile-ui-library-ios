import SwiftUI

// Screen 27 — Trip detail (trip complete). White app bar (back + title), white trip summary
// (Trip 1 + Completed, window/distance, progress, pickup/delivery tags, Map / View details),
// a grey list with the completed stop card, and a pinned "Swipe to end trip" action.
struct HFScreen27: View {
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HF27AppBar(title: "Trip", onClose: onClose)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HF27TripSummary()

                    HFSectionHeader(text: "Stops (1)")
                    HFStopCard(statusText: "Completed", showNavigate: true)
                        .padding(.horizontal, Spacing.spacing16)
                        .padding(.bottom, Spacing.spacing24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(HFColor.screen)

            HF27EndTripBar(onEndTrip: onPrimary)
        }
        .background(HFColor.surface.ignoresSafeArea())
    }
}

// MARK: - App bar

private struct HF27AppBar: View {
    let title: String
    var onClose: () -> Void = {}
    var body: some View {
        HFTitleBar(title: title, leading: .back, onBack: onClose)
    }
}

// MARK: - Trip summary header

private struct HF27TripSummary: View {
    @Environment(\.hfViewDetails) private var viewDetails
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            HStack(spacing: Spacing.spacing8) {
                HFCopyableEyebrow(text: "TRIP 1", entity: "Trip", id: HFEntityID.trip)
                HFStatusChip(text: "Completed", fill: HFColor.success)
            }
            Text("08:30-11:00 · ~17 kms")
                .typography(Typography.h5)
                .foregroundColor(HFColor.textPrimary)
            HStack(spacing: Spacing.spacing8) {
                EncoreIcon(iconName: "LCheckCircle", size: 16)
                    .foregroundColor(HFColor.success)
                Text("1 stop completed")
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
        .background(HFColor.surface)
    }
}

// MARK: - Bottom action

private struct HF27EndTripBar: View {
    var onEndTrip: () -> Void = {}
    var body: some View {
        HFSheetFooter {
            SlidingButtonView(label: "Swipe to end trip", onSlideComplete: onEndTrip)
        }
    }
}

#Preview("HF 27 — Trip") {
    HFScreen27()
}
