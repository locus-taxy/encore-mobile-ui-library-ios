import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Layout constants read from the device

enum V2Layout {
    /// Height of the status-bar strip the stop sheet leaves uncovered so the backdrop shows through.
    /// Measured from the key window; the 44pt fallback is the pre-notch inset.
    static var statusStrip: CGFloat {
        #if canImport(UIKit)
        let inset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .safeAreaInsets.top
        return inset.map { $0 > 0 ? $0 : 44 } ?? 44
        #else
        return 44
        #endif
    }


    /// Height the app actually gets to draw in: the window minus the band the system reserves at the
    /// top. Derived from the window rather than measured from the sheet layer — the layer's size
    /// depends on its content, so measuring it to size the content is circular and collapses.
    static var drawableHeight: CGFloat {
        #if canImport(UIKit)
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow }) else { return 800 }
        return window.bounds.height - window.safeAreaInsets.top
        #else
        return 800
        #endif
    }

    /// Bottom inset a scrolling list needs so its last row can clear the sticky footer instead of
    /// coming to rest underneath it.
    ///
    /// Footers are STACKED under the scroll view, never overlaid on it, so the list only needs the
    /// page's own 16 of breathing room at its end — the old 120 left a screen of dead grey under the
    /// last card. A list with a FAB floating over it adds the FAB's slot (48 target + 12 gap).
    static let footerClearance: CGFloat = 16
    static let fabClearance: CGFloat = 16 + 48 + 12

    /// Vertical space a visible toast occupies above the sticky footer: the 56pt pill plus its 16pt
    /// gap. Anything floating above the footer (a FAB) rides up by exactly this much while a toast is
    /// on screen, then settles back — Figma frame 32.
    /// Frame 32 measures the FAB's lift at 68 (660 → 592), resting 8 above the toast's top.
    static let toastSlot: CGFloat = 68
}

/// A full-bleed screen that reserves the status-bar strip at the top and paints it.
///
/// The whole V2 hierarchy is full-bleed so the stop sheet's backdrop can dim the strip (frames 76→77).
/// That means every *base* surface has to hand the strip back explicitly, which is what this does.
struct V2Surface<Content: View>: View {
    var strip: Color = HFColor.surface
    /// True while a bottom sheet covers this surface. The strip is the one band the sheet deliberately
    /// leaves uncovered (frames 76→77), and the page that owns those pixels is the one that can dim
    /// them — a backdrop inside the sheet layer cannot reach up there.
    var dimmed: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                strip
                if dimmed {
                    Color.encore("Backdrop/Fill").opacity(0.5)
                }
            }
            .frame(height: V2Layout.statusStrip)
            content
        }
    }
}

/// A FAB pinned above the sticky footer that gets out of the toast's way.
///
/// The toast rises from behind the footer and rests 16pt above it; without this the toast would land
/// on top of the FAB. Wrap the FAB in this and it translates up by one toast slot while a toast is
/// showing, then comes back down.
struct V2FabSlot<Content: View>: View {
    @Environment(\.hfToast) private var toastCenter
    @ViewBuilder var content: Content

    var body: some View {
        if let toastCenter {
            V2FabSlotBody(toast: toastCenter) { content }
        } else {
            content
        }
    }
}

private struct V2FabSlotBody<Content: View>: View {
    @ObservedObject var toast: HFToastCenter
    @ViewBuilder var content: Content

    private var lifted: Bool { toast.current != nil }

    var body: some View {
        content
            .offset(y: lifted ? -V2Layout.toastSlot : 0)
            .animation(V2Motion.standard, value: lifted)
    }
}

// MARK: - P0.3 Motion primitives
//
// The five transition laws live here and nowhere else. Surfaces never declare a duration, a curve or
// a transition inline — changing the feel of the app must stay a one-line edit in this file.
//
//   1. trip list → trip page          rises from the bottom, and leaves the same way
//   2. trip → stop                    bottom sheet over a dark backdrop (stop is a subset of trip)
//   3. stop → task                    dissolve inside the sheet's real estate
//   4. workflows (scan/checklist/maps) full pager, ✕ on the right
//   5. profile / tab switch           lateral push (parallel screens)
//
// Laws 1 and 2 are the same gesture at two depths: drilling into a subset pulls the subset UP over
// what you came from, and going back drops it. The trip page is the trip list's subset exactly as a
// stop is the trip's, so it travels the same way — which is why law 1 is no longer a dissolve.

enum V2Motion {
    /// Every surface swap and state advance uses this single curve.
    static let standard: Animation = .easeInOut(duration: 0.22)
    /// Sheets and covers travel further, so they get slightly longer.
    static let surface: Animation = .easeInOut(duration: 0.28)
    /// Reflow — something inside the page grows or shrinks (the medium banner, the network strip, a
    /// day section, a row leaving the Unread tab) and everything below follows it. The whole page
    /// moves, so it gets the longest, softest curve (Material's standard easing): it should glide in
    /// and settle, never jump. Same curve both ways.
    static let reflow: Animation = .timingCurve(0.4, 0, 0.2, 1, duration: 0.4)

