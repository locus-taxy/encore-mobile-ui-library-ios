import SwiftUI

// Screen 03 — Trip detail (pre-start) with the "View details" bottom sheet open. Behind a dimming
// backdrop sits the full trip-detail page (eyebrow + window + stop count + pickup/delivery tags +
// Map / View details, a stop card, and the swipe-to-start action). The sheet keeps a close (X) in
// its title bar and shows the trip meta as a 2-column grid.
struct HFScreen03: View {
    var onPrimary: () -> Void = {}          // the main forward action
    var onSecondary: (Int) -> Void = { _ in } // drill-in taps (cards), indexed 0,1,…
    var onClose: () -> Void = {}            // X / back

    var body: some View {
        ZStack(alignment: .bottom) {
            HF03Base(onPrimary: onPrimary, onSecondary: onSecondary, onClose: onClose)

            Color.black.opacity(0.5)
                .ignoresSafeArea()

            HF03DetailsSheet(onClose: onClose)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HFColor.surface.ignoresSafeArea())
    }
}

// MARK: - Trip-detail page (behind the sheet)

private struct HF03Base: View {
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}
    var body: some View {
        VStack(spacing: 0) {
            HF03AppBar(title: "Trip", onClose: onClose)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HF03Summary()

                    HFSectionHeader(text: "Stops (1)")
                    Button { onSecondary(0) } label: {
                        HF03StopCard()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.spacing16)
                    .padding(.bottom, Spacing.spacing24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(HFColor.screen)

            HF03StartTripBar(onPrimary: onPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct HF03AppBar: View {
    let title: String
    var onClose: () -> Void = {}
    var body: some View {
        HFTitleBar(title: title, leading: .back, onBack: onClose)
    }
}

// MARK: - Full summary header (eyebrow + window + count + tags + actions)

private struct HF03Summary: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            HF03Eyebrow(text: "TRIP 1")
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
                HF03TintButton(label: "Map", icon: "LLocationMap")
                HF03TintButton(label: "View details", icon: nil)
            }
        }
        .padding(Spacing.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.surface)
    }
}

private struct HF03StopCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            HF03Eyebrow(text: "STOP 1")
            HStack(alignment: .bottom, spacing: Spacing.spacing4) {
                Text("Locus - Logistics Optimization & Decision-making Platform")
                    .typography(Typography.h6)
                    .foregroundColor(HFColor.textPrimary)
                EncoreIcon(iconName: "LVerified", size: 16)
                    .foregroundColor(HFColor.success)
                    .padding(.bottom, Spacing.spacing2)
            }
            Text("08:30 - 10:00 · 2 tasks")
                .typography(Typography.body2)
                .foregroundColor(HFColor.textSecondary)
            HF03CustomerPill()
                .padding(.top, Spacing.spacing2)
        }
        .padding(Spacing.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(HFColor.divider, lineWidth: 0.5))
    }
}

private struct HF03StartTripBar: View {
    var onPrimary: () -> Void = {}
    var body: some View {
        HFSheetFooter {
            SlidingButtonView(label: "Swipe to start trip 1", onSlideComplete: onPrimary)
        }
    }
}

// MARK: - "View details" bottom sheet

private struct HF03DetailsSheet: View {
    var onClose: () -> Void = {}
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("View details")
                    .typography(Typography.label0)
                    .foregroundColor(HFColor.textPrimary)
                Spacer()
                Button(action: onClose) {
                    EncoreIcon(iconName: "LCross", size: 24)
                        .foregroundColor(HFColor.textSecondary)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, Spacing.spacing16)
            .padding(.trailing, Spacing.spacing4)
            .padding(.top, Spacing.spacing4)

            Divider().overlay(HFColor.divider)

            HF03DetailGrid()
                .padding(Spacing.spacing16)
        }
        .background(
            HFColor.surface
                .clipShape(HF03TopRoundedRect(radius: 16))
        )
    }
}

private struct HF03DetailGrid: View {
    var body: some View {
        VStack(spacing: Spacing.spacing16) {
            HStack(alignment: .top, spacing: Spacing.spacing16) {
                HF03DetailItem(label: "Lunch break", value: "12:00-12:45")
                HF03DetailItem(label: "Helper", value: "Suresh")
            }
            HStack(alignment: .top, spacing: Spacing.spacing16) {
                HF03DetailItem(label: "Vehicle", value: "KA-01-AB-1234\n(LCV Tata Ace)")
                HF03DetailItem(label: "Fuel allowance", value: "₹600")
            }
        }
    }
}

private struct HF03DetailItem: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing2) {
            Text(label)
                .typography(Typography.body2)
                .foregroundColor(HFColor.textSecondary)
            Text(value)
                .typography(Typography.label1)
                .foregroundColor(HFColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Shared bits (screen 03)

private struct HF03TintButton: View {
    let label: String
    let icon: String?
    var body: some View {
        HStack(spacing: Spacing.spacing8) {
            if let icon {
                EncoreIcon(iconName: icon, size: 18)
                    .foregroundColor(HFColor.primary)
            }
            Text(label)
                .typography(Typography.Button.small)
                .foregroundColor(HFColor.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(HFColor.primary.opacity(0.08))
        .clipShape(Capsule())
    }
}

private struct HF03CustomerPill: View {
    var body: some View {
        HStack(spacing: Spacing.spacing4) {
            EncoreIcon(iconName: "LPerson", size: 14)
                .foregroundColor(HFColor.primary)
            Text("Customer")
                .typography(Typography.Chip.labelSmall)
                .foregroundColor(HFColor.primary)
        }
        .padding(.horizontal, Spacing.spacing8)
        .padding(.vertical, Spacing.spacing4)
        .background(HFColor.primary.opacity(0.08))
        .clipShape(Capsule())
    }
}

private struct HF03Eyebrow: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(text)
                .typography(Typography.overline2)
                .foregroundColor(HFColor.textSecondary)
            HF03HLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [1.5, 2]))
                .foregroundColor(HFColor.divider)
                .frame(height: 1)
        }
        .fixedSize()
    }
}

private struct HF03HLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        return p
    }
}

private struct HF03TopRoundedRect: Shape {
    var radius: CGFloat = 16
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.maxY))
        p.addLine(to: CGPoint(x: 0, y: radius))
        p.addQuadCurve(to: CGPoint(x: radius, y: 0), control: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX - radius, y: 0))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: radius), control: CGPoint(x: rect.maxX, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview("HF 03 — Trip (view details)") {
    HFScreen03()
}
