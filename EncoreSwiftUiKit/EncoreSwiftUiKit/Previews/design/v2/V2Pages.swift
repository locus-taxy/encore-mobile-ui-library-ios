import SwiftUI

// MARK: - P1 The four surfaces
//
// ~100 frames render from these. A frame is (surface, entity state) — there is no per-frame branching
// anywhere below, and no literal design values: statuses, affordances and motion all come from P0.

/// Counts that appear in copy. Centralised so "1 tasks" can't reappear per surface.
enum V2Text {
    static func tasks(_ n: Int) -> String { "\(n) task\(n == 1 ? "" : "s")" }
    static func stops(_ n: Int) -> String { "\(n) stop\(n == 1 ? "" : "s")" }
    static func clubbedOrders(_ n: Int) -> String { "\(n) clubbed order\(n == 1 ? "" : "s")" }
}

// MARK: - Cards

/// Stop row on the trip page. Composes the HFKit atoms rather than extending `HFStopCard`, which
/// hardcodes the Customer pill and would have to import the V2 status types to do this — the shared
/// kit stays below the V2 layer.
struct V2StopCard: View {
    let stop: V2Stop
    var showNavigate: Bool = false
    /// False while the trip is still pending dispatch — the stop shows no chips at all until then.
    var dispatched: Bool = true
    var onNavigate: () -> Void = {}
    var onTap: () -> Void = {}

    var body: some View {
        V2CardView(model: stop.listCard(showNavigate: showNavigate,
                                        dispatched: dispatched,
                                        onNavigate: onNavigate,
                                        onTap: onTap))
    }
}

/// Task list on the stop sheet.
///
/// Figma groups CONSECUTIVE orders that share a recipient into one white card with a single contact
/// strip beneath (11394-adjacent sheet body): two orders for Priya Sharma share a strip, while stop 3's
/// two different recipients each get their own card + strip. The whole list sits inside a tinted
/// container, so the white cards read as nested rather than floating.
struct V2TaskCard: View {
    let stop: V2Stop
    var onTap: (V2Task) -> Void = { _ in }

    /// Consecutive runs of tasks that share a recipient.
    private var groups: [[V2Task]] {
        var out: [[V2Task]] = []
        for task in stop.looseTasks {
            let key = "\(task.contactName ?? "")|\(task.contactSub ?? "")"
            let prev = out.last?.first
            let prevKey = "\(prev?.contactName ?? "")|\(prev?.contactSub ?? "")"
            if !out.isEmpty, key == prevKey {
                out[out.count - 1].append(task)
            } else {
                out.append([task])
            }
        }
        return out
    }

    var body: some View {
        VStack(spacing: V2Space.groupGap) {
            // The club (if any) is one card; everything else groups by recipient. On the return hub
            // that is the hand-back club AND the separate return-delivery card (Story 1.4.10).
            if !stop.clubbedTasks.isEmpty {
                group(stop.clubbedTasks, clubbed: true)
            }
            ForEach(Array(groups.enumerated()), id: \.offset) { _, run in
                group(run, clubbed: false)
            }
        }
    }

