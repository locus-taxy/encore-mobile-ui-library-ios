import SwiftUI

// MARK: - DP-2956 In-app notification inbox
//
// Built to the brief only, on the scan list's structure (Scan HUs, frames 08 / 09):
//   tabs on top · grey day sections with an accordion header and count · flat white rows with a
//   leading checkbox · ticking one swaps the bar for ✕ "n selected" and the footer for one action.
//
// Split the way the dev team's SDUI stack splits (disco-mobile-workspace docs/sdui-framework.md):
//   • SDUI card  — the row CONTENT: `notification_list_card_v1`. `V2NotificationRowVars` is that
//                  card's variables; `V2NotificationRowCard` renders nothing but those.
//   • Native host — everything around it: navbar, tabs, day headers, filter sheet, paging, checkbox,
//                  swipe-to-read, mark-all, offline / empty / no-results states, row tap → target.
// Keep that line when changing this file: if it needs a gesture, a list or a sheet, it's host chrome.

// MARK: SDUI card — notification_list_card_v1

/// The card's variables: subject, full message, relative time, read or unread, plus the gone line
/// ("The row stays and says so"). Severity and type are filters only — not drawn on the row.
struct V2NotificationRowVars: Equatable {
    var subject: String
    var body: String
    /// Today's rows only ("12 min ago"). Under Yesterday and older the section header already says
    /// when, so the row shows no time.
    var timeLabel: String?
    var isUnread: Bool
    var goneLabel: String?

    static func make(_ n: V2Notification, now: Date) -> Self {
        V2NotificationRowVars(subject: n.subject,
                              body: n.body,
                              timeLabel: V2Ago.group(n.createdAt, now: now) == .today
                                  ? V2Ago.label(n.createdAt, now: now) : nil,
                              isUnread: !n.read,
                              goneLabel: n.targetGone ? "This \(n.target.noun) is no longer available" : nil)
    }
}

/// Subject with the unread dot at its right, the message in full, then the time as a small grey
/// line under it — the scan row's "0/3 box" line. Unread = primary dot + SemiBold subject; read =
/// Regular subject and a secondary message.
struct V2NotificationRowCard: View {
    let vars: V2NotificationRowVars

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing4) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.spacing8) {
                Text(vars.subject)
                    .v2Text(vars.isUnread ? V2Font.cardTitle : V2Font.body1)
                    .foregroundColor(HFColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if vars.isUnread {
                    Circle()
                        .fill(HFColor.primary)
                        .frame(width: 8, height: 8)
                        .accessibilityLabel("Unread")
                }
            }
            // Never cut short.
            Text(vars.body)
                .v2Text(V2Font.body2)
                .foregroundColor(vars.isUnread ? HFColor.textPrimary : HFColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let gone = vars.goneLabel {
                HStack(spacing: Spacing.spacing4) {
                    EncoreIcon(iconName: "LInfo", size: 16)
                    Text(gone).v2Label(V2Font.label2)
                }
                .foregroundColor(HFColor.textSecondary)
                .padding(.top, Spacing.spacing4)
            }
            if let time = vars.timeLabel {
                Text(time)
                    .v2Label(V2Font.label2)
                    .foregroundColor(HFColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum V2Ago {
    /// Relative, as the brief asks: "Just now", "12 min ago", "3 h ago", "Yesterday", "4 days ago".
    static func label(_ date: Date, now: Date) -> String {
        let mins = Int(now.timeIntervalSince(date) / 60)
        if mins < 1 { return "Just now" }
        if mins < 60 { return "\(mins) min ago" }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: now)).day ?? 0
        if days == 0 { return "\(mins / 60) h ago" }
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days) days ago" }
        let weeks = days / 7
        return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
    }

    enum Group: Int, CaseIterable {
        case today, yesterday, thisWeek, older
        var title: String {
            switch self {
            case .today:     return "Today"
            case .yesterday: return "Yesterday"
            case .thisWeek:  return "This week"
            case .older:     return "Older"
            }
        }
    }

    /// Day groups in the worker's time zone (AC-2): today, yesterday, this week, older.
    static func group(_ date: Date, now: Date) -> Group {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: now)).day ?? 0
        switch days {
        case ..<1: return .today
        case 1:    return .yesterday
        case 2..<7: return .thisWeek
        default:   return .older
        }
    }
}

