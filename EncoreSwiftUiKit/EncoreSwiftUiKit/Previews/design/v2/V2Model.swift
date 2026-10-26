import SwiftUI

// MARK: - P0.1 Entity state machines
//
// Single source of truth for every chip, affordance and counter in the V2 prototype. Surfaces derive
// everything from here — no surface may branch on a frame number or hardcode a status string.
//
// Status values come from Figma component sets, and every colour binds to the raw palette token the
// chip actually uses (read via get_variable_defs — the "NEWER STATUS COLORS" set documented in
// Components ▸ Dev note 6784:348241):
//   stop status  1728:51916   task status 1778:39047   sla 6967:333684
//   stop ident   1728:51826   task ident  1778:39045   task tag 10374:290432
// Lifecycles cross-checked against disco-encore-product-docs
// docs/07-domains/08-execution/entities/{01b-last-mile-trip,02-stop,03-movement-task,06-stop-settings}.md

enum V2Token {
    static let lightBlue    = Color.encore("LightBlue/500")
    static let lightBlueBg  = Color.encore("LightBlue/50")
    static let blue         = Color.encore("Blue/500")
    static let purple       = Color.encore("Purple/500")
    static let green        = Color.encore("Green/500")
    static let greenBg      = Color.encore("Green/50")
    static let red          = Color.encore("Red/500")
    static let redBg        = Color.encore("Red/50")
    static let yellow       = Color.encore("Yellow/400")
    static let yellowStroke = Color.encore("Yellow/500")
    static let yellowBg     = Color.encore("Yellow/50")
    static let orange       = Color.encore("Orange/500")
    static let orangeBg     = Color.encore("Orange/50")
    /// Navbar / bar icon colour — Figma `action/active` (#666666). Distinct name from
    /// `Text/Secondary` even though they resolve alike today: one is chrome, the other is copy.
    static let actionActive = Color.encore("Action/Active")
}

/// Stop primary lifecycle. P0.6 — `pending` is deliberately chip-less: most cards sit in pending, so
/// chipping it would be noise and the SLA chip carries the card instead.
enum V2StopStatus: CaseIterable {
    case pending, enRoute, arrived, inProgress, completed, failed, partial, skipped, cancelled

    var label: String? {
        switch self {
        case .pending:    return nil
        case .enRoute:    return "En route"
        case .arrived:    return "Arrived"
        case .inProgress: return "In progress"
        case .completed:  return "Completed"
        case .failed:     return "Failed"
        case .partial:    return "Partial"
        case .skipped:    return "Skipped"
        case .cancelled:  return "Cancelled"
        }
    }

    var fill: Color {
        switch self {
        case .pending:              return .clear
        case .enRoute:              return V2Token.lightBlue
        case .arrived:              return V2Token.blue
        case .inProgress:           return V2Token.purple
        case .completed:            return V2Token.green
        case .failed, .cancelled:   return V2Token.red
        case .partial:              return V2Token.yellow
        case .skipped:              return V2Token.orange
        }
    }

    /// Only the amber `Partial` chip flips to a dark label — yellow/400 can't carry white.
    var onFill: Color { self == .partial ? HFColor.textPrimary : HFColor.onPrimary }

    /// P0.5 — terminal ⇒ the surface carries no primary or secondary actions at all.
    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .partial, .skipped, .cancelled: return true
        default: return false
        }
    }

    /// `ReportStopFailure` / `DeferStop` both require that no task has started, which the stop's own
    /// state already encodes — the first task start moves it to `inProgress` (STOP-INV-17).
    var allowsException: Bool { self == .enRoute || self == .arrived }
}

/// MovementTask primary lifecycle. `partial` is in the spec (*"subject shell partially handled — some
/// members DELIVERED, others REFUSED/DAMAGED/SHORT"*) but has no Figma chip yet: every `Partial`
/// component in the file is stop-grain. Rendered provisionally with the stop's amber treatment.
enum V2TaskStatus: CaseIterable {
    case pending, inProgress, completed, failed, partial, cancelled