    /// One recipient = one tinted container (primary 4%, r16, 8 inset) holding the white task stack
    /// and its contact strip. Two recipients are two containers, 8 apart (frame 73).
    @ViewBuilder private func group(_ tasks: [V2Task], clubbed: Bool) -> some View {
        VStack(spacing: Spacing.spacing8) {
            VStack(spacing: 0) {
                if clubbed {
                    clubbedRow
                } else {
                    ForEach(tasks) { task in
                        taskRow(task)
                        if task.id != tasks.last?.id {
                            Rectangle().fill(HFColor.divider).frame(height: V2Space.hairline)
                        }
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(HFColor.divider, lineWidth: V2Space.hairline))

            if let first = tasks.first, let name = first.contactName {
                // States board: no call on a terminal task, on a stop the rider hasn't started
                // ("Pending (not started)"), or on the clubbed dock strip — only en route onwards.
                V2ContactRow(name: name, sub: first.contactSub ?? "",
                             showsCall: !clubbed && !first.status.isTerminal && stop.status != .pending)
            }
        }
        .padding(Spacing.spacing8)
        .background(HFColor.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var clubbedRow: some View {
        V2CardView(model: stop.clubbedTaskCard(onTap: {
            if let first = stop.clubbedTasks.first { onTap(first) }
        }))
    }

    private func taskRow(_ task: V2Task) -> some View {
        V2CardView(model: task.listCard(onTap: { onTap(task) }))
    }
}

/// Contact strip under a task (customer name / dock) with an optional call button.
struct V2ContactRow: View {
    let name: String
    let sub: String
    var showsCall: Bool

    var body: some View {
        HStack(spacing: Spacing.spacing12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .v2Label(V2Font.label2)
                    .foregroundColor(HFColor.textPrimary)
                Text(sub)
                    .v2Text(V2Font.body2)
                    .foregroundColor(HFColor.textSecondary)
            }
            Spacer()
            V2ActionRow(isTerminal: !showsCall) {
                EncoreIcon(iconName: "LCallOutline", size: V2Icon.call)
                    .foregroundColor(HFColor.primary)
                    .frame(width: V2Metrics.callDisc, height: V2Metrics.callDisc)
                    .background(HFColor.surface)
                    .clipShape(Circle())
            }
        }
        // Frames 17 / 40: 12 × 8 inset, 52 tall, primary at 8%.
        .padding(.horizontal, Spacing.spacing12)
        .padding(.vertical, Spacing.spacing8)
        .background(HFColor.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Trip row on the delivery list. Rhythm from node 5617:263145 — 12 inset, eyebrow→headline **8**,
/// headline→sub **4**, content→tags **16**, tag gap **4**. The v1 `HFTripCard` spaces everything
/// uniformly at 8, which is what made this read flat.
struct V2TripCard: View {
    let trip: V2Trip
    var onTap: () -> Void = {}

    var body: some View {
        V2CardView(model: trip.listCard(onTap: onTap))
    }
}

// MARK: - P1.1 Trip list

struct V2TripListPage: View {
    let trip: V2Trip
    /// The shift's app-bar status line (`V2Shift.appBarSubtitle`) — the same one Home shows.
    var shiftSubtitle: String? = nil
    var onOpenTrip: () -> Void = {}
    var onAvatar: () -> Void = {}
    var onTab: (V2AppTab) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            V2AppBar(title: "Delivery", subtitle: shiftSubtitle, onAvatar: onAvatar)
            Group {
                if trip.status == .completed {
                    // A finished trip leaves the list; with nothing else planned the tab is empty (112).
                    V2NoTripsState()
                } else {
                    ScrollView {
                        VStack(spacing: V2Space.sectionToCard) {
                            V2SectionHeader(text: "Today (1)")
                            V2TripCard(trip: trip, onTap: onOpenTrip)
                                .padding(.horizontal, V2Space.pageMargin)
                        }
                        .padding(.bottom, Spacing.spacing16)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(HFColor.screen)
            HFToastAnchor(height: 0)
            V2TabBar(active: .delivery, onSelect: onTab)
        }
    }
}

// MARK: - P1.2 Trip page

struct V2TripPage: View {
    let trip: V2Trip
    var onBack: () -> Void = {}
    var onOpenStop: (V2Stop) -> Void = { _ in }
    var onViewDetails: () -> Void = {}
    var onStartTrip: () -> Void = {}
    var onEndTrip: () -> Void = {}

    /// Collapsed once the list has been scrolled: the header keeps only the eyebrow + headline and
    /// gains a drop shadow, and the section label scrolls away with the content (frames 63 → 64).
    @State private var collapsed = false

    private var activeStopId: Int? { trip.stops.first { !$0.status.isTerminal }?.id }

    var body: some View {
        VStack(spacing: 0) {
            V2ListBar(title: "Trip", itemCount: trip.stops.count, onBack: onBack)
            header
            list
            footer
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Zero-height probe: reports how far the content has travelled.
                GeometryReader { proxy in
                    Color.clear.preference(key: V2ScrollOffsetKey.self,
                                           value: proxy.frame(in: .named(Self.space)).minY)
                }
                .frame(height: 0)

                V2SectionHeader(text: "Stops (\(trip.stops.count))")
                    .padding(.bottom, V2Space.sectionToCard)

                VStack(spacing: V2Space.cardGap) {
                    ForEach(trip.stops) { stop in
                        V2StopCard(stop: stop,
                                   showNavigate: stop.id == activeStopId
                                       && trip.status != .pendingDispatch,
                                   dispatched: trip.status != .pendingDispatch,
                                   onTap: { onOpenStop(stop) })
                            .padding(.horizontal, V2Space.pageMargin)
                    }
                }

                // Lets the last card clear the sticky footer instead of sitting under it.
                Color.clear.frame(height: V2Layout.footerClearance)
            }
        }
        .coordinateSpace(name: Self.space)
        .v2OnScrollOffset { minY in
            let shouldCollapse = minY < -12
            if shouldCollapse != collapsed {
                withAnimation(V2Motion.standard) { collapsed = shouldCollapse }
            }
        }
        .background(HFColor.screen)
    }

    private static let space = "v2TripScroll"

    private var header: some View {
        VStack(spacing: 0) {
            V2CardView(model: trip.headerCard(collapsed: collapsed,
                                              onMap: {},
                                              onDetails: onViewDetails))
            // DP-2959 context notice — notifications about the trip itself.
            V2NotificationNotice(about: { $0 == .trip }, insets: V2StopSheet.noticeInsets)
        }
            .background(
                // Collapsed, the header floats over the scrolling list, so it casts a shadow.
                Rectangle()
                    .fill(HFColor.surface)
                    // E2 — 0 4 8 @16% (frames 64, 76).
                    .shadow(color: Color(.sRGB, red: 17/255, green: 19/255, blue: 24/255,
                                         opacity: collapsed ? 0.16 : 0),
                            radius: 4, x: 0, y: 4)
            )
    }

    @ViewBuilder private var footer: some View {
        if trip.status == .completed {
            HFToastAnchor()                          // terminal: no footer, toast still lands (110)
        } else if trip.status == .pendingDispatch {
            V2Footer(isTerminal: false) {
                V2SwipeCTA(label: "Swipe to start trip \(trip.seq)", action: onStartTrip)
            }
        } else if trip.status == .inTransit {
            let remaining = trip.stops.count - trip.doneStops
            V2Footer(isTerminal: false,
                     caption: trip.canEndTrip ? nil
                        : "Visit remaining \(V2Text.stops(remaining)) before ending trip") {
                Button(action: onEndTrip) {
                    Text("End trip \(trip.seq)")
                        .v2Label(V2Font.buttonLarge)
                        .foregroundColor(trip.canEndTrip ? HFColor.onPrimary : HFColor.textDisabled)
                        .frame(maxWidth: .infinity)
                        .frame(height: V2Metrics.footerButton)
                        .background(trip.canEndTrip ? HFColor.primary : HFColor.disabledBg)
                        .clipShape(RoundedRectangle(cornerRadius: V2Metrics.footerRadius))
                }
                .buttonStyle(.plain)
                .allowsHitTesting(trip.canEndTrip)
            }
        }
    }
}

struct V2ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

extension View {
    /// Reports how far a ScrollView's content has travelled (negative once scrolled down).
    ///
    /// On iOS 18+ this reads the scroll view's own geometry. The zero-height GeometryReader probe
    /// (`V2ScrollOffsetKey`) stopped updating mid-scroll there, so the trip header never collapsed
    /// (frames 63 → 64); it stays as the iOS 15–17 path.
    @ViewBuilder func v2OnScrollOffset(_ action: @escaping (CGFloat) -> Void) -> some View {
        if #available(iOS 18.0, *) {
            self.onScrollGeometryChange(for: CGFloat.self,
                                        of: { -($0.contentOffset.y + $0.contentInsets.top) },
                                        action: { _, y in action(y) })
        } else {
            self.onPreferenceChange(V2ScrollOffsetKey.self, perform: action)
        }
    }
}

// MARK: - P1.3 Stop sheet

struct V2StopSheet: View {
    let stop: V2Stop
    /// False until the parent trip is in transit: a stop cannot be started before its trip is.
    var tripStarted: Bool = true
    var canUndoArrival: Bool = false
    var onClose: () -> Void = {}
    var onKebab: () -> Void = {}
    var onOpenTask: (V2Task) -> Void = { _ in }
    var onException: (V2StopException) -> Void = { _ in }
    var onExceptionSheet: () -> Void = {}
    var onPrimary: () -> Void = {}
    /// The kebab's menu (frame 21) — open state lives with the flow so a tap elsewhere can close it.
    var menuOpen: Bool = false
    var onUndoArrival: () -> Void = {}
    var onDismissMenu: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            V2SheetBar(title: stop.kind.pageTitle,
                       showKebab: canUndoArrival,
                       kebabSelected: menuOpen,
                       showSearch: V2ListAffordance.showsSearchAndFilter(rowCount: renderedTaskRows),
                       onKebab: onKebab,
                       onClose: onClose)
            header
            ScrollView {
                VStack(spacing: V2Space.sectionToCard) {
                    V2SectionHeader(text: "Tasks (\(stop.tasks.count))")
                    V2TaskCard(stop: stop, onTap: onOpenTask)
                        .padding(.horizontal, Spacing.spacing16)
                }
                .padding(.bottom, Spacing.spacing16)
            }
            .background(HFColor.screen)
            footer
        }
        .overlay(alignment: .topTrailing) {
            if menuOpen {
                ZStack(alignment: .topTrailing) {
                    // No scrim: a transparent catcher closes the menu on any tap outside it.
                    Color.clear.contentShape(Rectangle()).onTapGesture(perform: onDismissMenu)
                    V2PopoverMenu(items: [
                        V2MenuItem(id: "undo", title: "Undo arrival",
                                   caption: undoCaption,
                                   captionTint: Color.encore("Error/Main"),
                                   action: onUndoArrival)
                    ])
                    // Right edge on the kebab's right edge (✕ 48 + 4 inset + 4), top 4 below it.
                    .padding(.top, 60)
                    .padding(.trailing, 56)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing)))
                }
            }
        }
    }

