import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - DP-2959 Notification priority tiering
//
// While the app is open, a notification interrupts according to the severity the PLATFORM set on the
// worker's inbox entry (`notificationInbox.severity`, Story 5.4.3). The app never assigns or overrides
// it; anything missing or unrecognised is LOW (AC-5), so a guess never outranks a chosen severity.
//
//   CRITICAL, HIGH → takeover: centred dialog over a scrim (Figma's blocking-dialog pattern) until
//                    dismissed or tapped through. Two or more at once become one summary dialog that
//                    sends the rider to the inbox.
//   MEDIUM         → top banner (Figma's dismissible banner, info): slides down and stays until the
//                    rider closes it (✕) or taps through; several become one summary banner.
//   LOW            → nothing in the app; it waits in the inbox (DP-2956).
//
// Placement rule the boards already imply: bottom toast = feedback on what YOU just did; top banner =
// something happened TO you; centre dialog = you must respond. Notifications never use the toast.
//
// The entry mirrors `notificationInbox` field for field (subject, body, receivedAt, status, severity,
// type, deepLinkTarget) so the same shape can come straight from the server / SDUI.

enum V2Severity: String, CaseIterable {
    case critical = "CRITICAL", high = "HIGH", medium = "MEDIUM", low = "LOW"

    /// The platform's value, verbatim. Absent or unknown → LOW (Story 5.4.3 AC-5).
    init(platform raw: String?) {
        self = raw.flatMap { V2Severity(rawValue: $0.uppercased()) } ?? .low
    }

    enum Tier { case takeover, banner, silent }
    var tier: Tier {
        switch self {
        case .critical, .high: return .takeover
        case .medium:          return .banner
        case .low:             return .silent
        }
    }

    var label: String {
        switch self {
        case .critical: return "Critical"
        case .high:     return "High"
        case .medium:   return "Medium"
        case .low:      return "Low"
        }
    }

    /// Tone colour — the semantic MUI mains, the same ones the status banners use. Critical and high
    /// look the same to the rider (one red): both mean "deal with this now". The platform keeps them
    /// apart for ordering (decided 2026-10-20; the brief leaves it to design).
    var tone: Color {
        switch self {
        case .critical, .high: return Color.encore("Error/Main")  // #B50000
        case .medium:   return Color.encore("Info/Main")       // #0188CC
        case .low:      return HFColor.textSecondary
        }
    }

    /// Inbox chip — tinted + outlined like the SLA chip (severity is an attribute, not a lifecycle
    /// state, so it doesn't take the filled status-chip look). Hues follow the web inbox
    /// (destructive / warning / caution / muted), so MEDIUM is amber there, not the info blue the
    /// banner uses.
    var chipBg: Color {
        switch self {
        case .critical: return Color.encore("Red/50")
        case .high:     return Color.encore("Orange/50")
        case .medium:   return Color.encore("Yellow/50")
        case .low:      return Color.encore("Grey/100")
        }
    }
    var chipStroke: Color {
        switch self {
        case .critical: return Color.encore("Red/500")
        case .high:     return Color.encore("Orange/500")
        case .medium:   return Color.encore("Yellow/500")
        case .low:      return Color.encore("Grey/400")
        }
    }

    var icon: String {
        switch self {
        case .critical, .high: return "LError"
        case .medium, .low:    return "LInfo"
        }
    }
}

enum V2NotificationKind: String {
    case alert = "ALERT", notification = "NOTIFICATION"
    var label: String { self == .alert ? "Alert" : "Notification" }
}

/// `deepLinkTarget` — what tapping through opens. Names entities by id, like routes do.
enum V2NotificationTarget: Equatable {
    case none, shift, trip, stop(Int), task(stop: Int, task: Int)

    var openLabel: String {
        switch self {
        case .none:  return "Got it"
        case .shift: return "View shift"
        case .trip:  return "View trip"
        case .stop:  return "View stop"
        case .task:  return "View task"
        }
    }