    var label: String? {
        switch self {
        case .pending:    return nil
        case .inProgress: return "In progress"
        case .completed:  return "Completed"
        case .failed:     return "Failed"
        case .partial:    return "Partial"
        case .cancelled:  return "Cancelled"
        }
    }

    var fill: Color {
        switch self {
        case .pending:              return .clear
        case .inProgress:           return V2Token.purple
        case .completed:            return V2Token.green
        case .failed, .cancelled:   return V2Token.red
        case .partial:              return V2Token.yellow
        }
    }

    var onFill: Color { self == .partial ? HFColor.textPrimary : HFColor.onPrimary }

    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .partial, .cancelled: return true
        default: return false
        }
    }

    /// Counts as a success for the stop cascade.
    var isSuccess: Bool { self == .completed }
    /// Counts as a failure for the stop cascade (partial resolves as a mixed outcome).
    var isFailure: Bool { self == .failed }
}

enum V2TripStatus: CaseIterable {
    case pendingDispatch, inTransit, completed

    var label: String {
        switch self {
        case .pendingDispatch: return "Pending dispatch"
        case .inTransit:       return "In transit"
        case .completed:       return "Completed"
        }
    }

    var fill: Color {
        switch self {
        case .pendingDispatch: return HFColor.textSecondary
        case .inTransit:       return V2Token.purple
        case .completed:       return V2Token.green
        }
    }

    var onFill: Color { HFColor.onPrimary }
    var isTerminal: Bool { self == .completed }
}

/// SLA chips are tinted-and-outlined, not filled: bg `X/50`, 1px `X/500` border, dark label.
/// `Stop.customer_sla_status` — an axis ORTHOGONAL to the stop's lifecycle status, measured against
/// the promise window (product docs, mobile-app execution model §3). It therefore survives a terminal
/// stop: "completed, on time" is the settled outcome, not a stale live reading, and Figma renders it
/// that way (frames 38 and 90 both chip a terminal stop `On time`).
///
/// What does NOT survive is a PREDICTIVE value. `atRisk` and `early` are forecasts about work still
/// in flight; once the stop is terminal the axis has to collapse to what actually happened.
enum V2Sla: CaseIterable {
    case early, onTime, atRisk, late, breached

    /// True while the value is still a forecast rather than an outcome.
    var isLive: Bool { self == .atRisk || self == .early }

    /// The outcome this forecast resolves to when the stop goes terminal.
    ///
    /// A real implementation compares the completion timestamp to the promise window. The prototype
    /// has no clock, so it resolves optimistically — it must not invent a `late` claim it cannot
    /// substantiate. The point of the method is the invariant: a terminal stop is never `atRisk`.
    func settled(completedLate: Bool = false) -> V2Sla {
        guard isLive else { return self }
        return completedLate ? .late : .onTime
    }

    var label: String {
        switch self {
        case .early:    return "Early"
        case .onTime:   return "On time"
        case .atRisk:   return "At risk"
        case .late:     return "Late"
        case .breached: return "Breached"
        }
    }

    var bg: Color {
        switch self {
        case .early:    return V2Token.lightBlueBg
        case .onTime:   return V2Token.greenBg
        case .atRisk:   return V2Token.yellowBg
        case .late:     return V2Token.orangeBg
        case .breached: return V2Token.redBg
        }
    }

    var stroke: Color {
        switch self {
        case .early:    return V2Token.lightBlue
        case .onTime:   return V2Token.green
        case .atRisk:   return V2Token.yellowStroke
        case .late:     return V2Token.orange
        case .breached: return V2Token.red
        }
    }
}

// MARK: - Kinds

/// StopType — drives the page title and the identifier pill. It does NOT drive affordances; those come
/// from per-stop config (see `V2StopConfig`), because StopSettings is resolved per stopType server-side.
enum V2StopKind {
    case hub, customer, partner, handback

