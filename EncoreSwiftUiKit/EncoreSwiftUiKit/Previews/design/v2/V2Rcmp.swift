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


/// Final design (agreed with Himadri). Opens on every Mark failed tap; no remembered state.
///   Sheet 1 "Mark order as failed?"  Call support → dialer, then sheet 2 on return
///                                    Mark the order as failed → failure checklist
///   Sheet 2 "Spoke to support?"      Call support again · Continue delivery · Mark the order as failed
/// The app can't see the call, so sheet 2 shows on return whether or not it connected.
enum V2RcmpPhase: Equatable { case prompt, returned }

/// Where the rider started failing from. Same two sheets, copy follows the action they tapped.
enum V2RcmpContext: Equatable {
    case task       // Delivery task page → Mark failed
    case scan       // Proposal 1: HU ⋮ → Raise an exception
    case scanOrder  // Proposal 2: after the HU exception checklist, confirm failing the order
}

/// What support needs to find the order.
struct V2RcmpBrief: Equatable {
    let orderRef: String
    let customer: String
}

struct V2RcmpNudgeSheet: View {
    var phase: V2RcmpPhase = .prompt
    var context: V2RcmpContext = .task
    let brief: V2RcmpBrief?
    var onClose: () -> Void = {}
    var onCall: () -> Void = {}
    var onMarkFailed: () -> Void = {}
    var onContinue: () -> Void = {}

    private var failLabel: String { context == .scan ? "Raise an exception" : "Mark the order as failed" }

    var body: some View {
        switch (phase, context) {
        case (.prompt, .task), (.prompt, .scanOrder):
            sheet(title: "Mark order as failed?",
                  description: "Contact support before marking the order as failed") {
                V2Button(label: "Call support", action: onCall)
                V2Button(label: failLabel, role: .text, action: onMarkFailed)
            }
        case (.prompt, .scan):
            sheet(title: "Raise an exception?",
                  description: "An HU exception fails the order. Contact support before raising it") {
                V2Button(label: "Call support", action: onCall)
                V2Button(label: failLabel, role: .text, action: onMarkFailed)
            }
        case (.returned, _):
            sheet(title: "Spoke to support?",
                  description: returnedDescription) {
                V2Button(label: "Call support again", role: .outlined, action: onCall)
                V2Button(label: context == .task ? "Continue delivery" : "Continue scanning", action: onContinue)
                V2Button(label: failLabel, role: .text, action: onMarkFailed)
            }
        }
    }

    private var returnedDescription: String {
        switch context {
        case .task:      return "Continue the delivery, or mark it failed if the issue stands."
        case .scan:      return "Continue scanning, or raise the exception if the issue stands."
        case .scanOrder: return "Continue scanning, or mark the order failed if the issue stands."
        }
    }

    private func sheet<Actions: View>(title: String, description: String,
                                      @ViewBuilder actions: () -> Actions) -> some View {
        VStack(spacing: 0) {
            HFSheetTitle(title: title, onClose: onClose)
            HFSeam()
            VStack(alignment: .leading, spacing: Spacing.spacing12) {
                Text(description)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.spacing16)
            .padding(.vertical, Spacing.spacing12)
            HFSheetFooter(caption: nil) {
                VStack(spacing: Spacing.spacing8) { actions() }
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
    var phase: V2RcmpPhase = .prompt
    var context: V2RcmpContext = .task
}