    /// Law 1 & 3 — content cross-fades in place.
    static let dissolve: AnyTransition = .opacity
    /// Law 2 & 4 — arrives from the bottom edge.
    static let riseFromBottom: AnyTransition = .move(edge: .bottom)
    /// Law 5 — parallel screen slides in from the right.
    static let pushFromTrailing: AnyTransition = .move(edge: .trailing)

    /// Law 5, direction-aware: moving to a higher tab index enters from the right, lower from the left.
    static func lateral(forward: Bool) -> AnyTransition {
        .asymmetric(insertion: .move(edge: forward ? .trailing : .leading),
                    removal: .move(edge: forward ? .leading : .trailing))
    }

    /// Run a state change through the standard curve. Use this instead of stacking `.animation(…)`
    /// modifiers, which compound and cause jank.
    static func tx(_ body: () -> Void) { withAnimation(standard, body) }
    static func txSurface(_ body: () -> Void) { withAnimation(surface, body) }
}

// MARK: - Law 2: the stop sheet layer

/// A full-height bottom sheet over a dark backdrop. The sheet's top edge respects the safe area, so
/// the scrim shows only in the status-bar strip — which is exactly what frames 17 / 40 / 65 draw.
/// Drag-down and ✕ are equivalent: both abandon to the base with the entity's state preserved.
struct V2SheetLayer<Content: View>: View {
    let isPresented: Bool
    var onDismiss: () -> Void = {}
    @ViewBuilder var content: Content

    @State private var drag: CGFloat = 0
    /// The network alert's height while it shows: the sheet starts under it, not under the status bar.
    @Environment(\.v2NetworkInset) private var networkInset

    var body: some View {
        // Frames 17 / 19 / 40 / 73: the sheet covers EVERYTHING below the status bar, and the only
        // dimmed band is the status strip itself. The backdrop ignores the safe area so it can reach
        // up into that strip (this layer sits at the flow root, so no ancestor has consumed it); the
        // sheet takes the whole drawable height beneath it.
        ZStack(alignment: .bottom) {
            if isPresented {
                // `Backdrop/Fill` is opaque black — the DS token carries no scrim alpha.
                //
                // The scrim is drawn as a BACKGROUND that ignores the safe area, on a layout-sized
                // clear view. As a full-bleed child itself it grew this layer — and the root ZStack —
                // up into the status strip, and the ZStack re-centred everything in it: the trip page
                // underneath visibly jumped up ~16pt as the stop sheet rose.
                Color.clear
                    .background(Color.encore("Backdrop/Fill").opacity(0.5).ignoresSafeArea())
                    .contentShape(Rectangle())
                    .onTapGesture { dismiss() }
                    .transition(.opacity)

                content
                    .frame(maxWidth: .infinity)
                    .frame(height: V2Layout.drawableHeight - networkInset)
                    .background(HFColor.surface)
                    // A colour background bleeds into the safe area by default, which painted the
                    // status strip white over the backdrop. Clip the sheet to its own frame.
                    .clipped()
                    .offset(y: drag)
                    .transition(V2Motion.riseFromBottom)
                    // The drag lives on the sheet's BAR (`V2SheetGrab`), not on the whole sheet: as a
                    // `.gesture` here it claimed every vertical pan, so the list inside never scrolled.
                    .environment(\.v2SheetDrag, V2SheetDragHandlers(
                        changed: { h in if h > 0 { drag = h } },
                        ended: { h in
                            if h > 120 { dismiss() } else { withAnimation(V2Motion.standard) { drag = 0 } }
                        }))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private func dismiss() {
        drag = 0
        V2Motion.txSurface { onDismiss() }
    }
}

// MARK: - Law 4: the workflow cover

/// Scan / checklist / maps are *workflows*, not pages: they cover everything and close with a ✕ on the
/// right. Presented as a full pager rising from the bottom.
struct V2WorkflowCover<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var onClose: () -> Void = {}
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            V2WorkflowBar(title: title, subtitle: subtitle, onClose: onClose)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(HFColor.screen)
    }
}

/// Workflow title bar — title (+ optional context subtitle) and a trailing ✕.
/// Workflow cover bar — law 4: a workflow owns the screen, so it exits with ✕ and never a back
/// chevron. Same navbar as everywhere else; only the actions differ.
struct V2WorkflowBar: View {
    let title: String
    var subtitle: String? = nil
    var onClose: () -> Void = {}

    var body: some View {
        V2Navbar(title: title,
                 subtitle: subtitle,
                 actions: [V2NavAction(id: "close", icon: "LCross", action: onClose)])
    }
}

// MARK: - P0.4 Alert host

/// An alert *moves in onto the screen under the top nav and goes back* — distinct from a toast, which
/// rises from behind the sticky footer. Place this directly below the title bar; it clips so the
/// banner appears to slide out from underneath the nav.
struct V2AlertHost: View {
    let alert: V2Alert?

    var body: some View {
        ZStack(alignment: .top) {
            if let alert {
                HFBanner(role: .network,
                         title: alert.title,
                         icon: alert.icon,
                         fill: alert.fill)
                    .transition(.move(edge: .top))
            }
        }
        .clipped()
    }
}

struct V2Alert: Equatable {
    let title: String
    var icon: String = "LInfo"
    var fill: Color = V2Token.orange