    var pageTitle: String {
        switch self {
        case .hub, .handback: return "Hub Stop"
        case .customer:       return "Customer Stop"
        case .partner:        return "Partner Stop"
        }
    }

    /// Identifier pills are *informational*, so their glyphs are the FILLED variants. Stroked glyphs
    /// are reserved for actionable icons (navigate, call, back, close).
    var identifier: (label: String, icon: String) {
        switch self {
        case .hub, .handback: return ("Hub", "LWarehouseFilled")
        case .customer:       return ("Customer", "LPerson")
        // TODO(design): the Figma pill uses a gem/rhombus glyph with no catalog equivalent — export
        // and import to Assets.xcassets; LHandshake is the interim stand-in.
        case .partner:        return ("Partner", "LHandshake")
        }
    }

    /// Hub load / handback stops club their orders into a single task card.
    var clubsTasks: Bool { clubKind != nil }

    /// The ONE task kind a stop clubs. A hub load clubs its pickups; the return hub clubs its
    /// hand-backs only — a return DELIVERY of a collected customer pickup is planned work with its
    /// own card, and "the two never merge into one list" (Story 1.4.10).
    var clubKind: V2TaskKind? {
        switch self {
        case .hub:      return .pickup
        case .handback: return .handback
        default:        return nil
        }
    }
}

enum V2TaskKind {
    case delivery, pickup, service, handback, scheduledBreak

    var label: String {
        switch self {
        case .delivery:       return "Delivery"
        case .pickup:         return "Pickup"
        case .service:        return "Service"
        case .handback:       return "Handback"
        case .scheduledBreak: return "Scheduled Break"
        }
    }

    /// Page title on the task detail surface — frame 99 reads "Handback Task", so this is derived,
    /// never hardcoded per screen.
    var pageTitle: String { "\(label) Task" }

    var glyph: HFChipGlyph {
        switch self {
        case .delivery: return .deliver
        case .pickup:   return .pickup
        case .handback: return .handback
        default:        return .none
        }
    }

    /// Break is the one identifier chip on a yellow tint rather than the secondary purple.
    var isBreak: Bool { self == .scheduledBreak }
}

// MARK: - P0.7 Exception affordances (config-driven)

/// Resolved `StopSettings` for one stop. Deliberately a value on the stop rather than a switch on
/// `V2StopKind`: server-side these are resolved per `stopType` + `serviceCategory`, and the spec is
/// explicit that "no defer here" is `deferralMax = 0`, not a hardcoded rule.
struct V2StopConfig {
    /// `deferralMax = 0` ⇒ DeferStop is blocked outright ("complete all tasks or skip the stop").
    var deferralMax: Int
    /// No StopSettings field disables ReportStopFailure — `locationFailureAllowedReasons` only
    /// restricts the reason list. False only on the return leg, where LMT-INV-27 requires arrival
    /// before CompleteTrip, so failing it would deadlock the trip.
    var canReportLocationFailure: Bool
    /// Partner counters hold the driver before undelivered tasks may be failed.
    var minDwellSeconds: Int

    static let customer = V2StopConfig(deferralMax: 3, canReportLocationFailure: true, minDwellSeconds: 0)
    static let hub      = V2StopConfig(deferralMax: 1, canReportLocationFailure: true, minDwellSeconds: 0)
    static let partner  = V2StopConfig(deferralMax: 0, canReportLocationFailure: true, minDwellSeconds: 503)
    static let handback = V2StopConfig(deferralMax: 0, canReportLocationFailure: false, minDwellSeconds: 0)
}

enum V2StopException: Hashable {
    case markFailed
    case deferStop(remaining: Int)

    /// Label when shown as a direct chip (single option).
    var chipLabel: String {
        switch self {
        case .markFailed:  return "Mark failed"
        case .deferStop:   return "Defer stop"
        }
    }

