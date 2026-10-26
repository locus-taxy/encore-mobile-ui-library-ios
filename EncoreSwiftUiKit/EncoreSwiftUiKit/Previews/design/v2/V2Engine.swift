import SwiftUI

// MARK: - P0.1 Entity state machine
//
// The ONLY place entity state changes. Surfaces call these; they never assign a status themselves.
// Terminal stop states are always derived from child task outcomes — see `cascade(stop:)`.

final class V2Engine: ObservableObject {
    @Published var trip: V2Trip
    @Published var shift = V2Shift()

    init(trip: V2Trip = V2Seed.trip()) { self.trip = trip }

    // MARK: Shift (frames 07–10, 113–115)

    func clockIn() {
        guard !shift.clockedIn, shift.status == .upcoming, shift.canClockIn else { return }
        shift.clockedIn = true
        shift.status = .ongoing
        shift.runningLate = false
    }

    /// Clock out is offered once the day's work is done — the trip is completed (frame 113).
    var canClockOut: Bool { shift.clockedIn && shift.status == .ongoing && trip.status == .completed }

    func clockOut() {
        guard canClockOut else { return }
        shift.status = .completed
    }

    // MARK: Trip

    func startTrip() { trip.status = .inTransit }

    /// Gated by LMT-G23 — see `V2Trip.canEndTrip`.
    func endTrip() {
        guard trip.canEndTrip else { return }
        trip.status = .completed
    }

    // MARK: Stop progression (the three driver-settable states)

    /// Stop work cannot begin before the trip is in transit — the trip is the outer gate on the whole
    /// stop lifecycle, so `pending → enRoute` is refused while the trip is still pending dispatch.
    func startWork(_ stopId: Int) {
        guard trip.status == .inTransit else { return }
        mutate(stopId) { s in
            guard s.status == .pending else { return }
            s.status = .enRoute
        }
    }

    func markArrival(_ stopId: Int) {
        mutate(stopId) { s in
            guard s.status == .enRoute else { return }
            s.status = .arrived
            s.dwellSecondsLeft = s.config.minDwellSeconds
            s.undoSecondsLeft = V2Engine.undoArrivalWindow
        }
    }

    /// Advances every running dwell clock by `seconds` (frame 81 → 85). A partner counter's
    /// undelivered tasks can only be failed once its clock reaches zero.
    func tickDwell(_ seconds: Int = 1) {
        for i in trip.stops.indices where trip.stops[i].dwellSecondsLeft > 0
            && (trip.stops[i].status == .arrived || trip.stops[i].status == .inProgress) {
            trip.stops[i].dwellSecondsLeft = max(0, trip.stops[i].dwellSecondsLeft - seconds)
        }
        // The undo window runs in real time — it is a short grace period, not a wait.
        for i in trip.stops.indices where trip.stops[i].undoSecondsLeft > 0 {
            trip.stops[i].undoSecondsLeft -= 1
        }
    }

    /// How long an arrival can be undone. Configuration — the board shows "01:02m left" mid-window.
    static let undoArrivalWindow = 90

    /// Log out: the next rider starts from a fresh plan.
    func reset() {
        trip = V2Seed.trip()
        shift = V2Shift()
    }

    /// STOP-INV-13 — undo requires every child task still PENDING.
    func undoArrival(_ stopId: Int) {
        mutate(stopId) { s in
            guard s.status == .arrived,
                  s.tasks.allSatisfy({ $0.status == .pending }) else { return }
            s.status = .enRoute
            s.dwellSecondsLeft = 0
            s.undoSecondsLeft = 0
        }
    }

    // MARK: Task progression

    /// A task is blocked while any dependency is non-terminal (`dependsOnTaskRefs`).
    func isBlocked(_ task: V2Task) -> Bool {
        guard !task.dependsOn.isEmpty else { return false }
        return task.dependsOn.contains { dep in
            guard let t = trip.allTasks.first(where: { $0.id == dep }) else { return false }
            return !t.status.isTerminal
        }
    }

    func startTask(_ stopId: Int, _ taskId: Int) {
        mutate(stopId) { s in
            guard let i = s.tasks.firstIndex(where: { $0.id == taskId }),
                  s.tasks[i].status == .pending else { return }
            s.tasks[i].status = .inProgress
        }
        promoteToInProgress(stopId)
    }

    /// Clubbed hub / handback stops start every task with one swipe.
    func startAllTasks(_ stopId: Int) {
        mutate(stopId) { s in
            for i in s.tasks.indices where s.tasks[i].status == .pending {
                s.tasks[i].status = .inProgress
            }
        }
        promoteToInProgress(stopId)
    }