// MARK: Filter

/// The brief's three filters. Status (unread, read) is the tab row, as the scan list's To do / Done;
/// type and severity are the filter sheet.
struct V2InboxFilter: Equatable {
    enum Status: String, CaseIterable { case all, unread, read }
    var status: Status = .all
    var kind: Set<V2NotificationKind> = []
    var severity: Set<V2Severity> = []

    /// Sheet facets only — the tab never badges the filter icon.
    var count: Int { kind.count + severity.count }
    var isEmpty: Bool { count == 0 }

    func matchesFacets(_ n: V2Notification) -> Bool {
        (kind.isEmpty || kind.contains(n.kind)) && (severity.isEmpty || severity.contains(n.severity))
    }

    func matches(_ n: V2Notification) -> Bool {
        guard matchesFacets(n) else { return false }
        switch status {
        case .all:    return true
        case .unread: return !n.read
        case .read:   return n.read
        }
    }
}

/// Figma's list filter sheet (Trip + Search › Search and filter): category rail on the left,
/// checkboxes with counts on the right, Apply (enabled once something changed) + Reset all.
struct V2InboxFilterSheet: View {
    let entries: [V2Notification]
    let applied: V2InboxFilter
    var onApply: (V2InboxFilter) -> Void
    var onClose: () -> Void

    enum Facet: String, CaseIterable { case severity = "Severity", type = "Type" }
    @State private var facet: Facet = .severity
    @State private var draft = V2InboxFilter()