    /// The block-below-the-header slot (16 sides, 12 bottom), as the task's instruction banner.
    static let noticeInsets = EdgeInsets(top: 0, leading: V2Space.headerInset,
                                         bottom: V2Space.headerInsetBottom, trailing: V2Space.headerInset)

    /// "01:02m left" — the undo window counting down (frame 21).
    private var undoCaption: String {
        String(format: "%02d:%02dm left", stop.undoSecondsLeft / 60, stop.undoSecondsLeft % 60)
    }

    private var header: some View {
        VStack(spacing: 0) {
            V2CardView(model: stop.headerCard(dispatched: tripStarted || stop.status != .pending,
                                              onNavigate: {},
                                              exceptionLabel: exceptionLabel,
                                              onException: onExceptionAction))
            // DP-2959 context notice — this stop's and its tasks' notifications, below the header.
            V2NotificationNotice(about: { target in
                switch target {
                case .stop(let s), .task(let s, _): return s == stop.id
                default: return false
                }
            }, insets: Self.noticeInsets)
        }
        .background(HFColor.surface)
    }

    /// A clubbed stop draws ONE card for every task, so the search/filter affordance counts what is
    /// on screen rather than what is in the model.
    private var renderedTaskRows: Int { (stop.clubbedTasks.isEmpty ? 0 : 1) + stop.looseTasks.count }