    // MARK: Scanning
    //
    // Scanning does not change a task's STATUS — it only fills the unit ledger the completion
    // checklist is gated on. Status still moves through `completeTask`, so there is one path to
    // terminal regardless of whether the rider scanned, bypassed, or failed.

    /// Result of offering an entity id to the scanner (frames 08 / 14 / 18 of the Scan template).
    enum ScanResult: Equatable {
        case scanned(V2HU)
        case alreadyScanned(V2HU)
        case notRecognised
    }

    @discardableResult
    func scan(_ stopId: Int, _ taskId: Int, _ huId: String) -> ScanResult {
        guard let s = trip.stops.firstIndex(where: { $0.id == stopId }),
              let t = trip.stops[s].tasks.firstIndex(where: { $0.id == taskId }),
              let u = trip.stops[s].tasks[t].units.firstIndex(where: { $0.id == huId })
        else { return .notRecognised }
        if trip.stops[s].tasks[t].units[u].scanned {
            return .alreadyScanned(trip.stops[s].tasks[t].units[u])
        }
        trip.stops[s].tasks[t].units[u].scanned = true
        return .scanned(trip.stops[s].tasks[t].units[u])
    }

    /// The next unscanned unit — what a real scanner would read next, and what the prototype's
    /// scan affordance stands in for.
    func nextUnscanned(_ stopId: Int, _ taskId: Int) -> V2HU? {
        stop(stopId)?.tasks.first { $0.id == taskId }?.units.first { !$0.scanned }
    }

    /// Frame 10 — `Undo` on the result sheet puts the unit back.
    func undoScan(_ stopId: Int, _ taskId: Int, _ huId: String) {
        mutate(stopId) { s in
            guard let t = s.tasks.firstIndex(where: { $0.id == taskId }),
                  let u = s.tasks[t].units.firstIndex(where: { $0.id == huId }) else { return }
            s.tasks[t].units[u].scanned = false
        }
    }

    // MARK: Work scope
    //
    // A clubbed stop (hub pickup, hand-back) is worked as ONE unit: one start, one scan list across
    // every order's units, one checklist, one completion (frames 26 → 37, 99 → 104). Every workflow
    // therefore acts on a SCOPE of tasks, not on the task it was opened from — acting on the lead task
    // alone is what left the hub stuck at 1/5 with the rest of the club unreachable.

    /// The tasks a workflow opened from `taskId` acts on: every open task on a clubbed stop,
    /// otherwise the task alone.
    func scope(_ stopId: Int, _ taskId: Int) -> [Int] {
        guard let s = stop(stopId), let lead = s.tasks.first(where: { $0.id == taskId }),
              s.isClubbed(lead) else { return [taskId] }
        let open = s.clubbedTasks.filter { !$0.status.isTerminal }.map(\.id)
        return open.isEmpty ? [taskId] : open
    }

    /// One task-shaped view of the scope, so scan surfaces read the same fields whichever it is:
    /// the lead task, carrying every scoped unit.
    func subject(_ stopId: Int, _ taskId: Int) -> V2Task? {
        guard let s = stop(stopId), var lead = s.tasks.first(where: { $0.id == taskId }) else { return nil }
        let ids = scope(stopId, taskId)
        lead.units = s.tasks.filter { ids.contains($0.id) }.flatMap(\.units)
        return lead
    }

    /// The scoped task that owns a unit.
    private func owner(_ stopId: Int, _ ids: [Int], _ huId: String) -> Int? {
        stop(stopId)?.tasks.first { ids.contains($0.id) && $0.units.contains { $0.id == huId } }?.id
    }

    @discardableResult
    func scan(_ stopId: Int, scope ids: [Int], _ huId: String) -> ScanResult {
        guard let t = owner(stopId, ids, huId) else { return .notRecognised }
        return scan(stopId, t, huId)
    }

    func nextUnscanned(_ stopId: Int, scope ids: [Int]) -> V2HU? {
        stop(stopId)?.tasks.filter { ids.contains($0.id) }.flatMap(\.units).first { !$0.scanned }
    }

    func undoScan(_ stopId: Int, scope ids: [Int], _ huId: String) {
        guard let t = owner(stopId, ids, huId) else { return }
        undoScan(stopId, t, huId)
    }

    /// Starts a scope of tasks in one swipe (a club), leaving the stop's other cards alone.
    func startTasks(_ stopId: Int, _ ids: [Int]) {
        mutate(stopId) { s in
            for i in s.tasks.indices where ids.contains(s.tasks[i].id) && s.tasks[i].status == .pending {
                s.tasks[i].status = .inProgress
            }
        }
        promoteToInProgress(stopId)
    }