    /// Title when shown as a row inside the `Facing issues?` sheet.
    var rowTitle: String {
        switch self {
        case .markFailed:               return "Mark as failed"
        case .deferStop(let remaining): return "Defer stop (\(remaining) remaining)"
        }
    }

    var rowSubtitle: String {
        switch self {
        case .markFailed: return "Report your stop issue and mark planned tasks as cancelled"
        case .deferStop:  return "Stop will be positioned later in the trip and actioned later"
        }
    }
}

// MARK: - Attempt-failure disposition (DEC-256)

/// Whether a failed task's goods leave this trip. Only the off-trip dispositions create a HANDBACK;
/// a same-trip retry keeps the goods aboard for another attempt.
enum V2Disposition {
    case retrySamePlan, retryReplan, abandon, wait

    var sendsGoodsOffTrip: Bool { self != .retrySamePlan }
}

// MARK: - Entities

/// A handling unit — the thing a rider actually scans. Frames 05/22 of the Scan template list these
/// with their HUID as the headline and a box count beneath; the scanner reports progress in HUs, not
/// boxes, which is why `scanned` is a unit-level flag.
struct V2HU: Identifiable, Equatable {
    let id: String
    var code: String = "JP-MIN-PKT-500G"
    var boxes: Int = 1
    var category: String = "Lorem Ipsum"
    var tags: [String] = []
    var scanned: Bool = false

    var boxLabel: String { boxes == 1 ? "1 box" : "\(boxes) boxes" }
}

struct V2Task: Identifiable {
    let id: Int
    /// The order's customer reference number — the "IKEA order ID" (`customerReferenceNumber`,
    /// DEC-284; format `IKEA-UK-{year}-{seq:08}`). Backend data, shown in full. The internal task id
    /// and the system order numbers (`TO-…`, `ORD-…`) never surface in the UI.
    let orderRef: String
    /// Display form: the static "ORDER ID" label in front of the value (eyebrows, section headers).
    var orderId: String { "ORDER ID \(orderRef)" }
    var kind: V2TaskKind
    var hus: Int
    var husLabel: String { hus == 1 ? "1 HU" : "\(hus) HUs" }
    /// Filled by `V2Seed` from `hus` so the seed stays readable. The scanner mutates these.
    var units: [V2HU] = []
    var scannedUnits: Int { units.filter(\.scanned).count }
    var allScanned: Bool { !units.isEmpty && scannedUnits == units.count }
    var tags: [String] = []
    var contactName: String? = nil
    var contactSub: String? = nil
    var instruction: String? = nil
    var status: V2TaskStatus = .pending
    /// Blocked until these tasks reach a terminal state (`MovementTask.dependsOnTaskRefs`).
    var dependsOn: [Int] = []
    /// True when this task's units are physically on the vehicle. A delivery loaded at the hub is
    /// aboard; a pickup that was never collected is not — and per DEC-488 §3 an uncollected unit
    /// "MUST NOT generate" a handback, since there is nothing to hand back.
    var custodyAboard: Bool = false
    /// Set when the task is resolved FAILED.
    var disposition: V2Disposition? = nil
    /// Why the task was cancelled, shown on its card (Task card states → Cancelled with reason).
    var cancellationReason: String? = nil
    /// Set when this task was created as a hand-back obligation for another task.
    var handbackFor: Int? = nil

    /// Qualifies for a HANDBACK on failure: goods aboard AND the disposition sends them off-trip.
    var isCustodyBoundFailure: Bool {
        guard status == .failed || status == .cancelled || status == .partial else { return false }
        guard custodyAboard else { return false }
        return (disposition ?? .abandon).sendsGoodsOffTrip
    }
}