    /// One affordance renders as a direct chip; two or more collapse into the `Facing issues?` sheet.
    /// The stop decides what is available (`V2Stop.exceptions`); the surface only decides the shape.
    private var exceptionLabel: String? {
        let options = stop.exceptions
        if options.count == 1 { return options[0].chipLabel }
        if options.count > 1 { return "Facing issues?" }
        return nil
    }

    private func onExceptionAction() {
        let options = stop.exceptions
        if options.count == 1 { onException(options[0]) } else if options.count > 1 { onExceptionSheet() }
    }

    @ViewBuilder private var footer: some View {
        switch stop.status {
        case .pending where tripStarted:
            V2Footer(isTerminal: false) {
                V2SwipeCTA(label: "Swipe to start work", action: onPrimary)
            }
        case .enRoute:
            V2Footer(isTerminal: false) {
                V2SwipeCTA(label: "Swipe to mark arrival", role: .arrival, action: onPrimary)
            }
        case .arrived where stop.kind == .partner:
            V2Footer(isTerminal: false) {
                V2SwipeCTA(label: "Swipe to start tasks", action: onPrimary)
            }
        case .inProgress where stop.kind == .partner:
            // Partner dwell gate: undelivered tasks can't be failed until the timer expires.
            let waiting = stop.dwellSecondsLeft > 0
            // Frame 81: only the time is red.
            V2Footer(isTerminal: false,
                     captionText: waiting
                        ? Text("Wait at this stop for").foregroundColor(HFColor.textSecondary)
                            + Text(" \(dwellText) mins").foregroundColor(Color.encore("Error/Main"))
                        : nil) {
                Button(action: onPrimary) {
                    Text("Mark undelivered tasks as failed")
                        .v2Label(V2Font.buttonLarge)
                        .foregroundColor(waiting ? HFColor.textDisabled : HFColor.onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: V2Metrics.footerButton)
                        .background(waiting ? HFColor.disabledBg : HFColor.primary)
                        .clipShape(RoundedRectangle(cornerRadius: V2Metrics.footerRadius))
                }
                .buttonStyle(.plain)
                .allowsHitTesting(!waiting)
            }
        default:
            // Arrived at a hub/customer stop and every terminal state carry no footer — the task card
            // is the next action. The anchor keeps toasts landing (frames 19, 73).
            HFToastAnchor()
        }
    }

