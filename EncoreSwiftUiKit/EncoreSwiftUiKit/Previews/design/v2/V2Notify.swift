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
//                    dismissed or tapped through. A second one waits behind it, with a marker.
//   MEDIUM         → top banner (Figma's dismissible banner, info): slides down, goes on its own,
//                    tappable.
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

    /// Tone colour — the semantic MUI mains, the same ones the status banners use.
    var tone: Color {
        switch self {
        case .critical: return Color.encore("Error/Main")      // #B50000
        case .high:     return HFColor.warning                   // #E65301
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
        case .critical: return "LError"
        case .high:     return "LWarning"
        case .medium, .low: return "LInfo"
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
    /// The thing it asked for is done (vehicle check passed, skip acknowledged). New data — the
    /// platform sends severity only; needed by the `actionRequired` variant.
    var resolved: Bool = false

    /// Critical / high that still needs the rider. Read ≠ resolved.
    var actionRequired: Bool { severity.tier == .takeover && !resolved && !targetGone }
}

/// Holds the inbox entries and decides what is on screen. Surfaces only render what it says.
final class V2NotificationCenter: ObservableObject {
    @Published private(set) var entries: [V2Notification] = []
    /// The critical / high on screen, and the ones waiting behind it (oldest first).
    @Published private(set) var takeover: Int? = nil
    @Published private(set) var queue: [Int] = []
    /// The medium banner on screen.
    @Published private(set) var banner: Int? = nil
    /// The inbox is online-only (Story 5.4.5 AC-8). Prototype toggle from the push panel.
    @Published var offline = false

    /// A medium that lands while a takeover is up waits for it to clear rather than sliding in under
    /// the scrim, where it would expire unseen. Only the newest waits — banners are moment-in-time.
    private var heldBanner: Int? = nil
    private var bannerTimer: DispatchWorkItem? = nil
    private var nextId = 1

    /// How long a medium banner stays before it goes on its own.
    static let bannerDwell: TimeInterval = 4

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
                 target: V2NotificationTarget = .none, targetGone: Bool = false) -> Int {
        let id = nextId
        nextId += 1
        entries.insert(V2Notification(id: id, severity: severity, kind: kind, subject: subject, body: body,
                                      target: target, targetGone: targetGone), at: 0)
        withAnimation(V2Motion.surface) {
            switch severity.tier {
            case .takeover:
                if takeover == nil { takeover = id } else { queue.append(id) }
            case .banner:
                if takeover == nil { showBanner(id) } else { heldBanner = id }
            case .silent:
                break
            }
        }
        return id
    }

    // MARK: Takeover

    /// Dismiss or tap through: either way the entry turns read (Story 5.4.3 AC-7), and the next one
    /// waiting takes its place.
    @discardableResult
    func closeTakeover() -> V2Notification? {
        guard let id = takeover else { return nil }
        markRead([id])
        let closed = entry(id)
        withAnimation(V2Motion.surface) {
            if queue.isEmpty {
                takeover = nil
            } else {
                takeover = queue.removeFirst()
            }
        }
        if takeover == nil, let held = heldBanner {
            heldBanner = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                withAnimation(V2Motion.surface) { self?.showBanner(held) }
            }
        }
        return closed
    }

    // MARK: Banner

    private func showBanner(_ id: Int) {
        bannerTimer?.cancel()
        banner = id
        let work = DispatchWorkItem { [weak self] in
            guard self?.banner == id else { return }
            withAnimation(V2Motion.surface) { self?.banner = nil }
        }
        bannerTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.bannerDwell, execute: work)
    }

    /// Tap: opens what it's about, and the entry turns read.
    @discardableResult
    func tapBanner() -> V2Notification? {
        guard let id = banner else { return nil }
        markRead([id])
        bannerTimer?.cancel()
        withAnimation(V2Motion.surface) { banner = nil }
        return entry(id)
    }

    /// ✕ or flicked away. The brief only reads the entry on tap-through or dismiss of an important
    /// one; a banner that leaves on its own stays unread in the inbox. An explicit ✕ is a dismiss.
    func dismissBanner() {
        guard let id = banner else { return }
        markRead([id])
        bannerTimer?.cancel()
        withAnimation(V2Motion.surface) { banner = nil }
    }

    // MARK: Read state

    func markRead(_ ids: [Int], _ read: Bool = true) {
        for i in entries.indices where ids.contains(entries[i].id) { entries[i].read = read }
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

    var body: some View {
        ZStack(alignment: .top) {
            if let n = center.entry(center.banner) {
                V2NotificationBanner(note: n,
                                     onTap: { if let n = center.tapBanner() { onOpen(n) } },
                                     onDismiss: { center.dismissBanner() })
                    .transition(.move(edge: .top))
                    .zIndex(1)
            }
            if let n = center.entry(center.takeover) {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        // The scrim swallows taps: an important one is answered, not tapped away.
                        .onTapGesture {}
                    V2NotificationTakeover(note: n,
                                           waiting: center.queue.count,
                                           onOpen: {
                                               if let n = center.closeTakeover(), n.target != .none { onOpen(n) }
                                           },
                                           onDismiss: { center.closeTakeover() })
                        .id(n.id)
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

/// Critical / high — Figma's blocking dialog (Home › Edge cases, e.g. "You missed the shift"):
/// 328 wide, r8; tinted icon chip; h5 title; body1 secondary; divider; actions. Tone lives in the icon
/// chip and the eyebrow, never in the buttons.
struct V2NotificationTakeover: View {
    let note: V2Notification
    var waiting: Int
    var onOpen: () -> Void
    var onDismiss: () -> Void

    /// Taps are ignored for a moment after it appears. A notification can land mid-swipe or mid-scan;
    /// without this the driver's finger, already moving, answers it by accident.
    @State private var armed = false
    static let armDelay: TimeInterval = 0.6

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.spacing16) {
                HStack(alignment: .center) {
                    EncoreIcon(iconName: note.severity.icon, size: 20)
                        .foregroundColor(note.severity.tone)
                        .frame(width: 52, height: 36)
                        .background(Capsule().fill(note.severity.tone.opacity(0.08)))
                    Spacer()
                    if waiting > 0 {
                        Text("\(waiting) more waiting")
                            .v2Label(V2Font.label2)
                            .foregroundColor(HFColor.textSecondary)
                            .padding(.horizontal, Spacing.spacing8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(HFColor.screen))
                            .transition(.opacity)
                    }
                }
                VStack(alignment: .leading, spacing: Spacing.spacing4) {
                    Text("\(note.severity.label.uppercased()) · \(note.kind.label.uppercased())")
                        .v2Label(V2Font.overline2)
                        .foregroundColor(note.severity.tone)
                    Text(note.subject)
                        .v2Text(V2Font.h5)
                        .foregroundColor(HFColor.textPrimary)
                    // The message is never cut short (DP-2956 rows say the same of the inbox).
                    Text(note.body)
                        .v2Text(V2Font.body1)
                        .foregroundColor(HFColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Spacing.spacing16)

            Rectangle().fill(HFColor.divider).frame(height: V2Space.hairline)

            VStack(spacing: Spacing.spacing8) {
                V2Button(label: note.target.openLabel, action: note.target == .none ? onDismiss : onOpen)
                if note.target != .none {
                    V2Button(label: "Dismiss", role: .text, action: onDismiss)
                }
            }
            .padding(Spacing.spacing16)
            .allowsHitTesting(armed)
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(HFColor.surface))
        .frame(maxWidth: 328)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .onAppear {
            armed = false
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.armDelay) { armed = true }
        }
    }
}

/// Medium — Figma's dismissible top banner (Home › Pre shift end): full width, info fill, 20 icon,
/// white Medium 14, ✕ at 48. A notification carries a message too, so it runs to two text lines; the
/// fill reaches into the status strip, as the connectivity strip does. Slides down from the top and
/// back up (Figma annotation: "slides down top-to-bottom … and goes out in the reverse pattern").
struct V2NotificationBanner: View {
    let note: V2Notification
    var onTap: () -> Void
    var onDismiss: () -> Void

    @State private var drag: CGFloat = 0

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.spacing12) {
            EncoreIcon(iconName: note.severity.icon, size: 20)
                .foregroundColor(HFColor.onPrimary)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(note.subject)
                    .v2Label(V2Font.label1)
                Text(note.body)
                    .v2Text(V2Font.body1)
                    .opacity(0.9)
                    .lineLimit(2)
            }
            .foregroundColor(HFColor.onPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                EncoreIcon(iconName: "LCross", size: 24)
                    .foregroundColor(HFColor.onPrimary)
                    .frame(width: V2Metrics.touchTarget, height: V2Metrics.touchTarget)
            }
            .buttonStyle(.plain)
            .padding(.top, -12)
        }
        .padding(.leading, Spacing.spacing16)
        .padding(.trailing, Spacing.spacing4)
        .padding(.vertical, Spacing.spacing12)
        .background(note.severity.tone.ignoresSafeArea(edges: .top))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .offset(y: min(0, drag))
        .gesture(DragGesture(minimumDistance: 8)
            .onChanged { drag = $0.translation.height }
            .onEnded { v in
                if v.translation.height < -24 { onDismiss() }
                withAnimation(V2Motion.standard) { drag = 0 }
            })
        .accessibilityAddTraits(.isButton)
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
    case critical, high, medium, low, gone, pair, connection
    var id: String { rawValue }

    var title: String {
        switch self {
        case .critical: return "Critical · task cancelled"
        case .high:     return "High · stop window changed"
        case .medium:   return "Medium · shift ending"
        case .low:      return "Low · hub message"
        case .gone:     return "High · trip reassigned (target gone)"
        case .pair:     return "Two important at once"
        case .connection: return "Lose / restore the connection"
        }
    }
}

/// Bottom-sheet panel opened by shaking the device. Not part of the product.
struct V2PushPanel: View {
    var onFire: (V2PushSample) -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HFSheetTitle(title: "Simulate a push", onClose: onClose)
            VStack(spacing: Spacing.spacing8) {
                ForEach(V2PushSample.allCases) { s in
                    Button { onFire(s) } label: {
                        Text(s.title)
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
            .padding(Spacing.spacing16)
            HFSheetBottomInset()
        }
    }
}