    /// Completes the whole scope in one transition, so the stop cascades once.
    func completeTasks(_ stopId: Int, _ ids: [Int]) {
        mutate(stopId) { s in
            for i in s.tasks.indices where ids.contains(s.tasks[i].id) && !s.tasks[i].status.isTerminal {
                s.tasks[i].status = .completed
                s.tasks[i].disposition = nil
            }
        }
        cascade(stopId)
    }

    func completeTask(_ stopId: Int, _ taskId: Int) {
        setTaskStatus(stopId, taskId, .completed, disposition: nil)
    }

    func completeAllTasks(_ stopId: Int) {
        mutate(stopId) { s in
            for i in s.tasks.indices where !s.tasks[i].status.isTerminal {
                s.tasks[i].status = .completed
            }
        }
        cascade(stopId)
    }

    /// Resolve a started task FAILED. The disposition decides whether its goods leave the trip, which
    /// is what gates the hand-back — not the failure itself.
    func failTask(_ stopId: Int, _ taskId: Int, disposition: V2Disposition = .abandon) {
        setTaskStatus(stopId, taskId, .failed, disposition: disposition)
    }

    /// Mixed member outcomes on one shell (spec PARTIAL). No Figma chip yet — provisional amber.
    func partialTask(_ stopId: Int, _ taskId: Int, disposition: V2Disposition = .abandon) {
        setTaskStatus(stopId, taskId, .partial, disposition: disposition)
    }

    /// Partner counters: fail whatever was never collected once the dwell timer has expired.
    func failUndeliveredTasks(_ stopId: Int) {
        guard let s = stop(stopId), s.dwellSecondsLeft <= 0 else { return }
        mutate(stopId) { s in
            for i in s.tasks.indices where !s.tasks[i].status.isTerminal {
                s.tasks[i].status = .failed
                s.tasks[i].disposition = .abandon
            }
        }
        cascade(stopId)
    }

    // MARK: Dispatch changes (what a notification announces)

    /// `CancelMovementTask` by dispatch: the task → CANCELLED with its reason (MT-INV-11), then the stop
    /// re-derives (all cancelled → SKIPPED; completed + cancelled → COMPLETED; …).
    func cancelTask(_ stopId: Int, _ taskId: Int, reason: String) {
        mutate(stopId) { s in
            guard let i = s.tasks.firstIndex(where: { $0.id == taskId }), !s.tasks[i].status.isTerminal else { return }
            s.tasks[i].status = .cancelled
            s.tasks[i].cancellationReason = reason
        }
        cascade(stopId)
    }

    /// `SkipStop` by dispatch: the stop → SKIPPED and every open task → CANCELLED (STOP_SKIPPED).
    func skipStop(_ stopId: Int, reason: String) {
        mutate(stopId) { s in
            for i in s.tasks.indices where !s.tasks[i].status.isTerminal {
                s.tasks[i].status = .cancelled
                s.tasks[i].cancellationReason = reason
            }
            s.status = .skipped
            s.statusReason = reason
            s.sla = s.sla.settled()
        }
        reconcileHandbacks()
    }

    // MARK: Stop exceptions

    /// `ReportStopFailure` (DEC-126): stop → FAILED with `LOCATION_FAILURE`, and every PENDING child
    /// → CANCELLED with `STOP_FAILED`.
    func reportStopFailure(_ stopId: Int) {
        guard let s = stop(stopId), s.exceptions.contains(.markFailed) else { return }
        mutate(stopId) { s in
            for i in s.tasks.indices where s.tasks[i].status == .pending {
                s.tasks[i].status = .cancelled
                s.tasks[i].cancellationReason = "Location could not be reached"
            }
            s.status = .failed
            s.statusReason = "Location could not be reached"
            s.sla = s.sla.settled()
        }
        // Stop-level failure is set directly (it is not a task cascade), but hand-backs still derive.
        reconcileHandbacks()
    }

    /// `DeferStop` (DEC-300 v1.1.0): ARRIVED → PENDING re-queue at a later sequence, `deferredCount++`.
    /// Child tasks stay PENDING.
    func deferStop(_ stopId: Int) {
        guard let s = stop(stopId),
              s.exceptions.contains(where: { if case .deferStop = $0 { return true } else { return false } })
        else { return }
        guard let idx = trip.stops.firstIndex(where: { $0.id == stopId }) else { return }
        var moved = trip.stops.remove(at: idx)
        moved.status = .pending
        moved.deferredCount += 1
        moved.dwellSecondsLeft = 0
        // Re-insert before the return leg if one exists, else at the end.
        let insertAt = trip.stops.firstIndex(where: { $0.isReturnLeg }) ?? trip.stops.count
        trip.stops.insert(moved, at: insertAt)
        resequence()
    }