struct V2Stop: Identifiable {
    let id: Int
    var seq: Int
    var kind: V2StopKind
    var config: V2StopConfig
    var title: String
    var verified: Bool = false
    var address: String
    var window: String
    var sla: V2Sla = .onTime
    var status: V2StopStatus = .pending
    var tasks: [V2Task]
    var deferredCount: Int = 0
    var dwellSecondsLeft: Int = 0
    /// Seconds left to undo an arrival (frame 21's "01:02m left"). No frame states the window, so it
    /// is configuration (`V2Engine.undoArrivalWindow`); the kebab goes when it runs out.
    var undoSecondsLeft: Int = 0
    /// True for the debrief return leg — planned at trip creation when the trip must return to origin
    /// (`returnToOriginRequired`, IKEA Wave 1), appended at runtime otherwise (DEC-302 3c).
    var isReturnLeg: Bool = false
    /// Why the stop ended this way — `skipReason` (SKIPPED) or `stopFailureReason` (FAILED). Shown as the
    /// header's reason pair, as a cancelled task shows its cancellation reason.
    var statusReason: String? = nil

    var eyebrow: String { "STOP \(seq)" }
    var doneTasks: Int { tasks.filter { $0.status.isTerminal }.count }
    var deferralsLeft: Int { max(0, config.deferralMax - deferredCount) }
    /// The tasks this stop clubs into one card, and the ones that keep their own cards.
    var clubbedTasks: [V2Task] { kind.clubKind.map { k in tasks.filter { $0.kind == k } } ?? [] }
    var looseTasks: [V2Task] { kind.clubKind.map { k in tasks.filter { $0.kind != k } } ?? tasks }
    func isClubbed(_ task: V2Task) -> Bool { kind.clubKind == task.kind }
    var totalHUs: Int { clubbedTasks.reduce(0) { $0 + $1.hus } }

    /// P0.7 — the affordances actually available right now. Surfaces render a direct chip for one and
    /// a `Facing issues?` sheet for two or more; they never decide availability themselves.
    var exceptions: [V2StopException] {
        guard status.allowsException else { return [] }
        var out: [V2StopException] = []
        if config.canReportLocationFailure { out.append(.markFailed) }
        // DeferStop is ARRIVED-only (DEC-300 — `STOP_NOT_ARRIVED`) and needs deferrals remaining.
        if status == .arrived, deferralsLeft > 0 { out.append(.deferStop(remaining: deferralsLeft)) }
        return out
    }

    /// Stop terminal state is derived from child task outcomes, never set directly
    /// (Stop § State Cascade — MovementTask → Stop).
    var derivedTerminal: V2StopStatus? {
        guard !tasks.isEmpty, tasks.allSatisfy({ $0.status.isTerminal }) else { return nil }
        let cancelled = tasks.filter { $0.status == .cancelled }.count
        if cancelled == tasks.count { return .skipped }
        let succeeded = tasks.filter { $0.status.isSuccess }.count
        let failed    = tasks.filter { $0.status.isFailure }.count
        let mixedShell = tasks.contains { $0.status == .partial }
        if mixedShell { return .partial }
        if succeeded > 0 && failed > 0 { return .partial }
        if failed > 0 && succeeded == 0 { return .failed }
        return .completed
    }
}

struct V2Trip {
    var seq: Int = 1
    var window: String = "08:00 AM - 02:00 PM"
    var distance: String = "~17 km"
    var status: V2TripStatus = .pendingDispatch
    var stops: [V2Stop]
    /// `LastMileTripSettings.returnHandoverTaskEnabled`. Off ⇒ no HANDBACK tasks and the return leg is
    /// a work-free debrief stop that completes on arrival.
    var returnHandoverTaskEnabled: Bool = true

    var eyebrow: String { "TRIP \(seq)" }
    var doneStops: Int { stops.filter { $0.status.isTerminal }.count }
    var allStopsTerminal: Bool { stops.allSatisfy { $0.status.isTerminal } }
    var allTasks: [V2Task] { stops.flatMap(\.tasks) }
    var pickups: Int { allTasks.filter { $0.kind == .pickup }.count }
    var deliveries: Int { allTasks.filter { $0.kind == .delivery }.count }
    var services: Int { allTasks.filter { $0.kind == .service }.count }