    var noun: String {
        switch self {
        case .none, .shift: return "shift"
        case .trip:         return "trip"
        case .stop:         return "stop"
        case .task:         return "task"
        }
    }
}

struct V2Notification: Identifiable, Equatable {
    let id: Int
    var severity: V2Severity
    var kind: V2NotificationKind
    var subject: String
    var body: String
    /// The entity's `createdAt` (the story says `receivedAt`; the entity and the web inbox use
    /// `createdAt` — open question for the dev team).
    var createdAt: Date = Date()
    var read: Bool = false
    var target: V2NotificationTarget = .none
    /// The target no longer exists or is no longer this worker's (reassigned). The entry stays.
    var targetGone: Bool = false
    /// The notification announces a STATUS change of its target (cancelled, failed, skipped). The
    /// item's own chip + reason already say so, so no context notice repeats it (decided 2026-10-26).
    /// The platform would derive this from the event behind the push.
    var statusChange: Bool = false
}

/// Holds the inbox entries and decides what is on screen. Surfaces only render what it says.
final class V2NotificationCenter: ObservableObject {
    @Published private(set) var entries: [V2Notification] = []
    /// The critical / high ones waiting to be answered, oldest first. One → its own dialog; two or
    /// more → the summary. A new one joins the summary (its count goes up), never a second dialog.
    @Published private(set) var takeovers: [Int] = []
    var takeover: Int? { takeovers.count == 1 ? takeovers.first : nil }
    /// The medium banners waiting to be answered, oldest first. One → its own banner; two or more → the
    /// summary banner. They stay until the rider answers them (✕ or tap) — never on a timer (decided
    /// 2026-10-20; the brief says "goes on its own after a few seconds").
    @Published private(set) var banners: [Int] = []
    var banner: Int? { banners.count == 1 ? banners.first : nil }
    /// Banners wait out of sight while a takeover is up or the camera is open, then come back.
    var bannerShowing: Bool { !banners.isEmpty && takeovers.isEmpty && !holdsBanners }
    /// Notices the rider closed on the page they are about (context notices, below).
    @Published private(set) var noticeClosed: Set<Int> = []
    /// The inbox is online-only (Story 5.4.5 AC-8). Prototype toggle from the push panel.
    @Published var offline = false {
        didSet {
            guard oldValue != offline else { return }
            reconnectWork?.cancel()
            if offline { reconnected = false; return }
            // Back online: the green strip takes the offline strip's place, then goes on its own.
            reconnected = true
            let work = DispatchWorkItem { [weak self] in withAnimation(V2Motion.reflow) { self?.reconnected = false } }
            reconnectWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.reconnectedDwell, execute: work)
        }
    }
    /// The moment after the connection returns ("Refreshed", Figma › Offline (no connection)).
    @Published private(set) var reconnected = false
    private var reconnectWork: DispatchWorkItem? = nil
    static let reconnectedDwell: TimeInterval = 2.5
    /// Either network strip is showing — fixed-height sheets give it room.
    var showsNetworkAlert: Bool { offline || reconnected }

    /// The camera is open. A scan is a workflow: a medium waits for the rider to come back out to the
    /// Scan HUs page and slides in there, rather than landing on the viewfinder.
    @Published private(set) var holdsBanners = false
    private var nextId = 1

    var unread: Int { entries.filter { !$0.read }.count }
    func entry(_ id: Int?) -> V2Notification? { id.flatMap { i in entries.first { $0.id == i } } }

    // MARK: Arrival

    /// History that was already in the inbox before this session — no surfacing, just entries.
    func seed(_ history: [V2Notification]) {
        guard entries.isEmpty else { return }
        entries = history.sorted { $0.createdAt > $1.createdAt }
        nextId = (entries.map(\.id).max() ?? 0) + 1
    }

    @discardableResult
    func receive(_ severity: V2Severity, _ kind: V2NotificationKind, subject: String, body: String,
                 target: V2NotificationTarget = .none, targetGone: Bool = false,
                 statusChange: Bool = false, surface: Bool = true) -> Int {
        let id = nextId
        nextId += 1
        // An open inbox makes room for it rather than cutting it in.
        withAnimation(V2Motion.reflow) {
            entries.insert(V2Notification(id: id, severity: severity, kind: kind, subject: subject, body: body,
                                          target: target, targetGone: targetGone,
                                          statusChange: statusChange), at: 0)
        }
        // Arrived while the app was closed: the phone showed it; in the app it is only an entry.
        guard surface else { return id }
        withAnimation(severity.tier == .banner ? V2Motion.reflow : V2Motion.surface) {
            switch severity.tier {
            case .takeover:
                takeovers.append(id)
            case .banner:
                banners.append(id)
            case .silent:
                break
            }
        }
        return id
    }

    // MARK: Takeover

    /// A single one, dismissed or tapped through: the entry turns read (Story 5.4.3 AC-7).
    @discardableResult
    func closeTakeover() -> V2Notification? {
        guard let id = takeover else { return nil }
        markRead([id])
        let closed = entry(id)
        withAnimation(V2Motion.surface) { takeovers = [] }
        return closed
    }

    /// The summary, answered. "Dismiss" marks them all read (the brief: dismissing marks read);
    /// "Open notifications" leaves them unread for the inbox.
    func closeSummary(read: Bool) {
        if read { markRead(takeovers) }
        withAnimation(V2Motion.surface) { takeovers = [] }
    }

    /// Camera opened / closed. Banners already up go out of sight and come back on Scan HUs.
    func holdBanners(_ on: Bool) {
        guard on != holdsBanners else { return }
        withAnimation(V2Motion.reflow) { holdsBanners = on }
    }

    // MARK: Banner

    /// Tap through one banner: opens what it's about, and the entry turns read.
    @discardableResult
    func tapBanner() -> V2Notification? {
        guard let id = banner else { return nil }
        markRead([id])
        withAnimation(V2Motion.reflow) { banners = [] }
        return entry(id)
    }

    /// The summary banner's "Open notifications": off to the inbox, where they stay unread.
    func openBanners() {
        withAnimation(V2Motion.reflow) { banners = [] }
    }

    /// ✕ or flicked away: a dismiss, so every entry it stood for turns read (the brief).
    func dismissBanner() {
        markRead(banners)
        withAnimation(V2Motion.reflow) { banners = [] }
    }

    // MARK: Context notices

    func closeNotice(_ id: Int) {
        withAnimation(V2Motion.reflow) { _ = noticeClosed.insert(id) }
    }

    // MARK: Read state

    /// Animated: in the Unread tab a row that turns read glides out and the rows below close up.
    func markRead(_ ids: [Int], _ read: Bool = true) {
        withAnimation(V2Motion.reflow) {
            for i in entries.indices where ids.contains(entries[i].id) { entries[i].read = read }
        }
    }

    func clear() { entries = [] }

    func markAllRead() { markRead(entries.filter { !$0.read }.map(\.id)) }
}

