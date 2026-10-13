import SwiftUI

// MARK: - DP-2956 In-app notification inbox
//
// Split the way the dev team's SDUI stack splits (disco-mobile-workspace docs/sdui-framework.md):
//   • SDUI card  — the row CONTENT: `notification_list_card_v1`. One card per entry, evaluated against
//                  the entry + `now`. `V2NotificationRowVars` is that evaluation (the AppEvalex
//                  expressions); `V2NotificationRowCard` renders nothing but those variables.
//   • Native host — everything around it: navbar, bell + count, day-group headers, filter sheet,
//                  paging, swipe-to-read, long-press multi-select, mark-all, offline / empty /
//                  no-results states, and row tap → open target (same routing as a push tap).
// Keep that line when changing this file: if it needs a gesture, a list or a sheet, it's host chrome.

// MARK: SDUI card — notification_list_card_v1

/// The card's variables. Each is one expression over `notification` and `now`.
struct V2NotificationRowVars: Equatable {
    var subject: String
    var body: String
    var timeLabel: String
    var typeLabel: String
    var severityLabel: String
    var severityBg: Color
    var severityStroke: Color
    var isUnread: Bool
    /// Shown when the target is gone — "The row stays and says so" (DP-2956).
    var goneLabel: String?

    static func make(_ n: V2Notification, now: Date) -> Self {
        V2NotificationRowVars(subject: n.subject,
                              body: n.body,
                              timeLabel: V2Ago.label(n.createdAt, now: now),
                              typeLabel: n.kind.label,
                              severityLabel: n.severity.label,
                              severityBg: n.severity.chipBg,
                              severityStroke: n.severity.chipStroke,
                              isUnread: !n.read,
                              goneLabel: n.targetGone ? "This \(n.target.noun) is no longer available" : nil)
    }
}

/// Unread = primary tint + SemiBold subject; read = white + Medium subject, secondary message. No
/// dot — the web inbox dropped it as too small, and the shade is what both surfaces share.
struct V2NotificationRowCard: View {
    let vars: V2NotificationRowVars

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing4) {
            HStack(spacing: Spacing.spacing8) {
                Text(vars.severityLabel)
                    .typography(HFType.badge12)
                    .foregroundColor(HFColor.textPrimary)
                    .padding(.horizontal, 6)
                    .frame(height: V2Metrics.chip)
                    .background(vars.severityBg)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(vars.severityStroke, lineWidth: V2Space.hairline))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Text(vars.typeLabel.uppercased())
                    .v2Label(V2Font.overline2)
                    .foregroundColor(HFColor.textSecondary)
                Spacer(minLength: 0)
                Text(vars.timeLabel)
                    .v2Label(V2Font.label2)
                    .foregroundColor(HFColor.textSecondary)
            }
            .padding(.bottom, Spacing.spacing4)
            Text(vars.subject)
                .v2Text(vars.isUnread ? V2Font.cardTitle : V2Font.label1)
                .foregroundColor(HFColor.textPrimary)
            // Never cut short (AC-3).
            Text(vars.body)
                .v2Text(V2Font.body1)
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
        }
        .padding(Spacing.spacing16)
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

struct V2InboxFilter: Equatable {
    enum Status: String, CaseIterable { case unread = "Unread", read = "Read" }
    var status: Set<Status> = []
    var kind: Set<V2NotificationKind> = []
    var severity: Set<V2Severity> = []

    var count: Int { status.count + kind.count + severity.count }
    var isEmpty: Bool { count == 0 }

    /// Empty set = no constraint on that facet.
    func matches(_ n: V2Notification) -> Bool {
        (status.isEmpty || status.contains(n.read ? .read : .unread))
            && (kind.isEmpty || kind.contains(n.kind))
            && (severity.isEmpty || severity.contains(n.severity))
    }
}

/// Figma's list filter sheet (Trip + Search › Search and filter): category rail on the left,
/// checkboxes with counts on the right, Apply (enabled once something changed) + Reset all.
struct V2InboxFilterSheet: View {
    let entries: [V2Notification]
    let applied: V2InboxFilter
    var onApply: (V2InboxFilter) -> Void
    var onClose: () -> Void