    var returnLegIndex: Int? { stops.firstIndex { $0.isReturnLeg } }

    /// `View details` uses a DIFFERENT counter set from the end-of-trip summary: here a stop is
    /// still "to do", there it has been resolved. Keeping them apart is deliberate — one reports
    /// work outstanding, the other reports outcomes (open conflict #6 in the flow map).
    var stopsToDo: Int { stops.filter { !$0.status.isTerminal }.count }
    func stops(_ status: V2StopStatus) -> Int { stops.filter { $0.status == status }.count }

    /// LMT-G23 / LMT-INV-27 — while the hand-back toggle is on, `CompleteTrip` is blocked until every
    /// HANDBACK task is terminal. Arrival at the return leg alone is not enough.
    var canEndTrip: Bool {
        guard allStopsTerminal else { return false }
        guard returnHandoverTaskEnabled else { return true }
        return allTasks.filter { $0.kind == .handback }.allSatisfy { $0.status.isTerminal }
    }
}

// MARK: - Seed (V2 Flow board: 4 planned stops; the return leg is appended on first custody-bound failure)

enum V2Seed {
    /// Box counts cycle so the list reads like the Figma frames (1 box / 3 boxes / 2 boxes / …)
    /// rather than a column of identical rows.
    // MARK: The order book — the single source every stop draws from
    //
    // One order is ONE set of handling units wherever it appears: picked up at the hub (26), delivered
    // at its customer stop (48, 82), and — if it fails while aboard — handed back on the return leg
    // (99). Tasks name an order by ref and take its units from here, so a count can never disagree
    // between screens: the hub's "6 HUs" IS O1 + O3 + O5 + O6 + O7.
    //
    // Refs are customer reference numbers (`IKEA-UK-{year}-{seq:08}`, DEC-284). HU codes are the
    // per-unit label number printed on every carton (docs' IKEA example 13245, DEC-226) — sample data
    // until the platform fixes a display field (HandlingUnit only has `hu-{uuid}`).
    struct Order {
        let ref: String
        /// (HU code, boxes in that unit)
        let units: [(code: String, boxes: Int)]
        var tags: [String] = []
    }

    static let orders: [Order] = [
        Order(ref: "IKEA-UK-2026-00098765", units: [("13245", 1)], tags: ["Fragile"]),  // O1
        Order(ref: "IKEA-UK-2026-00098766", units: [("13251", 1)]),                     // O2 customer pickup
        Order(ref: "IKEA-UK-2026-00098767", units: [("13246", 3)]),                     // O3
        Order(ref: "IKEA-UK-2026-00098768", units: [("13252", 1)]),                     // O4 customer pickup
        Order(ref: "IKEA-UK-2026-00098769", units: [("13247", 2)]),                     // O5
        Order(ref: "IKEA-UK-2026-00098770", units: [("13248", 1), ("13249", 1)]),       // O6
        Order(ref: "IKEA-UK-2026-00098771", units: [("13250", 3)]),                     // O7
    ]

    static func order(_ n: Int) -> Order { orders[n - 1] }

    /// A task for order `n`: its ref, its tags and its HU count all come from the order book.
    static func task(_ id: Int, order n: Int, _ kind: V2TaskKind, contact: String, sub: String,
                     instruction: String? = nil, dependsOn: [Int] = [],
                     custodyAboard: Bool = false) -> V2Task {
        let o = order(n)
        return V2Task(id: id, orderRef: o.ref, kind: kind, hus: o.units.count, tags: o.tags,
                      contactName: contact, contactSub: sub, instruction: instruction,
                      dependsOn: dependsOn, custodyAboard: custodyAboard)
    }