    private var dwellText: String {
        let m = stop.dwellSecondsLeft / 60, s = stop.dwellSecondsLeft % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - P1.4 Task detail

struct V2TaskDetailSheet: View {
    let stop: V2Stop
    let task: V2Task
    var isBlocked: Bool = false
    var dwellBlocked: Bool = false
    var onBack: () -> Void = {}
    var onClose: () -> Void = {}
    var onPrimary: () -> Void = {}
    var onMarkFailed: () -> Void = {}
    var onGoToRelated: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            V2SheetBar(title: task.kind.pageTitle, showBack: true,
                       onBack: onBack, onClose: onClose)
            header
            ScrollView {
                VStack(spacing: V2Space.sectionSeam) {
                    if stop.isClubbed(task) {
                        // One section per order, each with its own status chip (26–28, 37, 99–104).
                        ForEach(stop.clubbedTasks) { order in
                            orderHeader(order)
                            units(order)
                        }
                    } else {
                        V2SectionHeader(text: "Handling units (\(task.units.count))")
                        units(task)
                    }
                }
                .padding(.bottom, Spacing.spacing16)
            }
            .background(HFColor.screen)
            footer
        }
    }

    // Same header node as the trip and stop headers (frames 45, 46, 59): eyebrow row → 8 → name
    // 16/24 → 2 → address 12/18 → 12 → action row. The instruction banner is a block of its own
    // BELOW the header (16 sides, 12 bottom), not a slot inside it.
    private var header: some View {
        VStack(spacing: 0) {
            V2CardView(model: task.headerCard(clubbed: stop.isClubbed(task) ? stop.clubbedTasks.count : nil,
                                              fallbackTitle: stop.title,
                                              dwellBlocked: dwellBlocked,
                                              onCall: {},
                                              onMarkFailed: onMarkFailed))
            if let instruction = task.instruction {
                V2InstructionBanner(text: instruction)
                    .padding(.horizontal, V2Space.headerInset)
                    .padding(.bottom, V2Space.headerInsetBottom)
            }
            // DP-2959 context notice: the same block-below-the-header slot as the instruction.
            V2NotificationNotice(about: { $0 == .task(stop: stop.id, task: task.id) }, insets: V2StopSheet.noticeInsets)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.surface)
    }