    enum Facet: String, CaseIterable { case status = "Status", type = "Type", severity = "Severity" }
    @State private var facet: Facet = .status
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
                    V2Button(label: "Reset all", role: .text, enabled: !draft.isEmpty) { draft = V2InboxFilter() }
                }
            }
        }
        .onAppear { draft = applied }
    }

    private func picked(_ f: Facet) -> Int {
        switch f {
        case .status:   return draft.status.count
        case .type:     return draft.kind.count
        case .severity: return draft.severity.count
        }
    }

    private struct Option { let label: String; let count: Int; let on: Bool; let toggle: () -> Void }

    private var options: [Option] {
        switch facet {
        case .status:
            return V2InboxFilter.Status.allCases.map { s in
                Option(label: s.rawValue,
                       count: entries.filter { ($0.read ? .read : .unread) == s }.count,
                       on: draft.status.contains(s),
                       toggle: { draft.status.formSymmetricDifference([s]) })
            }
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

    @Environment(\.hfToast) private var toast
    /// Paging: the first page, then one more each time the end of the list comes into view.
    @State private var shown = Self.pageSize
    @State private var loadingMore = false
    @State private var selecting: Set<Int>? = nil
    @State private var swiping: (id: Int, dx: CGFloat)? = nil
    static let pageSize = 8

    private var now: Date { Date() }
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
            } else if matching.isEmpty {
                state(title: "No results found", body: "Try adjusting or clearing your filters",
                      action: ("Reset all", onResetFilter))
            } else {
                list
            }
            if let selecting {
                HFSheetFooter {
                    HStack(spacing: Spacing.spacing8) {
                        V2Button(label: "Mark unread", role: .text, enabled: !selecting.isEmpty) {
                            finishSelection(read: false)
                        }
                        V2Button(label: "Mark read", enabled: !selecting.isEmpty) { finishSelection(read: true) }
                    }
                }
                .transition(.move(edge: .bottom))
            }
        }
        .background(HFColor.screen)
        .ignoresSafeArea(.container, edges: .bottom)
        .onChange(of: filter) { _ in shown = Self.pageSize }
    }

    // MARK: Navbar — back · title · filter (count badge); select mode swaps in ✕ · "n selected"

    @ViewBuilder private var navbar: some View {
        if let selecting {
            V2Navbar(back: { withAnimation(V2Motion.standard) { self.selecting = nil } },
                     backIcon: "LCross",
                     title: "\(selecting.count) selected")
        } else {
            V2Navbar(back: onBack,
                     title: "Notifications",
                     actions: center.offline || center.entries.isEmpty ? [] : [
                        V2NavAction(id: "filter", icon: "LFilterAlt",
                                    badge: filter.isEmpty ? nil : filter.count, action: onFilter)
                     ])
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

    // MARK: List

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if selecting == nil {
                    HStack {
                        Text(center.unread == 1 ? "1 unread" : "\(center.unread) unread")
                            .v2Label(V2Font.label2)
                            .foregroundColor(HFColor.textSecondary)
                        Spacer()
                        Button {
                            center.markAllRead()
                            toast?.show("All marked as read")
                        } label: {
                            Text("Mark all as read")
                                .v2Label(V2Font.label1)
                                .foregroundColor(center.unread == 0 ? HFColor.textSecondary.opacity(0.5) : HFColor.primary)
                                .frame(height: V2Metrics.touchTarget)
                        }
                        .buttonStyle(.plain)
                        .disabled(center.unread == 0)
                    }
                    .padding(.horizontal, V2Space.pageMargin)
                }
                ForEach(V2Ago.Group.allCases, id: \.self) { g in
                    let rows = visible.filter { V2Ago.group($0.createdAt, now: now) == g }
                    if !rows.isEmpty {
                        Text("\(g.title.uppercased()) (\(matching.filter { V2Ago.group($0.createdAt, now: now) == g }.count))")
                            .v2Label(V2Font.section)
                            .foregroundColor(HFColor.textSecondary)
                            .padding(.horizontal, V2Space.pageMargin)
                            .padding(.top, Spacing.spacing16)
                            .padding(.bottom, Spacing.spacing8)
                        VStack(spacing: Spacing.spacing8) {
                            ForEach(rows) { row($0) }
                        }
                        .padding(.horizontal, V2Space.pageMargin)
                    }
                }
                if shown < matching.count {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .onAppear(perform: loadMore)
                }
                Color.clear.frame(height: HFLayout.bottomInset + Spacing.spacing16)
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

    /// Host chrome around one SDUI row card: tint, swipe-to-toggle-read, long-press to select, tap.
    private func row(_ n: V2Notification) -> some View {
        let dx = swiping?.id == n.id ? swiping!.dx : 0
        let picked = selecting?.contains(n.id) ?? false
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

            HStack(spacing: 0) {
                if selecting != nil {
                    EncoreIcon(iconName: picked ? "LCheckboxFilled" : "LCheckboxBlank", size: 24)
                        .foregroundColor(picked ? HFColor.primary : V2Token.actionActive)
                        .padding(.leading, Spacing.spacing16)
                }
                V2NotificationRowCard(vars: .make(n, now: now))
            }
            .background(ZStack { HFColor.surface; HFColor.primary.opacity(n.read ? 0 : 0.04) })
            .offset(x: dx)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(picked ? HFColor.primary : HFColor.divider, lineWidth: picked ? 1 : V2Space.hairline))
        .contentShape(Rectangle())
        .onTapGesture {
            if selecting != nil {
                withAnimation(V2Motion.standard) { selecting?.formSymmetricDifference([n.id]) }
            } else {
                center.markRead([n.id])
                onOpen(n)
            }
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            guard selecting == nil else { return }
            withAnimation(V2Motion.standard) { selecting = [n.id] }
        }
        .simultaneousGesture(selecting != nil ? nil : DragGesture(minimumDistance: 12)
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

    private func finishSelection(read: Bool) {
        guard let ids = selecting, !ids.isEmpty else { return }
        center.markRead(Array(ids), read)
        withAnimation(V2Motion.standard) { selecting = nil }
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
            EncoreIcon(iconName: "LBell", size: V2Icon.bar)
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
