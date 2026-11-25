import SwiftUI

// MARK: - DP-9877 · Call RCMP on task failure
//
// RCMP (support / supervisor / warehouse manager — whoever the client configures) resolves a blocked
// delivery with the customer OUTSIDE the app and tells the rider what to do: deliver, or mark failed.
// The app never records RCMP's decision; it only puts the call in the rider's path. Four shapes are
// compared as variants (see V2Variant): 1 banner, 2 nav icon, 3 menu sheet, 4 step sheet.

/// Who the rider is calling. One contact in the prototype; the client config could list several.
enum V2Rcmp {
    static let contactName = "RCMP · Support desk"
    static let contactPhone = "+44 20 7946 0123"
}

// MARK: Option 1 — banner on the failure checklist

struct V2RcmpBanner: View {
    var onCall: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.spacing12) {
            Text("Call RCMP before marking this task failed")
                .v2Text(V2Font.body1)
                .foregroundColor(HFColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            V2Button(label: "Call", size: .compact, leadingIcon: "LCall", hug: true, action: onCall)
        }
        .padding(.leading, Spacing.spacing16)
        .padding(.trailing, Spacing.spacing12)
        .padding(.vertical, Spacing.spacing4)
        .background(HFColor.infoBg)
    }
}

// MARK: Option 3 — "Facing issues?" menu (same shape as the stop-level frame 70 sheet)

struct V2RcmpMenuSheet: View {
    var onClose: () -> Void = {}
    var onCall: () -> Void = {}
    var onFail: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HFSheetTitle(title: "Facing issues?", onClose: onClose)
            HFSeam()
            V2RcmpRow(title: "Call RCMP",
                      subtitle: "Talk to support about missing, damaged or refused items",
                      action: onCall)
            HFSeam()
            V2RcmpRow(title: "Mark as failed",
                      subtitle: "Report the issue and fail this task",
                      action: onFail)
            HFSheetBottomInset()
        }
        .background(HFColor.surface)
    }
}

// MARK: Option 4 — call-RCMP step between "Mark failed" and the checklist

/// What RCMP needs to find the order on any call (in-app or speed dial).
struct V2RcmpBrief: Equatable {
    let orderRef: String
    let customer: String
}

/// Figma 14852:46617 ("Dialog Elements" pattern). Opens on every Mark failed tap. There is no remembered
/// state: the app never sees the call, so each time the rider gets the same two ways forward.
///   Call RCMP                 → hands off to the dialer; the sheet stays open for when the rider returns.
///   Mark the order as failed  → straight to the failure checklist.
struct V2RcmpNudgeSheet: View {
    let brief: V2RcmpBrief?
    var onClose: () -> Void = {}
    var onCall: () -> Void = {}
    var onMarkFailed: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HFSheetTitle(title: "Mark failed", onClose: onClose)
            HFSeam()
            VStack(alignment: .leading, spacing: Spacing.spacing12) {
                Text("Contact support team before marking the order as failed")
                    .v2Text(V2Font.body1)
                    .foregroundColor(HFColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let brief {
                    HStack(alignment: .top, spacing: Spacing.spacing16) {
                        gridField("Order ID", brief.orderRef)
                        gridField("Customer", brief.customer)
                    }
                }
            }
            .padding(.horizontal, Spacing.spacing16)
            .padding(.vertical, Spacing.spacing12)
            .frame(maxWidth: .infinity, alignment: .leading)

            HFSheetFooter(caption: nil) {
                VStack(spacing: Spacing.spacing4) {
                    V2Button(label: "Call RCMP", action: onCall)
                    V2Button(label: "Mark the order as failed", role: .text, action: onMarkFailed)
                }
            }
        }
        .background(HFColor.surface)
    }

    private func gridField(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.spacing2) {
            Text(label).v2Label(V2Font.label2).foregroundColor(HFColor.textSecondary)
            Text(value).v2Label(V2Font.label2).foregroundColor(HFColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Frame-70 row: label1 title over body1 subtitle, chevron in a 48 target.
struct V2RcmpRow: View {
    let title: String
    let subtitle: String
    var icon: String? = nil
    var danger: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: Spacing.spacing16) {
                if let icon {
                    EncoreIcon(iconName: icon, size: V2Icon.banner)
                        .foregroundColor(HFColor.infoText)
                }
                VStack(alignment: .leading, spacing: Spacing.spacing2) {
                    Text(title)
                        .v2Label(V2Font.label1)
                        .foregroundColor(danger ? Color.encore("Error/Main") : HFColor.textPrimary)
                    Text(subtitle)
                        .v2Text(V2Font.body1)
                        .foregroundColor(HFColor.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                EncoreIcon(iconName: "LChevronRight", size: V2Icon.chevron)
                    .foregroundColor(V2Token.actionActive)
                    .frame(width: V2Metrics.touchTarget, height: V2Metrics.touchTarget)
            }
            .padding(.leading, Spacing.spacing16)
            .padding(.trailing, Spacing.spacing4)
            .padding(.vertical, Spacing.spacing8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: Flow state

struct V2RcmpTarget: Equatable { let stop: Int; let task: Int }

struct V2RcmpNudge: Equatable {
    let target: V2RcmpTarget
}