    static func trip() -> V2Trip {
        var trip = plan()
        for s in trip.stops.indices {
            for t in trip.stops[s].tasks.indices {
                let task = trip.stops[s].tasks[t]
                guard let o = orders.first(where: { $0.ref == task.orderRef }) else { continue }
                trip.stops[s].tasks[t].units = o.units.enumerated().map { i, u in
                    V2HU(id: u.code, boxes: u.boxes, tags: i == 0 ? o.tags : [])
                }
            }
        }
        return trip
    }

    private static func plan() -> V2Trip {
        V2Trip(stops: [
            V2Stop(id: 1, seq: 1, kind: .hub, config: .hub,
                   title: "IKEA Hub",
                   address: "12, Whitefield Hub Road, Bengaluru, 560066",
                   window: "08:00 AM - 08:50 AM",
                   // Five clubbed pickup orders totalling six handling units — the board draws
                   // `5 CLUBBED ORDERS / 6 HUs`, and the scan page groups its rows by these orders.
                   tasks: [
                    task(11, order: 1, .pickup, contact: "Dock 3, Bay B2", sub: "Whitefield Hub"),
                    task(12, order: 3, .pickup, contact: "Dock 3, Bay B2", sub: "Whitefield Hub"),
                    task(13, order: 5, .pickup, contact: "Dock 3, Bay B2", sub: "Whitefield Hub"),
                    task(14, order: 6, .pickup, contact: "Dock 3, Bay B2", sub: "Whitefield Hub"),
                    task(15, order: 7, .pickup, contact: "Dock 3, Bay B2", sub: "Whitefield Hub"),
                   ]),
            V2Stop(id: 2, seq: 2, kind: .customer, config: .customer,
                   title: "Locus - Logistics Optimization & Decision-making Platform",
                   verified: true,
                   address: "Mayur Greens, 4th Floor, 87-148, Koramangala, Bengaluru, 560034",
                   window: "09:15 AM - 09:45 AM",
                   tasks: [
                    task(21, order: 1, .delivery, contact: "Priya Sharma", sub: "23, Floor 4, Building 2",
                         instruction: "Call on arrival, don't ring the doorbell.", custodyAboard: true),
                    task(22, order: 2, .pickup, contact: "Priya Sharma", sub: "23, Floor 4, Building 2",
                         dependsOn: [21]),
                   ]),
            V2Stop(id: 3, seq: 3, kind: .customer, config: .customer,
                   title: "Majestic Apartments",
                   address: "A-148, 4th Block, Koramangala, Bengaluru, 560034",
                   window: "10:00 AM - 11:00 AM",
                   tasks: [
                    task(31, order: 3, .delivery, contact: "Priya Sharma", sub: "27, Floor 4, Building 2",
                         custodyAboard: true),
                    // Never collected, so nothing is aboard — must NOT generate a handback.
                    task(32, order: 4, .pickup, contact: "Rohit Mehta", sub: "23, Floor 4, Building 2"),
                   ]),
            V2Stop(id: 4, seq: 4, kind: .partner, config: .partner,
                   title: "Costa Coffee",
                   address: "87-148, Koramangala, Bengaluru, 560034",
                   window: "11:30 AM - 01:00 PM",
                   tasks: [
                    task(41, order: 5, .delivery, contact: "Rohit Mehta", sub: "Counter 2, Gate 1",
                         instruction: "Call on arrival, don't ring the doorbell.", custodyAboard: true),
                    task(42, order: 6, .delivery, contact: "Priya Sharma", sub: "Counter 2, Gate 1",
                         custodyAboard: true),
                    task(43, order: 7, .delivery, contact: "Rohit Mehta", sub: "Counter 2, Gate 1",
                         custodyAboard: true),
                   ],
                   dwellSecondsLeft: 503),
            // The trip returns to origin, so the hub stop is PLANNED (STOP-INV-3), carrying the
            // return DELIVER of what is collected from customers on the way — order 2, picked up at
            // stop 2 (W-2 §4.1, Story 1.4.10). Hand-backs of failed deliveries join it at runtime as
            // their own club (DEC-488 §3).
            V2Stop(id: 99, seq: 5, kind: .handback, config: .handback,
                   title: "IKEA Hub",
                   address: "12, Whitefield Hub Road, Bengaluru, 560066",
                   window: "01:15 PM - 01:45 PM",
                   tasks: [
                    task(51, order: 2, .delivery, contact: "Dock 3, Bay B2", sub: "Whitefield Hub",
                         dependsOn: [22]),
                   ],
                   isReturnLeg: true),
        ])
    }
}