    /// `ORDER_ID_… (n)` + the order's status chip (none while pending) — 44 tall, pl12 (frame 27).
    private func orderHeader(_ order: V2Task) -> some View {
        HStack(spacing: Spacing.spacing8) {
            HStack(spacing: 2) {
                Text(order.orderId).lineLimit(1).truncationMode(.middle)
                Text("(\(order.units.count))")
            }
            .v2Label(V2Font.overline2)
            .foregroundColor(HFColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            V2TaskStatusChip(status: order.status)
        }
        .padding(.leading, Spacing.spacing12)
        .padding(.trailing, Spacing.spacing16)
        .frame(height: V2Metrics.listHeader)
    }

    /// One card per handling unit, 8 apart.
    private func units(_ order: V2Task) -> some View {
        VStack(spacing: Spacing.spacing8) {
            ForEach(order.units) { huCard($0) }
        }
        .padding(.horizontal, V2Space.pageMargin)
    }

    /// HU card (node 1791:51832): white r12, p12, no stroke; "HU ID" label → code label1 (wraps)
    /// → 4 → box count body2 → 16 → tags 4 apart.
    ///
    /// The code is backend data with no self-describing prefix, so the card names it: the static
    /// "HU ID" label sits over the value, the same Label/Value pairing the scanner result card uses
    /// (frame 50) — the list and the scan confirmation read the same way. (Design call, 2026-10-06.)
    private func huCard(_ hu: V2HU) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("HU ID")
                .v2Label(V2Font.body2)
                .foregroundColor(HFColor.textSecondary)
            // Shown exactly as the backend sends it — never truncated or reformatted; a long code
            // wraps. The label, not the value, carries the meaning.
            Text(hu.id)
                .v2Text(V2Font.label1)
                .foregroundColor(HFColor.textPrimary)
            Text(hu.boxLabel)
                .v2Label(V2Font.body2)
                .foregroundColor(HFColor.textSecondary)
                .padding(.top, Spacing.spacing4)
            if !hu.tags.isEmpty {
                HStack(spacing: V2Space.tagGap) {
                    ForEach(hu.tags, id: \.self) { tag in
                        HFPillChip(text: tag, bg: HFColor.screen, fg: HFColor.textSecondary, dot: false)
                    }
                }
                .padding(.top, V2Space.contentToTags)
            }
        }
        .padding(Spacing.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
    }

    @ViewBuilder private var footer: some View {
        if isBlocked {
            // Dependency not yet resolved: no swipe bar, just a route to the blocking task (frame 44).
            V2Footer(isTerminal: false,
                     caption: task.kind == .pickup
                        ? "Finish the related delivery task to do this pickup"
                        : "Finish the related pickup task to do this delivery") {
                Button(action: onGoToRelated) {
                    Text("Go to related task")
                        .v2Label(V2Font.buttonLarge)
                        .foregroundColor(HFColor.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: V2Metrics.footerButton)
                        .overlay(RoundedRectangle(cornerRadius: V2Metrics.footerRadius).stroke(HFColor.primary, lineWidth: V2Space.hairline))
                }
                .buttonStyle(.plain)
            }
        } else {
            switch task.status {
            case .pending:
                V2Footer(isTerminal: false) {
                    V2SwipeCTA(label: "Swipe to start task",
                               action: onPrimary)
                }
            case .inProgress:
                // Split footer, primary in the right slot: 160 × 48 "Scan HUs →" (frame 27).
                V2Footer(isTerminal: false) {
                    HStack(spacing: Spacing.spacing8) {
                        Spacer(minLength: 0)
                        V2Button(label: "Scan HUs", trailingIcon: "LArrowForward", action: onPrimary)
                            .frame(width: V2Metrics.footerAction)
                    }
                }
            default:
                HFToastAnchor()                     // terminal task: toast still lands (frame 37, 55)
            }
        }
    }
}

