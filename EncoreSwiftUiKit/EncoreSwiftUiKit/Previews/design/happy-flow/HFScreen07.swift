import SwiftUI

// Screen 07 — Customer Stop (pre-start): full-page detail. STOP 1 (no status chip yet),
// verified customer, single "Navigate" action pill, Tasks(2), swipe-to-start-work.
//
// This file also hosts the shared Customer-Stop building blocks (HFStop*) reused by
// screens 09/11/12, which differ only in status chip, action pills, app-bar menu and
// the bottom bar.
struct HFScreen07: View {
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}
    /// Gate the swipe CTA (e.g. when the trip hasn't started yet).
    var ctaEnabled: Bool = true
    /// Helper line shown under a disabled CTA explaining why it's blocked.
    var ctaCaption: String? = nil
    var body: some View {
        VStack(spacing: 0) {
            HFStopAppBar(onClose: onClose)
            ScrollView {
                VStack(spacing: 0) {
                    HFStopHeader(showFacingIssues: false)
                    HFStopTasks(onSelect: onSecondary)
                }
            }
            .background(HFColor.screen)

            HFSheetFooter(caption: ctaCaption) {
                SlidingButtonView(label: "Swipe to start work", onSlideComplete: { onPrimary() })
                    .disabled(!ctaEnabled)
            }
        }
        .background(HFColor.surface.ignoresSafeArea())
    }
}

// MARK: - App bar (title + optional kebab + close)

struct HFStopAppBar: View {
    var showMenu: Bool = false
    var onClose: () -> Void = {}
    var body: some View {
        // Shared title bar: no leading control; trailing = (kebab +) plain X close (LCross).
        HFTitleBar(title: "Customer Stop",
                   trailing: showMenu ? .menuClose : .close,
                   onClose: onClose)
    }
}

// MARK: - Stop header (white)

struct HFStopHeader: View {
    var statusText: String? = nil
    var statusFill: Color = HFColor.primary
    var showFacingIssues: Bool = true
    @Environment(\.hfNavigate) private var navigate
    var body: some View {
        // Figma header rhythm: eyebrow→title 8, title→address 2, address→time 8,
        // time→divider 12, divider→pills 12; container top/px 16, bottom 12.
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.spacing8) {
                HFCopyableEyebrow(text: "STOP 1", entity: "Stop", id: HFEntityID.stop)
                if let statusText {
                    HFStatusChip(text: statusText, fill: statusFill)
                }
                Spacer()
            }
            .padding(.bottom, Spacing.spacing8)

            HFStopTitle()
                .padding(.bottom, Spacing.spacing2)

            Text("Mayur Greens, 4th Floor, 87-148, Koramangala, Bengaluru, 560034")
                .typography(Typography.body2)
                .foregroundColor(HFColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, Spacing.spacing8)

            Text("08:30 - 10:00")
                .typography(Typography.body2)
                .foregroundColor(HFColor.textSecondary)
                .padding(.bottom, Spacing.spacing12)

            Divider().overlay(HFColor.divider)
                .padding(.bottom, Spacing.spacing12)

            HStack(spacing: Spacing.spacing12) {
                HFStopActionPill(label: "Navigate", icon: "LNavigationOutlined", action: navigate)
                if showFacingIssues {
                    HFStopActionPill(label: "Facing issues?")
                }
                Spacer()
            }
        }
        .padding(.horizontal, Spacing.spacing16)
        .padding(.top, Spacing.spacing16)
        .padding(.bottom, Spacing.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.surface)
    }
}

/// Company/customer name with a trailing green Verified seal (Material `verified`, per Figma).
struct HFStopTitle: View {
    var body: some View {
        HFVerifiedTitle(title: "Locus - Logistics Optimization & Decision-making Platform")
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Tinted-blue action pill (Navigate / Facing issues?).
struct HFStopActionPill: View {
    let label: String
    var icon: String? = nil
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.spacing4) {
                if let icon {
                    EncoreIcon(iconName: icon, size: 14)
                        .foregroundColor(HFColor.primary)
                }
                Text(label)
                    .typography(Typography.Button.small)
                    .foregroundColor(HFColor.primary)
            }
            .padding(.horizontal, Spacing.spacing12)
            .padding(.vertical, Spacing.spacing6)
            .background(Capsule().fill(HFColor.primary.opacity(0.08)))
            .overlay(Capsule().stroke(HFColor.pillBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

/// Small-caps eyebrow WITHOUT the dotted underline — used for card-level identifiers
/// (ORDER ID / LU ID) which, unlike the copyable STOP header entity, aren't tap-to-copy in Figma.
struct HFPlainEyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .typography(Typography.overline2)
            .foregroundColor(HFColor.textSecondary)
    }
}

/// Small-caps eyebrow (STOP header only) with the dotted "tap for info" underline from Figma.
struct HFDottedEyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .typography(Typography.overline2)
            .foregroundColor(HFColor.textSecondary)
            .overlay(alignment: .bottom) {
                GeometryReader { g in
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: 0.5))
                        p.addLine(to: CGPoint(x: g.size.width, y: 0.5))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [1, 2]))
                    .foregroundColor(HFColor.textDisabled)
                }
                .frame(height: 1)
                .offset(y: 3)
            }
    }
}