    var body: some View {
        VStack(spacing: 0) {
            HFSheetTitle(title: "Notification filter", onClose: onClose)
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 0) {
                    ForEach(Facet.allCases, id: \.self) { f in
                        let n = picked(f)
                        Button { facet = f } label: {
                            Text(n > 0 ? "\(f.rawValue.uppercased()) (\(n))" : f.rawValue.uppercased())
                                .v2Label(V2Font.overline2)
                                .foregroundColor(facet == f ? HFColor.primary : HFColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Spacing.spacing16)
                                .frame(height: 52)
                                .background(facet == f ? HFColor.primary.opacity(0.04) : HFColor.surface)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
                .frame(width: 120)
                .background(HFColor.surface)
                VStack(spacing: 0) {
                    ForEach(options, id: \.label) { o in
                        Button { o.toggle() } label: {
                            HStack(spacing: Spacing.spacing16) {
                                EncoreIcon(iconName: o.on ? "LCheckboxFilled" : "LCheckboxBlank", size: 24)
                                    .foregroundColor(o.on ? HFColor.primary : V2Token.actionActive)
                                Text("\(o.label) (\(o.count))")
                                    .v2Text(V2Font.body1)
                                    .foregroundColor(HFColor.textPrimary)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, Spacing.spacing16)
                            .frame(height: 52)
                            .background(o.on ? HFColor.primary.opacity(0.04) : HFColor.surface)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
                .background(HFColor.screen)
            }
            .frame(height: 300)
            HFSheetFooter {
                VStack(spacing: Spacing.spacing8) {
                    V2Button(label: "Apply", enabled: draft != applied) { onApply(draft) }
                    V2Button(label: "Reset all", role: .text, enabled: !draft.isEmpty) {
                        draft = V2InboxFilter(status: applied.status)
                    }
                }
            }
        }
        .onAppear { draft = applied }
    }

    private func picked(_ f: Facet) -> Int {
        switch f {
        case .type:     return draft.kind.count
        case .severity: return draft.severity.count
        }
    }

    private struct Option { let label: String; let count: Int; let on: Bool; let toggle: () -> Void }

    private var options: [Option] {
        switch facet {
        case .type:
            return [V2NotificationKind.alert, .notification].map { k in
                Option(label: k == .alert ? "Alerts" : "Notifications",
                       count: entries.filter { $0.kind == k }.count,
                       on: draft.kind.contains(k),
                       toggle: { draft.kind.formSymmetricDifference([k]) })
            }
        case .severity:
            return V2Severity.allCases.map { s in
                Option(label: s.label,
                       count: entries.filter { $0.severity == s }.count,
                       on: draft.severity.contains(s),
                       toggle: { draft.severity.formSymmetricDifference([s]) })
            }
        }
    }
}

// MARK: Native host — the inbox page

struct V2InboxPage: View {
    @ObservedObject var center: V2NotificationCenter
    var onBack: () -> Void
    var onOpen: (V2Notification) -> Void
    var onFilter: () -> Void
    var filter: V2InboxFilter
    var onResetFilter: () -> Void
    /// The status tab, kept by the flow so it survives the filter sheet.
    var onStatus: (V2InboxFilter.Status) -> Void
    /// Demo states only: open already selecting these ids.
    var demoSelection: Set<Int> = []

    @Environment(\.hfToast) private var toast
    /// Paging: the first page, then one more each time the end of the list comes into view.
    @State private var shown = Self.pageSize
    @State private var loadingMore = false
    /// As on the scan list: ticking a row's checkbox IS selection mode; none ticked = normal.
    @State private var selected: Set<Int> = []
    @State private var collapsed: Set<V2Ago.Group> = []
    @State private var swiping: (id: Int, dx: CGFloat)? = nil
    static let pageSize = 8

    private var selecting: Bool { !selected.isEmpty }
    private var now: Date { Date() }
    /// Sheet facets applied, tab ignored — what the tab counts are taken from.
    private var faceted: [V2Notification] { center.entries.filter(filter.matchesFacets) }
    private var matching: [V2Notification] { center.entries.filter(filter.matches) }
    private var visible: [V2Notification] { Array(matching.prefix(shown)) }

    var body: some View {
        VStack(spacing: 0) {
            navbar
            if center.offline {
                offlineStrip
                state(title: "No connection",
                      body: "Your notifications need a connection. They'll show here once you're back online.")
            } else if center.entries.isEmpty {
                state(title: "No notifications yet", body: "Anything you're sent will show here.")
            } else {
                // Frame 09: "Select all" replaces the tabs while selecting.
                if selecting { selectAllRow } else { tabs }
                HFSeam()
                if matching.isEmpty {
                    state(title: "No results found", body: "Try adjusting or clearing your filters",
                          action: filter.isEmpty ? nil : ("Reset all", onResetFilter))
                } else {
                    list
                }
            }
            footer
        }
        .background(HFColor.screen)
        .ignoresSafeArea(.container, edges: .bottom)
        .onChange(of: filter) { _ in shown = Self.pageSize }
        .onAppear { if !demoSelection.isEmpty { selected = demoSelection } }
    }

    // MARK: Top — navbar, then tabs + "Mark all as read" (frame 08); ✕ "n selected" + Select all (09)

    @ViewBuilder private var navbar: some View {
        if selecting {
            V2Navbar(back: { withAnimation(V2Motion.standard) { selected = [] } },
                     backIcon: "LCross",
                     title: "\(selected.count) selected")
        } else {
            V2Navbar(back: onBack,
                     title: "Notifications",
                     actions: center.offline || center.entries.isEmpty ? [] : [
                        V2NavAction(id: "filter", icon: "LFilterAlt",
                                    badge: filter.isEmpty ? nil : filter.count, action: onFilter)
                     ])
        }
    }

    /// The scan list's counted tabs for status. No separate mark-all: Select all → Mark read does it.
    private var tabs: some View {
        V2Tabs(tabs: [V2Tab(id: "all", label: "All", count: faceted.count),
                      V2Tab(id: "unread", label: "Unread", count: faceted.filter { !$0.read }.count),
                      V2Tab(id: "read", label: "Read", count: faceted.filter(\.read).count)],
               selection: Binding(get: { filter.status.rawValue },
                                  set: { id in withAnimation(V2Motion.standard) {
                                      onStatus(V2InboxFilter.Status(rawValue: id) ?? .all)
                                  } }))
    }

    /// Frame 09's select-all row: a 48 checkbox target, then the label.
    private var selectAllRow: some View {
        let ids = Set(matching.map(\.id))
        let all = !ids.isEmpty && ids.isSubset(of: selected)
        return Button {
            withAnimation(V2Motion.standard) { selected = all ? [] : ids }
        } label: {
            HStack(spacing: -Spacing.spacing8) {
                V2Checkbox(checked: all)
                Text("Select all")
                    .v2Label(V2Font.chipLabel)
                    .foregroundColor(HFColor.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.leading, Spacing.spacing4)
            .frame(height: V2Metrics.tabBar)
            .background(HFColor.surface)
        }
        .buttonStyle(.plain)
    }

    /// Frame 09's footer while selecting: one hug-right action — "Mark read" while any picked row is
    /// unread, else "Mark unread". Otherwise an empty band, so toasts still have a footer to rise from.
    private var footer: some View {
        HFToastFooter {
            if selecting {
                let markRead = center.entries.contains { selected.contains($0.id) && !$0.read }
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    V2Button(label: markRead ? "Mark read" : "Mark unread",
                             leadingIcon: markRead ? "LCheck" : nil,
                             hug: true) { finishSelection(read: markRead) }
                }
                .padding(.horizontal, V2Space.headerInset)
                .frame(height: V2Metrics.dialogActions)
                .padding(.bottom, max(0, HFLayout.bottomInset - Spacing.spacing16))
                .frame(maxWidth: .infinity)
                .background(
                    Rectangle()
                        .fill(HFColor.surface)
                        .shadow(color: Color(.sRGB, red: 17/255, green: 19/255, blue: 24/255, opacity: 0.16),
                                radius: 2, x: 0, y: 0)
                )
                .transition(.move(edge: .bottom))
            } else {
                Color.clear.frame(maxWidth: .infinity).frame(height: HFLayout.bottomInset)
            }
        }
    }

    private var offlineStrip: some View {
        HStack(spacing: Spacing.spacing8) {
            EncoreIcon(iconName: "LWarning", size: 20)
            Text("Offline · Last synced 08:16").v2Label(V2Font.label1)
        }
        .foregroundColor(HFColor.onPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(HFColor.warning)
    }

    // MARK: List — the scan list's grey day sections and flat white rows

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: V2Space.sectionSeam) {
                ForEach(V2Ago.Group.allCases, id: \.self) { g in
                    let rows = visible.filter { V2Ago.group($0.createdAt, now: now) == g }
                    if !rows.isEmpty {
                        V2ListSectionHeader(title: g.title.uppercased(),
                                            count: matching.filter { V2Ago.group($0.createdAt, now: now) == g }.count,
                                            expanded: !collapsed.contains(g)) {
                            withAnimation(V2Motion.standard) { collapsed.formSymmetricDifference([g]) }
                        }
                        if !collapsed.contains(g) {
                            ForEach(rows) { row($0) }
                        }
                    }
                }
                if shown < matching.count {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .onAppear(perform: loadMore)
                }
                Color.clear.frame(height: Spacing.spacing16)
            }
        }
    }

    private func loadMore() {
        guard !loadingMore else { return }
        loadingMore = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            shown += Self.pageSize
            loadingMore = false
        }
    }

    /// Host chrome around one SDUI row card, laid out as the scan list's HU row (frame 08): a 48
    /// checkbox top-aligned at x4, content, white, edge to edge. Tap opens (or toggles while
    /// selecting); swipe left toggles read.
    private func row(_ n: V2Notification) -> some View {
        let dx = swiping?.id == n.id ? swiping!.dx : 0
        let picked = selected.contains(n.id)
        return ZStack(alignment: .trailing) {
            // What the swipe reveals.
            HStack {
                Spacer()
                Text(n.read ? "Mark unread" : "Mark read")
                    .v2Label(V2Font.label1)
                    .foregroundColor(HFColor.onPrimary)
                    .padding(.trailing, Spacing.spacing24)
            }
            .frame(maxHeight: .infinity)
            .background(HFColor.primary)
            .opacity(dx < 0 ? 1 : 0)

            HStack(alignment: .top, spacing: Spacing.spacing4) {
                // Gmail-style: the type icon (filled, grey) IS the selection handle — tapping it
                // starts selecting, and while selecting every icon becomes a checkbox in the same slot.
                Button { toggle(n.id) } label: {
                    if selecting {
                        V2Checkbox(checked: picked)
                    } else {
                        EncoreIcon(iconName: n.kind == .alert ? "LAlertTri" : "LBell", size: V2Icon.bar)
                            .foregroundColor(V2Token.actionActive)
                            .frame(width: V2Metrics.touchTarget, height: V2Metrics.touchTarget)
                            .accessibilityLabel(n.kind == .alert ? "Alert" : "Notification")
                    }
                }
                .buttonStyle(.plain)
                V2NotificationRowCard(vars: .make(n, now: now))
                    .padding(.top, Spacing.spacing12)
            }
            .padding(.leading, Spacing.spacing4)
            .padding(.trailing, V2Space.pageMargin)
            .padding(.bottom, Spacing.spacing12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HFColor.surface)
            .offset(x: dx)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if selecting {
                toggle(n.id)
            } else {
                center.markRead([n.id])
                onOpen(n)
            }
        }
        .onLongPressGesture(minimumDuration: 0.4) { if !selecting { toggle(n.id) } }
        .simultaneousGesture(selecting ? nil : DragGesture(minimumDistance: 12)
            .onChanged { v in
                guard abs(v.translation.width) > abs(v.translation.height) else { return }
                swiping = (n.id, min(0, max(-140, v.translation.width)))
            }
            .onEnded { v in
                if v.translation.width < -80 {
                    center.markRead([n.id], !n.read)
                    toast?.show(n.read ? "Marked as unread" : "Marked as read")
                }
                withAnimation(V2Motion.standard) { swiping = nil }
            })
    }

    private func toggle(_ id: Int) {
        withAnimation(V2Motion.standard) { selected.formSymmetricDifference([id]) }
    }

    private func finishSelection(read: Bool) {
        let ids = Array(selected)
        guard !ids.isEmpty else { return }
        center.markRead(ids, read)
        withAnimation(V2Motion.standard) { selected = [] }
        toast?.show("\(ids.count) marked as \(read ? "read" : "unread")")
    }

    // MARK: States

    private func state(title: String, body: String, action: (String, () -> Void)? = nil) -> some View {
        VStack(spacing: Spacing.spacing8) {
            Image.withName("HFEmptyRider")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding(.bottom, Spacing.spacing8)
            Text(title)
                .v2Label(V2Font.sheetHeadline)
                .foregroundColor(HFColor.textPrimary)
            Text(body)
                .v2Text(V2Font.body1)
                .foregroundColor(HFColor.textSecondary)
                .multilineTextAlignment(.center)
            if let action {
                Button(action: action.1) {
                    Text(action.0)
                        .v2Label(V2Font.buttonMedium)
                        .foregroundColor(HFColor.primary)
                        .padding(.horizontal, Spacing.spacing24)
                        .frame(height: 40)
                        .overlay(RoundedRectangle(cornerRadius: V2Metrics.footerRadius).stroke(HFColor.primary, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, Spacing.spacing8)
            }
        }
        .padding(.horizontal, Spacing.spacing32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: -40)
    }
}

// MARK: Seed — what was already in the inbox

extension V2NotificationCenter {
    /// A plausible history for the seeded driver, spread across the four day groups. Words follow the
    /// mobile push catalogue's kinds (trip assigned, stop added, shift notices, hub messages, breaks).
    static func history(now: Date = Date()) -> [V2Notification] {
        func ago(_ minutes: Double) -> Date { now.addingTimeInterval(-minutes * 60) }
        let day = 24.0 * 60
        return [
            V2Notification(id: 101, severity: .high, kind: .notification,
                           subject: "Stop added to trip 1",
                           body: "Costa Coffee was added as stop 4 of 5. Your route order has been updated.",
                           createdAt: ago(12), target: .stop(4)),
            V2Notification(id: 102, severity: .medium, kind: .notification,
                           subject: "Customer asked for a call first",
                           body: "Priya Sharma at stop 2 asked you to call on arrival and not ring the doorbell.",
                           createdAt: ago(48), target: .stop(2)),
            V2Notification(id: 103, severity: .low, kind: .notification,
                           subject: "Trip 1 assigned",
                           body: "You have a new trip for today, 08:00 AM to 02:00 PM, with 5 stops.",
                           createdAt: ago(95), read: true, target: .trip),
            V2Notification(id: 104, severity: .critical, kind: .alert,
                           subject: "Vehicle check overdue",
                           body: "Your vehicle check for KA-03-MX-4412 was due before your shift. Complete it at the hub before your next trip.",
                           createdAt: ago(day + 130), read: true),
            V2Notification(id: 105, severity: .low, kind: .notification,
                           subject: "Trip 2 reassigned",
                           body: "Trip 2 was moved to another driver. You don't need to do anything.",
                           createdAt: ago(day + 300), target: .trip, targetGone: true),
            V2Notification(id: 106, severity: .medium, kind: .alert,
                           subject: "Break due",
                           body: "You have driven 4 h 30 min. Take your break at your next stop.",
                           createdAt: ago(day + 420), read: true),
            V2Notification(id: 107, severity: .low, kind: .notification,
                           subject: "Shift added for Friday",
                           body: "You have a new shift on Friday, 08:00 AM to 02:00 PM.",
                           createdAt: ago(3 * day), read: true, target: .shift),
            V2Notification(id: 108, severity: .high, kind: .alert,
                           subject: "Stop skipped by dispatch",
                           body: "Stop 6 on trip 3 was skipped by dispatch. Don't go to Brigade Road; continue to your next stop.",
                           createdAt: ago(4 * day), read: true),
            V2Notification(id: 109, severity: .low, kind: .notification,
                           subject: "Message from your hub",
                           body: "The hub closes at 08:00 PM on Saturday for stock-taking.",
                           createdAt: ago(5 * day), read: true),
            V2Notification(id: 110, severity: .medium, kind: .notification,
                           subject: "Shift ended automatically",
                           body: "Your shift ended at midnight because you didn't clock out. Talk to your supervisor if this is wrong.",
                           createdAt: ago(9 * day), read: true, target: .shift),
            V2Notification(id: 111, severity: .low, kind: .notification,
                           subject: "App updated",
                           body: "Version 2.4.1 is installed. Scanning is faster at stops with many units.",
                           createdAt: ago(12 * day), read: true),
            V2Notification(id: 112, severity: .high, kind: .alert,
                           subject: "Delivery cancelled at stop 3",
                           body: "Order IKEA-UK-2026-00098712 for Anil Kumar was cancelled by dispatch. You handed it back at the hub.",
                           createdAt: ago(15 * day), read: true),
        ]
    }
}

// MARK: App-bar entry, provided through the environment

/// What an app bar needs to show the inbox entry. Absent → no bell (pages outside the signed-in flow).
struct V2InboxEntry {
    var unread: Int
    var open: () -> Void
}

private struct V2InboxEntryKey: EnvironmentKey { static let defaultValue: V2InboxEntry? = nil }
extension EnvironmentValues {
    var v2InboxEntry: V2InboxEntry? {
        get { self[V2InboxEntryKey.self] }
        set { self[V2InboxEntryKey.self] = newValue }
    }
}

// MARK: Count badge — Figma's applied-filter badge, reused for the bell's unread count

struct V2CountBadge: View {
    let count: Int
    var body: some View {
        Text(count > 9 ? "9+" : "\(count)")
            .font(.custom(V2Font.label2.fontName, size: 10))
            .foregroundColor(HFColor.onPrimary)
            .padding(.horizontal, 3)
            .frame(minWidth: 16, minHeight: 16)
            .background(RoundedRectangle(cornerRadius: 4).fill(HFColor.primary))
    }
}

/// Inbox entry on the app bar: bell + unread count; no badge at zero (AC-7).
struct V2BellButton: View {
    let unread: Int
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            EncoreIcon(iconName: "LNotificationsOutlined", size: V2Icon.bar)
                .foregroundColor(V2Token.actionActive)
                .frame(width: V2Metrics.touchTarget, height: V2Metrics.touchTarget)
                .overlay(alignment: .topTrailing) {
                    if unread > 0 { V2CountBadge(count: unread).offset(x: -6, y: 8) }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(unread > 0 ? "Notifications, \(unread) unread" : "Notifications")
    }
}