/// Delivery instruction on a task (frame 46): info-tinted row, leading ⓘ, single line.
struct V2InstructionBanner: View {
    /// Frame 45: 48 tall — 8 inset around a 32pt icon box holding a 20pt glyph; body1 14/20; r4 with a
    /// 0.5 border over the tone at 8%. The notification notice (DP-2959) adds a Medium 14 title, an
    /// optional link line and a ✕; error tone per the inline error alert (#FFB6AB border, r4).
    enum Tone { case info, error }
    var title: String? = nil
    let text: String
    var tone: Tone = .info
    var link: (label: String, action: () -> Void)? = nil
    var onClose: (() -> Void)? = nil

    init(title: String? = nil, text: String, tone: Tone = .info,
         link: (label: String, action: () -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.title = title; self.text = text; self.tone = tone; self.link = link; self.onClose = onClose
    }

    private var border: Color {
        tone == .info ? Color(.sRGB, red: 189/255, green: 226/255, blue: 255/255, opacity: 1)  // #BDE2FF
                      : Color(.sRGB, red: 255/255, green: 182/255, blue: 171/255, opacity: 1)  // #FFB6AB
    }
    private var main: Color { tone == .info ? Color.encore("Info/Main") : Color.encore("Error/Main") }
    private var glyph: Color { tone == .info ? HFColor.infoText : Color.encore("Error/Main") }

    var body: some View {
        HStack(alignment: title == nil ? .center : .top, spacing: Spacing.spacing4) {
            EncoreIcon(iconName: tone == .info ? "LInfo" : "LError", size: V2Icon.banner)
                .foregroundColor(glyph)
                .frame(width: 32, height: title == nil ? 32 : 20)
            VStack(alignment: .leading, spacing: 0) {
                if let title {
                    Text(title)
                        .v2Label(V2Font.label1)
                        .foregroundColor(HFColor.textPrimary)
                }
                Text(text)
                    .v2Text(V2Font.body1)
                    .foregroundColor(HFColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let link {
                    Button(action: link.action) {
                        Text(link.label)
                            .v2Label(V2Font.buttonMedium)
                            .underline()
                            .foregroundColor(glyph)
                            .frame(minHeight: 28, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
            if let onClose {
                Button(action: onClose) {
                    EncoreIcon(iconName: "LCross", size: 20)
                        .foregroundColor(V2Token.actionActive)
                        .frame(width: 32, height: 20)
                        .contentShape(Rectangle().inset(by: -12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
        }
        .padding(.horizontal, Spacing.spacing8)
        .padding(.vertical, Spacing.spacing8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(main.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(border, lineWidth: V2Space.hairline))
    }
}

// MARK: - Exception sheet (frame 70)

struct V2ExceptionSheet: View {
    let options: [V2StopException]
    var onClose: () -> Void = {}
    var onPick: (V2StopException) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            HFSheetTitle(title: "Facing issues?", onClose: onClose)
            HFSeam()
            ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                Button { onPick(option) } label: {
                    // Frame 70: pl16 pr4 py8, gap 16; label1 title (the remaining count in error red)
                    // over body1; a 24pt chevron in a 48 target.
                    HStack(alignment: .center, spacing: Spacing.spacing16) {
                        VStack(alignment: .leading, spacing: Spacing.spacing2) {
                            title(option)
                                .v2Label(V2Font.label1)
                            Text(option.rowSubtitle)
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
                if i < options.count - 1 {
                    HFSeam()
                }
            }
            HFSheetBottomInset()
        }
        .background(HFColor.surface)
    }

    private func title(_ option: V2StopException) -> Text {
        switch option {
        case .deferStop(let remaining):
            return Text("Defer stop").foregroundColor(HFColor.textPrimary)
                + Text(" (\(remaining) remaining)").foregroundColor(Color.encore("Error/Main"))
        default:
            return Text(option.rowTitle).foregroundColor(HFColor.textPrimary)
        }
    }
}

// MARK: - Trip `View details` — node 10956:665726
//
// Three sections of key-value grids, separated by hairlines. Geometry from the node:
//   <DialogTitle>   360 × 64
//   section         12 above, 16 below; heading 20, then 12 down to the grid
//   section 1       no heading — a 2-column grid, pairs 156 wide (gap 16), 54 tall (it carries a
//                   caption line)
//   sections 2 / 3  heading + a 3-column grid
//
// Every number in it is derived. The counts drawn in Figma (2 stops, 3 tasks) belong to an older
// seed than the trip page behind them, which is why they are not copied across.

struct V2TripDetailsSheet: View {
    let trip: V2Trip
    var onClose: () -> Void = {}

    var body: some View {
        // The sections are NOT separated by dividers. The sheet's own background is
        // `background/columnHeading` (#f5f5f5) and each section paints `background/default` on top
        // with a 1px gap, so what reads as a rule is the sheet showing through. Drawing a
        // `Divider` (#c2c2c2) here is both the wrong colour and the wrong construct.
        VStack(spacing: V2Space.sectionSeam) {
            HFSheetTitle(title: "View details", onClose: onClose)
                .background(HFColor.surface)

            section(heading: nil, columns: 2, pairs: [
                V2Pair(id: "vehicle", label: "Vehicle", value: "KA-01-AB-1234",
                       caption: "LCV Tata Ace"),
                V2Pair(id: "helper", label: "Helper", value: "Suresh"),
            ])

            section(heading: "Stop Progress (\(trip.stops.count))", columns: 3, pairs: [
                V2Pair(id: "todo", label: "To do", value: "\(trip.stopsToDo)"),
                V2Pair(id: "done", label: "Completed", value: "\(trip.stops(.completed))"),
                V2Pair(id: "failed", label: "Failed", value: "\(trip.stops(.failed))"),
                V2Pair(id: "partial", label: "Partial", value: "\(trip.stops(.partial))"),
                V2Pair(id: "skipped", label: "Skipped", value: "\(trip.stops(.skipped))"),
            ])

            section(heading: "Task Types (\(trip.allTasks.count))", columns: 3, pairs: [
                V2Pair(id: "pickup", label: "Pickup", value: "\(trip.pickups)"),
                V2Pair(id: "delivery", label: "Delivery", value: "\(trip.deliveries)"),
                V2Pair(id: "service", label: "Service", value: "\(trip.services)"),
            ])
        }
        .background(HFColor.screen)
        // Bottom inset continues the last section's white — stacked as its own block it picked up
        // a 1px seam and read as a divider under Task Types.
        .padding(.bottom, HFLayout.bottomInset)
        .background(HFColor.surface)
    }

    private func section(heading: String?, columns: Int, pairs: [V2Pair]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let heading {
                Text(heading)
                    .v2Label(V2Font.label1)          // typography/label1 — 14/20 Medium
                    .foregroundColor(HFColor.textPrimary)
                    .frame(height: V2Metrics.detailsHeading, alignment: .leading)
                    .padding(.bottom, V2Space.headingToGrid)
            }
            V2GridView(slot: V2GridSlot(columns: columns, pairs: pairs))
        }
        .padding(.horizontal, V2Space.headerInset)
        .padding(.top, V2Space.detailsSectionTop)
        .padding(.bottom, V2Space.detailsSectionBottom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.surface)
    }
}
