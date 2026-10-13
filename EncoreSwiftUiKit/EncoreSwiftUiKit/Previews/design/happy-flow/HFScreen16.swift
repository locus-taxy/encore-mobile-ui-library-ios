import SwiftUI

// Screen 16 — Delivery Task (ready to start). App bar: back + close. White detail head (Order ID,
// recipient, address, Call action, info banner "Call on arrival, don't ring the doorbell"), grey
// "Logistic units (2)" list, and a "Swipe to start task" sliding button pinned to the bottom.
//
// This file also hosts the shared Delivery-Task building blocks (HFDelivery*) reused by screen 17.
struct HFScreen16: View {
    // Flow-coordinator interaction contract. onSecondary is unused here (no task/order cards;
    // logistic-unit cards are static in V1).
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}
    var body: some View {
        VStack(spacing: 0) {
            HFDeliveryAppBar(title: "Delivery Task", onClose: onClose)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HFDeliveryHeader()
                    HFDeliveryUnits()
                }
            }
            .background(HFColor.screen)

            HFSheetFooter {
                SlidingButtonView(label: "Swipe to start task", onSlideComplete: { onPrimary() })
            }
        }
        .background(HFColor.surface.ignoresSafeArea())
    }
}

// MARK: - App bar (back + title + close)

struct HFDeliveryAppBar: View {
    let title: String
    var onClose: () -> Void = {}
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.spacing8) {
                EncoreIcon(iconName: "LChevronLeft", size: 24)
                    .foregroundColor(HFColor.textPrimary)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .onTapGesture { onClose() }
                Text(title)
                    .typography(Typography.h6)
                    .foregroundColor(HFColor.textPrimary)
                Spacer()
                EncoreIcon(iconName: "LCross", size: 24)
                    .foregroundColor(HFColor.textPrimary)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .onTapGesture { onClose() }
            }
            .padding(.horizontal, Spacing.spacing8)
            Divider().overlay(HFColor.divider)
        }
        .background(HFColor.surface)
    }
}

// MARK: - White detail head (identifier + optional status, recipient, address, Call, banner)

struct HFDeliveryHeader: View {
    var orderId: String = "Order ID 1"
    var status: String? = nil
    var statusFill: Color = HFColor.primary
    var recipient: String = "Priya Sharma"
    var address: String = "Mayur Greens, 4th Floor, 87-148, Koramangala, Bengaluru, 560034"
    var showFacingIssues: Bool = false
    var body: some View {
        // Figma header rhythm: eyebrow→recipient 8, recipient→address 2, group→divider/Call 12;
        // container top/px 16, bottom 12. ORDER ID keeps its dotted underline (page-level
        // copyable entity, like the STOP header — Figma-confirmed).
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: Spacing.spacing8) {
                Text(orderId.uppercased())
                    .typography(Typography.overline2)
                    .foregroundColor(HFColor.textSecondary)
                    .overlay(alignment: .bottom) { HFDashUnderline().offset(y: 3) }
                if let status {
                    HFStatusChip(text: status, fill: statusFill)
                }
            }
            .padding(.bottom, Spacing.spacing8)
            Text(recipient)
                .typography(Typography.h6)                 // recipient name → h6 (SemiBold 16)
                .foregroundColor(HFColor.textPrimary)
                .padding(.bottom, Spacing.spacing2)
            Text(address)
                .typography(Typography.body2)              // address → body2 (12)
                .foregroundColor(HFColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, Spacing.spacing12)

            Divider().overlay(HFColor.divider)
                .padding(.bottom, Spacing.spacing12)

            HStack(spacing: Spacing.spacing8) {
                HFDeliveryActionPill(icon: "LCall", label: "Call")
                if showFacingIssues {
                    HFDeliveryActionPill(label: "Facing issues?")
                }
            }

            HFDeliveryInfoBanner(text: "Call on arrival, don't ring the doorbell.")
                .padding(.top, Spacing.spacing12)
        }
        .padding(.horizontal, Spacing.spacing16)
        .padding(.top, Spacing.spacing16)
        .padding(.bottom, Spacing.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.surface)
    }
}

// MARK: - Grey logistic-unit list

struct HFDeliveryUnits: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HFSectionHeader(text: "Logistic units (2)")
            VStack(spacing: Spacing.spacing12) {
                HFDeliveryLUCard(id: "LU ID 1", count: "1 item", tag: "Big & bulky")
                HFDeliveryLUCard(id: "LU ID 2", count: "4 items", tag: nil)
            }
            .padding(.horizontal, Spacing.spacing16)
            .padding(.bottom, Spacing.spacing24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.screen)
    }
}

// MARK: - Shared bits

// Dotted underline drawn beneath the ORDER ID identifier (Figma marks it as an expandable field).
struct HFDashUnderline: View {
    var body: some View {
        GeometryReader { g in
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0.5))
                p.addLine(to: CGPoint(x: g.size.width, y: 0.5))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [1, 2]))
            .foregroundColor(HFColor.textDisabled)
        }
        .frame(height: 1)
    }
}

struct HFDeliveryActionPill: View {
    var icon: String? = nil
    let label: String
    var body: some View {
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
        .background(HFColor.primary.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(HFColor.pillBorder, lineWidth: 0.5))
    }
}

struct HFDeliveryInfoBanner: View {
    let text: String
    var body: some View {
        HStack(alignment: .center, spacing: Spacing.spacing8) {
            EncoreIcon(iconName: "LInformation", size: 20)
                .foregroundColor(HFColor.infoText)
            Text(text)
                .typography(Typography.body1)
                .foregroundColor(HFColor.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.spacing12)
        .padding(.vertical, Spacing.spacing8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.infoBg)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        // 0.5px #BDE2FF hairline border (Figma info-banner stroke).
        .overlay(RoundedRectangle(cornerRadius: 4)
            .stroke(Color(.sRGB, red: 189/255, green: 226/255, blue: 255/255, opacity: 1), lineWidth: 0.5))
    }
}

struct HFDeliveryLUCard: View {
    let id: String
    let count: String
    var tag: String?
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            Text(id)
                .typography(Typography.label1)     // "LU ID N" → label1 (14)
                .foregroundColor(HFColor.textPrimary)
            Text(count)
                .typography(Typography.body2)       // count → body2 (12)
                .foregroundColor(HFColor.textSecondary)
            if let tag {
                HFPillChip(text: tag, bg: HFColor.screen, fg: HFColor.textSecondary, dot: false)
            }
        }
        .padding(Spacing.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(HFColor.divider, lineWidth: 0.5))
    }
}