// MARK: - Tasks (grey)

struct HFStopTasks: View {
    var onSelect: (Int) -> Void = { _ in }
    // Optional per-order status chips (In progress / Completed states). Default: no chip.
    var order1Status: String? = nil
    var order1StatusFill: Color = HFColor.success
    var order2Status: String? = nil
    var order2StatusFill: Color = HFColor.success
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HFSectionHeader(text: "Tasks (2)")
            VStack(spacing: Spacing.spacing8) {
                HFStopOrderCard(eyebrow: "Order ID 1", quantity: "2 LUs",
                                type: "Deliver", attribute: "Big & bulky",
                                customer: "Priya Sharma", address: "23, Floor 4, Building 2",
                                statusText: order1Status, statusFill: order1StatusFill,
                                action: { onSelect(0) })
                HFStopOrderCard(eyebrow: "Order ID 2", quantity: "1 LU",
                                type: "Pickup", attribute: "Fragile",
                                customer: "Rohit Mehta", address: "23, Floor 4, Building 2",
                                statusText: order2Status, statusFill: order2StatusFill,
                                action: { onSelect(1) })
            }
            .padding(.horizontal, Spacing.spacing16)
            .padding(.bottom, Spacing.spacing24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.screen)
    }
}

/// Clickable order card. Figma wraps each order in a faint-blue (#266EF1 @4%) r16 container that
/// holds TWO sibling r12 cards: the white order card (0.5px divider border) and the light-blue
/// (#266EF1 @8%) customer row, stacked with an 8pt gap. Order-card content is padded 12.
struct HFStopOrderCard: View {
    let eyebrow: String
    let quantity: String
    let type: String
    let attribute: String
    let customer: String
    let address: String
    var statusText: String? = nil
    var statusFill: Color = HFColor.success
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.spacing8) {
                // Sibling 1 — white order card
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: Spacing.spacing8) {
                        HFPlainEyebrow(text: eyebrow)   // ORDER ID: no dotted underline
                        if let statusText {
                            HFStatusChip(text: statusText, fill: statusFill)
                        }
                    }
                    .padding(.bottom, Spacing.spacing4)   // eyebrow→quantity 4
                    Text(quantity)
                        .typography(Typography.label1)     // "N LUs" → label1 (14)
                        .foregroundColor(HFColor.textPrimary)
                        .padding(.bottom, Spacing.spacing16)  // quantity→tags 16
                    HStack(spacing: Spacing.spacing4) {   // tag gap 4
                        HFPillChip(text: type, glyph: type == "Pickup" ? .pickup : .deliver)
                        HFPillChip(text: attribute, bg: HFColor.screen, fg: HFColor.textSecondary, dot: false)
                    }
                }
                .padding(Spacing.spacing12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(HFColor.divider, lineWidth: 0.5))

                // Sibling 2 — light-blue customer row
                HFStopCustomerRow(name: customer, address: address)
            }
            .padding(Spacing.spacing8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(HFColor.primary.opacity(0.04)))
        }
        .buttonStyle(.plain)
    }
}

/// Nested customer row: light-blue tint, name/address + circular call button.
struct HFStopCustomerRow: View {
    let name: String
    let address: String
    var body: some View {
        HStack(spacing: Spacing.spacing12) {
            VStack(alignment: .leading, spacing: Spacing.spacing2) {
                Text(name)
                    .typography(Typography.label2)   // stop-card contact name → label2 (12)
                    .foregroundColor(HFColor.textPrimary)
                Text(address)
                    .typography(Typography.body2)
                    .foregroundColor(HFColor.textSecondary)
            }
            Spacer()
            ZStack {
                Circle().fill(HFColor.surface)
                EncoreIcon(iconName: "LCall", size: 14)
                    .foregroundColor(HFColor.primary)
            }
            .frame(width: 32, height: 32)
        }
        .padding(.horizontal, Spacing.spacing12)
        .padding(.vertical, Spacing.spacing8)
        .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.primary.opacity(0.08)))
    }
}