// MARK: - Shift (frames 07–10, 113–115)

/// Shift lifecycle — DRAFT → UPCOMING → ONGOING → COMPLETED, + NO SHOW (Components → Shift card
/// states). Before clock-in the shift is UPCOMING; it is ONGOING only once the rider clocks in. (Flow
/// frame 07 labels the pre-clock-in card "Ongoing"; the states board is the state machine.)
enum V2ShiftStatus {
    case draft, upcoming, ongoing, completed, noShow

    /// Draft carries no chip at all (there is no Draft variant in the Shift Status set).
    var label: String? {
        switch self {
        case .draft:     return nil
        case .upcoming:  return "Upcoming"
        case .ongoing:   return "Ongoing"
        case .completed: return "Completed"
        case .noShow:    return "No show"
        }
    }

    var fill: Color {
        switch self {
        case .draft, .upcoming: return Color.encore("Grey/500")
        case .ongoing:          return V2Token.purple
        case .completed:        return V2Token.green
        case .noShow:           return V2Token.red
        }
    }
}

/// One leg of a shift's plan (Shift card legs).
struct V2ShiftLeg: Identifiable {
    enum Kind { case delivery, gap, hubOps }
    let id: Int
    var kind: Kind
    var window: String

    var label: String {
        switch kind {
        case .delivery: return "DELIVERY"
        case .gap:      return "GAP"
        case .hubOps:   return "HUB OPS"
        }
    }

    var tint: Color {
        switch kind {
        case .delivery: return HFColor.primary
        case .gap:      return Color.encore("Highlight/Dark")
        case .hubOps:   return Color.encore("Secondary/Main")
        }
    }
}

struct V2Shift {
    var seq: Int = 1
    var window: String = "08:00 AM - 02:00 PM"
    var status: V2ShiftStatus = .upcoming
    var clockedIn: Bool = false
    /// The clock-in window is open (Upcoming, can be actioned). False = "very next, can't be actioned":
    /// Clock in is disabled and the reason line says why.
    var canClockIn: Bool = true
    /// Start time passed without a clock-in: still Upcoming, Clock in enabled, the "now" marker sits in
    /// the first leg and the reason line asks why.
    var runningLate: Bool = false
    /// Where "now" sits on the leg rail, in legs: 0 = the first leg's dot, 1 = the second's, 2.4 = 40%
    /// of the way from the third dot to the fourth. Shown while the shift is under way or running late.
    var nowAt: Double = 0
    var legs: [V2ShiftLeg] = [V2ShiftLeg(id: 1, kind: .delivery, window: "08:00 AM - 02:00 PM")]
    var reportingArea: String = "Whitefield DSU, Area 2, Bay 2"
    var clockedTime: String = "08:02 AM - 02:06 PM"
    var onShift: String = "6h 4m (+4 mins)"
    var clockedInAt: String = "08:02"

    /// The app-bar status line — one rule for every tab (Home and Delivery): shown while the rider is
    /// clocked in, gone before clock-in and after clock-out.
    var appBarSubtitle: String? {
        clockedIn && status == .ongoing ? "ON SHIFT · SINCE \(clockedInAt)" : nil
    }
}