    static func offline() -> V2Alert {
        V2Alert(title: "No internet connection", icon: "LWifiOff", fill: V2Token.orange)
    }

    static func == (l: V2Alert, r: V2Alert) -> Bool { l.title == r.title && l.icon == r.icon }
}

// MARK: - P0.5 Terminal ⇒ no actions

/// Secondary action row (Navigate, Call, Mark failed, Facing issues?, …).
///
/// It renders **nothing** when the entity is terminal — the affordances are removed, not disabled,
/// which is what frames 38 / 55 / 73 / 90 / 104 / 110 / 115 all show. Every surface routes its
/// secondary actions through here, so no screen can forget the rule.
struct V2ActionRow<Content: View>: View {
    let isTerminal: Bool
    @ViewBuilder var content: Content

    var body: some View {
        if !isTerminal {
            HStack(spacing: Spacing.spacing8) {
                content
            }
        }
    }
}

/// Primary sticky footer (swipe CTA / button). Also vanishes at terminal, per the same rule.
/// Wraps `HFSheetFooter`, so it keeps the shadow separator and hosts the sandwich toast.
struct V2Footer<Content: View>: View {
    let isTerminal: Bool
    var caption: String? = nil
    /// A caption with mixed runs (frame 81's red countdown). Wins over `caption`.
    var captionText: Text? = nil
    @ViewBuilder var content: Content

    var body: some View {
        if !isTerminal {
            HFSheetFooter(caption: caption, captionText: captionText) {
                content
            }
        } else {
            HFToastAnchor()          // no footer, but feedback still needs somewhere to land
        }
    }
}

// MARK: - Swipe CTA

/// Every progression in the app is a swipe-to-confirm. Blue for normal progression, green for
/// arrival — expressed as a role so the mapping lives in one place.
enum V2SwipeRole {
    case progress, arrival

    var tint: Color? {
        switch self {
        case .progress: return nil                    // SlidingButtonView's default primary
        case .arrival:  return V2Token.green
        }
    }
}

struct V2SwipeCTA: View {
    let label: String
    var role: V2SwipeRole = .progress
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        SlidingButtonView(label: label, tint: role.tint) { action() }
            .disabled(!enabled)
    }
}

// MARK: - Chip renderers bound to the status enums (P0.2 consumers)

/// SLA chip — tinted + outlined, dark label.
struct V2SlaChip: View {
    let sla: V2Sla
    var body: some View {
        Text(sla.label)
            .typography(HFType.badge12)
            .foregroundColor(HFColor.textPrimary)
            .padding(.horizontal, 6)                        // same box as the status chip
            .frame(minWidth: V2Metrics.chipMinWidth)
            .frame(height: V2Metrics.chip)
            .background(sla.bg)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(sla.stroke, lineWidth: V2Space.hairline))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

/// P0.6 — `pending` has no chip; the SLA chip carries the card instead. Callers just pass the status
/// and get nothing for pending, so the rule can't be forgotten per-surface.
struct V2StopStatusChip: View {
    let status: V2StopStatus
    var body: some View {
        if let label = status.label {
            HFStatusChip(text: label, fill: status.fill, label: status.onFill)
        }
    }
}

struct V2TaskStatusChip: View {
    let status: V2TaskStatus
    var body: some View {
        if let label = status.label {
            HFStatusChip(text: label, fill: status.fill, label: status.onFill)
        }
    }
}

struct V2TripStatusChip: View {
    let status: V2TripStatus
    var body: some View {
        HFStatusChip(text: status.label, fill: status.fill, label: status.onFill)
    }
}

/// Stop identifier pill (Customer / Supplier / Hub / Partner).
struct V2StopIdentifierChip: View {
    let kind: V2StopKind
    var body: some View {
        HFCustomerChip(label: kind.identifier.label, icon: kind.identifier.icon)
    }
}

/// Task identifier pill (Delivery / Pickup / Service / Handback / Scheduled Break).
struct V2TaskIdentifierChip: View {
    let kind: V2TaskKind
    var body: some View {
        HFPillChip(text: kind.label,
                   bg: kind.isBreak ? V2Token.yellowBg : HFColor.purpleBg,
                   fg: kind.isBreak ? Color.encore("Yellow/700") : HFColor.purpleText,
                   dot: kind.glyph == .none,
                   glyph: kind.glyph)
    }
}

// MARK: - P0.10 List affordance rule

/// Dev note 9166:350818 — "Search and filter renders on all Trip list, Stop list, and Task list more
/// than 3 items in the list." Encoded once so every list obeys it.
enum V2ListAffordance {
    static let threshold = 3

    /// Counts RENDERED ROWS, not entities — a hub stop clubs five tasks into one card and shows no
    /// search (frames 17/97), while a partner stop with three separate task cards does (frame 77).
    /// The board draws it at three, so the threshold is inclusive.
    static func showsSearchAndFilter(rowCount: Int) -> Bool { rowCount >= threshold }
}