    // MARK: - Cascades

    private func setTaskStatus(_ stopId: Int, _ taskId: Int, _ status: V2TaskStatus,
                               disposition: V2Disposition?) {
        mutate(stopId) { s in
            guard let i = s.tasks.firstIndex(where: { $0.id == taskId }) else { return }
            s.tasks[i].status = status
            s.tasks[i].disposition = disposition
        }
        cascade(stopId)
    }

    private func promoteToInProgress(_ stopId: Int) {
        mutate(stopId) { s in
            guard s.status == .arrived || s.status == .enRoute else { return }
            guard s.tasks.contains(where: { $0.status == .inProgress }) else { return }
            s.status = .inProgress
        }
    }

    /// Applies the MovementTask → Stop derivation, then reconciles hand-back obligations.
    private func cascade(_ stopId: Int) {
        mutate(stopId) { s in
            if let derived = s.derivedTerminal {
                s.status = derived
                // All tasks cancelled → SKIPPED by derivation: the skip's reason is that.
                if derived == .skipped, s.statusReason == nil { s.statusReason = "All tasks cancelled" }
                // The SLA axis outlives the lifecycle one, but a FORECAST does not: a stop that is
                // done is no longer "at risk" of anything. Settling it here means no surface has to
                // remember the rule.
                s.sla = s.sla.settled()
            } else if s.tasks.contains(where: { $0.status == .inProgress }) {
                s.status = .inProgress
            }
        }
        reconcileHandbacks()
    }

    // MARK: - Hand-back derivation (DEC-488 §3 amending DEC-376)

    /// Appends the debrief return leg at the FIRST custody-bound failure so HANDBACK tasks have a
    /// parent stop (MT-INV-1), then keeps exactly one HANDBACK per qualifying task (MT-INV-29 grain).
    ///
    /// A failure only qualifies when the units are genuinely aboard AND the disposition sends them
    /// off-trip. An uncollected pickup never qualifies: there is nothing to hand back.
    private func reconcileHandbacks() {
        guard trip.returnHandoverTaskEnabled else { return }

        let qualifying = trip.stops
            .filter { !$0.isReturnLeg }
            .flatMap(\.tasks)
            .filter(\.isCustodyBoundFailure)

        guard !qualifying.isEmpty else { return }

        if trip.returnLegIndex == nil { appendReturnLeg() }
        guard let legIdx = trip.returnLegIndex else { return }

        let existing = Set(trip.stops[legIdx].tasks.compactMap(\.handbackFor))
        for source in qualifying where !existing.contains(source.id) {
            trip.stops[legIdx].tasks.append(
                V2Task(id: 900 + source.id,
                       orderRef: source.orderRef,
                       kind: .handback,
                       hus: source.hus,
                       tags: source.tags,
                       contactName: "Dock 3, Bay B2",
                       contactSub: "Whitefield Hub",
                       custodyAboard: true,
                       handbackFor: source.id)
            )
            // The same handling units come back — fresh to scan at the hub (99). Built with none,
            // the handback scan list was empty and could never complete.
            trip.stops[legIdx].tasks[trip.stops[legIdx].tasks.count - 1].units =
                source.units.map { var u = $0; u.scanned = false; return u }
        }
    }

    private func appendReturnLeg() {
        let leg = V2Stop(id: 99, seq: trip.stops.count + 1, kind: .handback, config: .handback,
                         title: "IKEA Hub",
                         address: "12, Whitefield Hub Road, Bengaluru, 560066",
                         window: "01:15 PM - 01:45 PM",
                         tasks: [],
                         isReturnLeg: true)
        trip.stops.append(leg)
        resequence()
    }

    // MARK: - Helpers

    private func resequence() {
        for i in trip.stops.indices { trip.stops[i].seq = i + 1 }
    }

    func stop(_ id: Int) -> V2Stop? { trip.stops.first { $0.id == id } }
    func task(_ stopId: Int, _ taskId: Int) -> V2Task? {
        stop(stopId)?.tasks.first { $0.id == taskId }
    }

    private func mutate(_ stopId: Int, _ body: (inout V2Stop) -> Void) {
        guard let i = trip.stops.firstIndex(where: { $0.id == stopId }) else { return }
        body(&trip.stops[i])
    }
}