// MARK: - Surfaces

/// Everything a notification puts on screen, as one overlay at the flow root (above sheets, covers
/// and the scanner — Story 5.4.3: an important one shows even over another modal).
struct V2NotificationLayer: View {
    @ObservedObject var center: V2NotificationCenter
    var onOpen: (V2Notification) -> Void
    /// The summary's "View all": the inbox, on its Unread tab.
    var onViewAll: () -> Void = {}

    var body: some View {
        ZStack(alignment: .top) {
            // The medium banner is not drawn here: it lives in the page, under the app bar / navbar
            // (`V2BannerSlot`), so the page moves down by its height.
            if !center.takeovers.isEmpty {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        // The scrim swallows taps: an important one is answered, not tapped away.
                        .onTapGesture {}
                    V2NotificationTakeover(notes: center.takeovers.compactMap { center.entry($0) },
                                           onOpen: {
                                               if let n = center.closeTakeover(), n.target != .none { onOpen(n) }
                                           },
                                           onDismiss: { center.closeTakeover() },
                                           onViewAll: { center.closeSummary(read: false); onViewAll() },
                                           onLater: { center.closeSummary(read: true) })
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        .padding(.horizontal, Spacing.spacing16)
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: Network alert — above every app bar

/// The connectivity strip (Auth + Home + Profile › "Offline (no connection)"): warning fill that runs
/// up through the status bar, then "Offline · Last synced" — above the app bar, so every page moves
/// down by it. App-wide state, not a notification and not part of any page.
private struct V2NetworkInsetKey: EnvironmentKey { static let defaultValue: CGFloat = 0 }
extension EnvironmentValues {
    /// Height the network alert takes above the app (0 when online). Fixed-height sheets subtract it.
    var v2NetworkInset: CGFloat {
        get { self[V2NetworkInsetKey.self] }
        set { self[V2NetworkInsetKey.self] = newValue }
    }
}

struct V2NetworkAlert: View {
    static let height: CGFloat = 40
    @ObservedObject var center: V2NotificationCenter
    var lastSynced = "08:16"
    var body: some View {
        VStack(spacing: 0) {
            if center.offline {
                HFOfflineBanner(lastSynced: lastSynced)
                    .transition(.move(edge: .top))
            } else if center.reconnected {
                // Same slot and metrics as the offline strip, success fill — the two swap in place
                // rather than one leaving and another arriving.
                HFBanner(role: .network, title: "Refreshed", icon: "LCheckCircleFilled", fill: HFColor.success)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(V2Motion.reflow, value: center.offline)
        .animation(V2Motion.reflow, value: center.reconnected)
    }
}

// MARK: Banner slot — the medium banner as part of the page

/// What a bar needs to host the medium banner. Injected at the flow root; absent → no slot.
struct V2BannerContext {
    let center: V2NotificationCenter
    var onOpen: (V2Notification) -> Void
    /// The inbox, on its Unread tab (summary banner, a notice's "+n more").
    var onViewAll: () -> Void = {}
}

private struct V2BannerContextKey: EnvironmentKey { static let defaultValue: V2BannerContext? = nil }
extension EnvironmentValues {
    var v2Banner: V2BannerContext? {
        get { self[V2BannerContextKey.self] }
        set { self[V2BannerContextKey.self] = newValue }
    }
}

/// Sits under every app bar and navbar. Home's banners push the page down ("Your shifts" starts below
/// "Pre shift end"), so this one takes real height: the content beneath moves down by exactly the
/// banner's height, and back up as it leaves. Clipped so it slides out from under the bar.
struct V2BannerSlot: View {
    @Environment(\.v2Banner) private var context
    var body: some View {
        if let context { V2BannerSlotBody(center: context.center, onOpen: context.onOpen, onViewAll: context.onViewAll) }
    }
}

private struct V2BannerSlotBody: View {
    @ObservedObject var center: V2NotificationCenter
    var onOpen: (V2Notification) -> Void
    var onViewAll: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            if center.bannerShowing {
                Group {
                    if center.banners.count > 1 {
                        V2NotificationBanner(icon: V2Severity.medium.icon, tone: V2Severity.medium.tone,
                                             title: "\(center.banners.count) new notifications",
                                             message: "Open to see what needs your attention",
                                             link: "Open notifications",
                                             onLink: { center.openBanners(); onViewAll() },
                                             onDismiss: { center.dismissBanner() })
                    } else if let n = center.entry(center.banner) {
                        V2NotificationBanner(icon: n.severity.icon, tone: n.severity.tone,
                                             title: n.subject, message: n.body,
                                             link: n.target == .none ? nil : n.target.openLabel,
                                             onLink: { if let n = center.tapBanner() { onOpen(n) } },
                                             onDismiss: { center.dismissBanner() })
                    }
                }
                .id(center.banners.count > 1)
                    // Slides out from under the bar as its slot opens; the page below follows (reflow).
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .animation(V2Motion.reflow, value: center.bannerShowing)
        .animation(V2Motion.standard, value: center.banners.count > 1)
    }
}

/// Critical / high — Figma's blocking dialog (Auth + Home + Profile: "Setup biometric", "Update - soft
/// block"): 328 wide, r12 (Figma r8 — see below); tinted pill icon chip; h5 title; body1 secondary; then the actions on their
/// own white block with an E1 shadow as the separator (no rule); primary on top, grey text below.
/// Tone lives in the icon chip only — no eyebrow, never in the buttons.
///
/// Two or more at once: the same dialog as a summary — "3 urgent notifications", "Open notifications"
/// (the inbox, Unread tab) over "Dismiss" (marks them read, as a single one's Dismiss does). The chip takes the most severe one's tone. A single dialog that
/// a second one joins dissolves into the summary in place (decided 2026-10-19, after a swipeable
/// carousel and a pager both read badly with alerts of different lengths).
struct V2NotificationTakeover: View {
    let notes: [V2Notification]
    var onOpen: () -> Void
    var onDismiss: () -> Void
    var onViewAll: () -> Void
    var onLater: () -> Void

    /// Taps are ignored for a moment after it appears — and again when it turns into the summary, since
    /// its buttons change under a finger that may be on its way to them. A notification can land
    /// mid-swipe or mid-scan; without this the driver's finger, already moving, answers it by accident.
    @State private var armed = false
    static let armDelay: TimeInterval = 0.6

    private var isSummary: Bool { notes.count > 1 }
    private var severity: V2Severity {
        notes.contains { $0.severity == .critical } ? .critical : (notes.first?.severity ?? .high)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if isSummary {
                    // Named as the inbox is ("Notifications"), "urgent" says why it interrupted, and the
                    // body says what opening it shows.
                    message(title: "\(notes.count) urgent notifications",
                            body: "Open to see what needs your attention")
                } else if let note = notes.first {
                    // The message is never cut short (DP-2956 rows say the same of the inbox).
                    message(title: note.subject, body: note.body)
                }
            }
            .id(isSummary)
            .transition(Self.swap)

            Group {
                if isSummary {
                    actions(primary: "Open notifications", primaryAction: onViewAll, secondary: "Dismiss", secondaryAction: onLater)
                } else if let note = notes.first {
                    actions(primary: note.target.openLabel,
                            primaryAction: note.target == .none ? onDismiss : onOpen,
                            secondary: note.target == .none ? nil : "Dismiss", secondaryAction: onDismiss)
                }
            }
            .id(isSummary)
            .transition(Self.swap)
            .padding(Spacing.spacing16)
            .frame(maxWidth: .infinity)
            .background(
                Rectangle()
                    .fill(HFColor.surface)
                    .shadow(color: Color(.sRGB, red: 17/255, green: 19/255, blue: 24/255, opacity: 0.16),
                            radius: 2, x: 0, y: 0)
            )
            .allowsHitTesting(armed)
        }
        .background(HFColor.surface)
        // r12, not Figma's 8: the container family (sheets, result card, menu) is 12, and a step above
        // the r8 buttons keeps the card reading as the outer shape. Logged in figma-discrepancies.md.
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: 328)
        .animation(V2Motion.standard, value: isSummary)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .onAppear(perform: arm)
        .onChange(of: isSummary) { _ in arm() }
    }

    /// Single → summary: the old words leave before the new arrive, so the two never print over each other.
    static let swap: AnyTransition = .asymmetric(
        insertion: .opacity.animation(.easeInOut(duration: 0.16).delay(0.1)),
        removal: .opacity.animation(.easeOut(duration: 0.1)))

    private func arm() {
        armed = false
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.armDelay) { armed = true }
    }

    private func message(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.spacing16) {
            EncoreIcon(iconName: severity.icon, size: 20)
                .foregroundColor(severity.tone)
                .frame(width: 52, height: 36)
                .background(Capsule().fill(severity.tone.opacity(0.08)))
            VStack(alignment: .leading, spacing: Spacing.spacing4) {
                Text(title)
                    .v2Text(V2Font.h5)
                    .foregroundColor(HFColor.textPrimary)
                Text(body)
                    .v2Text(V2Font.body1)
                    .foregroundColor(HFColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.spacing16)
    }

    private func actions(primary: String, primaryAction: @escaping () -> Void,
                         secondary: String?, secondaryAction: @escaping () -> Void) -> some View {
        VStack(spacing: Spacing.spacing8) {
            V2Button(label: primary, action: primaryAction)
            if let secondary {
                V2Button(label: secondary, role: .text, action: secondaryAction)
            }
        }
    }
}

/// Medium — Home's in-page banner (Auth + Home + Profile: "Pre shift end", "Approaching-end reminder"):
/// full width directly under the app bar, info fill, 20 filled icon centred, white 14/20 text (subject
/// Medium, message Regular, up to two lines), ✕ in a 48 at the right. The full-bleed strip under the
/// status bar is the network alert's, not this.
///
/// Stays until answered (decided 2026-10-20), so it ALWAYS has the ✕. When there is somewhere to go, the
/// `<Alert>` text action ("View stop", "Open notifications") sits on its own line under the message —
/// Figma's "Sync pending" puts the action IN the ✕'s place; both together is new (figma-discrepancies.md).
/// Tapping the body does what the action does. Flick up = ✕.
struct V2NotificationBanner: View {
    var icon: String
    var tone: Color
    var title: String
    var message: String
    var link: String?
    var onLink: () -> Void
    var onDismiss: () -> Void

    @State private var drag: CGFloat = 0

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.spacing12) {
            EncoreIcon(iconName: icon, size: 20)
                .foregroundColor(HFColor.onPrimary)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .v2Label(V2Font.label1)
                Text(message)
                    .v2Text(V2Font.body1)
                    .opacity(0.9)
                    .lineLimit(2)
                if let link {
                    // `<Alert>` action (Session pre-expiry "Continue"): text button, SemiBold 14/24,
                    // underlined, white.
                    Button(action: onLink) {
                        Text(link)
                            .v2Label(V2Font.buttonMedium)
                            .underline()
                            .frame(minHeight: 32, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .foregroundColor(HFColor.onPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                EncoreIcon(iconName: "LCross", size: 24)
                    .foregroundColor(HFColor.onPrimary)
                    .frame(width: V2Metrics.touchTarget, height: V2Metrics.touchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(.leading, Spacing.spacing16)
        .padding(.trailing, Spacing.spacing4)
        .padding(.vertical, Spacing.spacing8)
        .frame(minHeight: V2Metrics.touchTarget)
        .background(tone)
        .contentShape(Rectangle())
        .onTapGesture { if link != nil { onLink() } }
        .offset(y: min(0, drag))
        .gesture(DragGesture(minimumDistance: 8)
            .onChanged { drag = $0.translation.height }
            .onEnded { v in
                if v.translation.height < -24 { onDismiss() }
                withAnimation(V2Motion.standard) { drag = 0 }
            })
    }
}

// MARK: Context notice — on the page a notification is about

/// Lands the rider on a stop / task / trip / Home and says WHY they might be here: today's notifications
/// about THIS page — its own level only (a task's notification sits on the task page; the stop shows
/// that task's state on its card, not a notice) — whether they came through the alert or found the page.
/// Only for changes that aren't a status: a cancelled / failed / skipped item says so in its own chip +
/// reason, so status-change notifications never make a notice (decided 2026-10-26). Figma's
/// inline card alert (frame 45's instruction banner, family 4): tinted, under the page header, part of
/// the content. Red for critical / high, blue otherwise. The newest shows; "+n more" goes to the inbox.
/// ✕ hides it on this page; it doesn't change read state (the brief: only tapping through, dismissing,
/// a row or a mark action do).
struct V2NotificationNotice: View {
    /// Which targets count as this page (a stop page also takes its tasks' notifications).
    let about: (V2NotificationTarget) -> Bool
    /// Space around it when it shows — none when there's nothing to say, so the page is unchanged.
    var insets = EdgeInsets()
    @Environment(\.v2Banner) private var context
    var body: some View {
        if let context {
            V2NoticeBody(center: context.center, about: about, insets: insets, onViewAll: context.onViewAll)
        }
    }
}

private struct V2NoticeBody: View {
    @ObservedObject var center: V2NotificationCenter
    let about: (V2NotificationTarget) -> Bool
    var insets: EdgeInsets
    var onViewAll: () -> Void

    private var matches: [V2Notification] {
        center.entries.filter {
            // Not while its own banner or dialog is still up — it would say the same thing twice.
            about($0.target) && !$0.targetGone && !$0.statusChange && !center.noticeClosed.contains($0.id)
                && !center.banners.contains($0.id) && !center.takeovers.contains($0.id)
                && Calendar.current.isDateInToday($0.createdAt)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let n = matches.first {
                V2InstructionBanner(title: n.subject, text: n.body,
                                    tone: n.severity.tier == .takeover ? .error : .info,
                                    link: matches.count > 1 ? ("+\(matches.count - 1) more", onViewAll) : nil,
                                    onClose: { center.closeNotice(n.id) })
                    .padding(insets)
                    .id(n.id)
                    .transition(V2Motion.dissolve)
            }
        }
        .animation(V2Motion.reflow, value: matches.first?.id)
    }
}

// MARK: - Prototype push trigger
//
// Stands in for the platform. Shake the simulator (Device › Shake, ⌃⌘Z) for the push panel, or launch
// with SIMCTL_CHILD_POC_PUSH=critical,high,medium (fired ~1.5 s after launch, 0.4 s apart).

extension Notification.Name {
    static let v2DeviceShaken = Notification.Name("v2DeviceShaken")
}

#if canImport(UIKit)
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake { NotificationCenter.default.post(name: .v2DeviceShaken, object: nil) }
    }
}
#endif

/// The kinds of push the panel can fire — written against the seeded trip so targets are real.
enum V2PushSample: String, CaseIterable, Identifiable {
    case critical, high, medium, low, gone, pair, trio, mediumPair, lastTask, stopSkipped, connection, criticalInfo, mediumInfo, tray
    var id: String { rawValue }

    var title: String {
        switch self {
        case .critical: return "Critical · task cancelled"
        case .high:     return "High · stop window changed"
        case .medium:   return "Medium · shift ending"
        case .mediumPair: return "Two medium at once"
        case .lastTask:   return "Last task at stop 3 cancelled (stop → Skipped)"
        case .stopSkipped: return "Dispatch skipped stop 4 (tasks → Cancelled)"
        case .low:      return "Low · hub message"
        case .gone:     return "High · trip reassigned (target gone)"
        case .pair:     return "Two important at once"
        case .trio:     return "Three important at once (one with nothing to open)"
        case .connection: return "Lose / restore the connection"
        case .criticalInfo: return "Critical · nothing to open"
        case .mediumInfo:   return "Medium · nothing to open"
        case .tray:         return "Tap it in the phone's tray (app was closed)"
        }
    }
}

/// Bottom-sheet panel opened by shaking the device. Not part of the product.
struct V2PushPanel: View {
    var onFire: (V2PushSample) -> Void
    var onJump: (String) -> Void = { _ in }
    var onClose: () -> Void

    /// Every demo state worth visiting for DP-2959 / DP-2956, grouped. "" = the full app from splash.
    static let states: [(group: String, items: [(key: String, title: String)])] = [
        ("App", [("", "Full app from splash"), ("home", "Home"), ("clockedin", "Home, clocked in"), ("badge-many", "Home, 120 unread (99+)")]),
        ("Inbox", [("inbox", "All"), ("inbox-unread", "Unread tab"),
                   ("inbox-caughtup", "Unread tab, nothing unread"), ("inbox-filter", "Filter sheet"),
                   ("inbox-nomatch", "Filter applied, no match"), ("inbox-select", "Selecting, some unread"),
                   ("inbox-select-read", "Selecting, all read"), ("inbox-swipe-read", "Swipe on unread"),
                   ("inbox-swipe-unread", "Swipe on read"), ("inbox-menu", "Row menu"),
                   ("inbox-offline", "No connection"), ("inbox-empty", "Empty"),
                   ("inbox-filter-type", "Filter sheet, Type"), ("inbox-collapsed", "Day section collapsed"),
                   ("inbox-paging", "Loading more")]),
        ("Acting on one", [("notif-pair", "Two important at once → summary"), ("notif-trio", "One, then two more join → summary"), ("notif-viewall", "Summary → Open notifications"), ("notif-banners", "Two medium → summary banner"), ("notif-notice", "Cancelled, dismissed, then open stop 3"), ("notif-cascade", "Last task cancelled → stop Skipped"), ("notif-skip", "Stop skipped → its tasks Cancelled"), ("notif-viewtask", "Takeover → View task (task shows Cancelled)"), ("notif-open", "Inbox row → its stop"),
                           ("notif-gone", "Row whose trip is gone → toast"), ("notif-tray", "Opened from the phone's tray")]),
        ("Workflow (for pushes on top)", [("stop", "Stop sheet"), ("scan", "Scan HUs"), ("scanner", "Scanner (camera)")]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HFSheetTitle(title: "Prototype", onClose: onClose)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.spacing8) {
                    header("Simulate a push")
                    ForEach(V2PushSample.allCases) { s in row(s.title) { onFire(s) } }
                    ForEach(Self.states, id: \.group) { g in
                        header("Go to · \(g.group)")
                        ForEach(g.items, id: \.key) { item in row(item.title) { onJump(item.key) } }
                    }
                }
                .padding(Spacing.spacing16)
            }
            .frame(maxHeight: 520)
            HFSheetBottomInset()
        }
    }

    private func header(_ text: String) -> some View {
        Text(text.uppercased())
            .v2Label(V2Font.overline2)
            .foregroundColor(HFColor.textSecondary)
            .padding(.top, Spacing.spacing8)
    }

    private func row(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .v2Label(V2Font.label1)
                .foregroundColor(HFColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.spacing16)
                .frame(height: V2Metrics.touchTarget)
                .background(RoundedRectangle(cornerRadius: 8).fill(HFColor.screen))
        }
        .buttonStyle(.plain)
    }
}

// MARK: Playground — the app's own "localhost"

/// Jump to another demo state from inside the app: rebuilds the whole flow fresh (as a relaunch would).
private struct V2JumpKey: EnvironmentKey { static let defaultValue: ((String) -> Void)? = nil }
extension EnvironmentValues {
    var v2Jump: ((String) -> Void)? {
        get { self[V2JumpKey.self] }
        set { self[V2JumpKey.self] = newValue }
    }
}

/// Wraps the flow so a state picked in the shake panel restarts it there. Launch state still comes
/// from POC_STATE; after that, everything is reachable from the panel.
public struct V2Playground: View {
    @State private var demo: String
    public init(demo: String = "") { _demo = State(initialValue: demo) }
    public var body: some View {
        V2Flow(demo: demo)
            .id(demo)
            .environment(\.v2Jump, { demo = $0 })
    }
}
