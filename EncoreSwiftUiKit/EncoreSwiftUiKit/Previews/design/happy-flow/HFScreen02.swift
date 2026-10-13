import SwiftUI

// Screen 02 — Trip detail (pre-start). White app bar (back + "Trip"), a white trip summary
// (eyebrow TRIP 1 + time window + stop count + Pickup/Delivery tags + divider + Map / View details),
// a grey stops list with one stop card, and a pinned "Swipe to start trip 1" action.
struct HFScreen02: View {
    var onPrimary: () -> Void = {}          // the main forward action
    var onSecondary: (Int) -> Void = { _ in } // drill-in taps (cards), indexed 0,1,…
    var onClose: () -> Void = {}            // X / back

    var body: some View {
        VStack(spacing: 0) {
            HF02AppBar(title: "Trip", onClose: onClose)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HF02Summary()

                    HFSectionHeader(text: "Stops (1)")
                    Button { onSecondary(0) } label: {
                        HFStopCard()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.spacing16)
                    .padding(.bottom, Spacing.spacing24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(HFColor.screen)

            HF02StartTripBar(onPrimary: onPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HFColor.surface.ignoresSafeArea())
    }
}

// MARK: - App bar

private struct HF02AppBar: View {
    let title: String
    var onClose: () -> Void = {}
    var body: some View {
        HFTitleBar(title: title, leading: .back, onBack: onClose)
    }
}

// MARK: - Full summary header (eyebrow + window + count + tags + actions)

private struct HF02Summary: View {
    @Environment(\.hfViewDetails) private var viewDetails
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            HFCopyableEyebrow(text: "TRIP 1", entity: "Trip", id: HFEntityID.trip)
            Text("08:30-11:00 · ~17 kms")
                .typography(Typography.h5)
                .foregroundColor(HFColor.textPrimary)
            Text("1 stop")
                .typography(Typography.body2)
                .foregroundColor(HFColor.textSecondary)
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

// MARK: - Bottom action

private struct HF02StartTripBar: View {
    var onPrimary: () -> Void = {}
    var body: some View {
        HFSheetFooter {
            SlidingButtonView(label: "Swipe to start trip 1", onSlideComplete: onPrimary)
        }
    }
}

#Preview("HF 02 — Trip (pre-start)") {
    HFScreen02()
}
