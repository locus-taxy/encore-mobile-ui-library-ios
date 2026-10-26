import SwiftUI

// MARK: - Entity → card
//
// A frame in the V2 board is `(surface, entity state)`. These projections are where that pairing is
// written down: an entity says which SLOTS it fills, and `V2CardView` owns every measurement.
//
// Two laws live here rather than in the surfaces, so they cannot be forgotten one screen at a time:
//   • Terminal ⇒ no affordances. A terminal entity projects an empty `actions`/`iconActions`.
//   • The entity a surface is ABOUT gets the copyable eyebrow; a card references ANOTHER entity and
//     therefore gets a plain one (ui-decisions §10/§11).

// MARK: Trip

extension V2Trip {
    /// The progress slot for this trip, in whichever of the four Figma variants applies
    /// (node 2835:228299).
    var progressSlot: V2ProgressSlot {
        switch status {
        case .pendingDispatch:
            // Nothing has happened yet, so there is no bar and no tick — just the plan.
            return V2ProgressSlot(fraction: nil, icon: false, caption: V2Text.stops(stops.count))
        case .inTransit where doneStops == stops.count:
            // Every stop resolved, trip not yet ended (106): the bar gives way to the outcome line.
            return V2ProgressSlot(fraction: nil, caption: "\(V2Text.stops(doneStops)) completed")
        case .inTransit:
            return V2ProgressSlot(fraction: CGFloat(doneStops) / CGFloat(max(1, stops.count)),
                                  caption: "\(doneStops)/\(stops.count) stops completed")
        default:
            return V2ProgressSlot(fraction: nil, caption: "\(V2Text.stops(doneStops)) completed")
        }
    }

    /// Trip row on the delivery list — node 1791:54552.
    func listCard(onTap: @escaping () -> Void) -> V2CardModel {
        V2CardModel(
            shape: .clickable,
            eyebrow: eyebrow,
            chips: status == .pendingDispatch ? [] : [
                V2ChipSlot("status") { V2TripStatusChip(status: status) }
            ],
            headline: "\(window) · \(distance)",
            progress: progressSlot,
            tags: [
                V2ChipSlot("pickups") { HFPillChip(text: "\(pickups) Pickups", glyph: .pickup) },
                V2ChipSlot("deliveries") { HFPillChip(text: "\(deliveries) Deliveries", glyph: .deliver) }
            ],
            // No gutter: a trip card never carries an icon action, and its progress bar spans the
            // card (frame 15). Only cards that CAN show one (stop → navigate) reserve it.
            onTap: onTap)
    }

    /// The header's progress block: absent while collapsed, and absent before dispatch — nothing has
    /// happened yet, so the header states the plan rather than a tally (frame 12 vs 15).
    func progressSlot(collapsed: Bool) -> V2ProgressSlot? {
        (collapsed || status == .pendingDispatch) ? nil : progressSlot
    }

    /// Trip page header — node 10956:673547, which is the card node with the background taken away.
    /// Collapsed (frame 64) keeps only the eyebrow and headline.
    func headerCard(collapsed: Bool,
                    onMap: @escaping () -> Void,
                    onDetails: @escaping () -> Void) -> V2CardModel {
        V2CardModel(
            shape: .card,
            chrome: .plain,
            eyebrow: eyebrow,
            eyebrowEntity: "Trip",
            eyebrowValue: HFEntityID.trip,
            chips: status == .pendingDispatch ? [] : [
                V2ChipSlot("status") { V2TripStatusChip(status: status) }
            ],
            headline: "\(window) · \(distance)",
            headlineLines: 1,
            progress: progressSlot(collapsed: collapsed),
            actions: collapsed ? [] : [
                V2CardAction(id: "map", label: "Map", icon: "LMap", action: onMap),
                V2CardAction(id: "details", label: "View details", isReadOnly: true,
                             action: onDetails)
            ].surviving(terminal: status.isTerminal))
            // No height pin: the header hugs its slots — 140 pending (12), 178 in transit (15),
            // 166 completed (110), 80 collapsed (64). Every inner block is pinned, so each is exact.
    }
}

// MARK: Stop

extension V2Stop {
    /// Stop row on the trip page — node 1791:54552. Navigate is an affordance, so it goes when the
    /// stop reaches a terminal state.
    func listCard(showNavigate: Bool,
                  dispatched: Bool = true,
                  onNavigate: @escaping () -> Void = {},
                  onTap: @escaping () -> Void) -> V2CardModel {
        V2CardModel(
            shape: .clickable,
            eyebrow: eyebrow,
            chips: chipSlots(dispatched: dispatched),
            headline: title,
            headlineVerified: verified,
            // A card always states the plan — `window • n tasks`. How much of it is DONE belongs to
            // the stop's own header, not to a row in someone else's list.
            subtext: "\(window) • \(V2Text.tasks(tasks.count))",
            tags: [
                V2ChipSlot("identifier") { V2StopIdentifierChip(kind: kind) }
            ],
            iconActions: (status.isTerminal || !showNavigate) ? [] : [
                V2CardIconAction(id: "navigate", icon: "LNavigationOutlined", action: onNavigate)
            ],
            reservesGutter: true,
            onTap: onTap)
    }

    /// Stop sheet header — node 11394:723379. Title and address are ONE block here (the node gaps
    /// them at 2), which is why they project into the address slot rather than headline + subtext.
    /// The SLA chip measures against the promise window, so it says nothing until the promise clock
    /// is running: while the trip is still pending dispatch a stop shows NO chips at all, and the
    /// SLA appears the moment the trip goes in transit (frames 12–14 → 15–16). It then persists
    /// through terminal, because by then it is an outcome (§22).
    func chipSlots(dispatched: Bool) -> [V2ChipSlot] {
        guard dispatched else { return [] }
        return [
            V2ChipSlot("status") { V2StopStatusChip(status: status) },
            V2ChipSlot("sla") { V2SlaChip(sla: sla) }
        ]
    }

    func headerCard(dispatched: Bool = true,
                    onNavigate: @escaping () -> Void,
                    exceptionLabel: String?,
                    onException: @escaping () -> Void) -> V2CardModel {
        var actions: [V2CardAction] = []
        if !status.isTerminal {
            actions.append(V2CardAction(id: "navigate", label: "Navigate",
                                        icon: "LNavigationOutlined", action: onNavigate))
            if let exceptionLabel {
                actions.append(V2CardAction(id: "exception", label: exceptionLabel,
                                            role: .danger, action: onException))
            }
        }
        return V2CardModel(
            shape: .card,
            chrome: .plain,
            eyebrow: eyebrow,
            eyebrowEntity: "Stop",
            eyebrowValue: HFEntityID.stop,
            chips: chipSlots(dispatched: dispatched),
            // Name and address hug their copy. The 228 the old pin used was frame 40's CONTENT
            // (two-line name + two-line address), not a reservation — a one-line stop is 186 (17),
            // a failed one with no actions 126 (73), one in progress 266 (57).
            address: V2Address(headline: title, subtext: address, verified: verified),
            subtext: window,
            progress: progressSlot,
            actions: actions)
    }

    /// Only surfaces once work has begun — before that the header states the plan, not the tally.
    var progressSlot: V2ProgressSlot? {
        switch status {
        case .inProgress:
            return V2ProgressSlot(fraction: CGFloat(doneTasks) / CGFloat(max(1, tasks.count)),
                                  caption: "\(doneTasks)/\(tasks.count) tasks completed")
        case .completed:
            return V2ProgressSlot(fraction: nil, caption: "\(V2Text.tasks(doneTasks)) completed")
        default:
            return nil
        }
    }
}

// MARK: Task

extension V2Task {
    /// Task row inside the stop sheet's grouped container. `.plain` chrome because the group — not
    /// the row — owns the white surface and the hairlines between rows.
    func listCard(onTap: @escaping () -> Void) -> V2CardModel {
        V2CardModel(
            shape: .clickable,
            chrome: .plain,
            eyebrow: orderId,
            eyebrowGap: V2Space.taskEyebrowToHeadline,
            chips: [
                V2ChipSlot("status") { V2TaskStatusChip(status: status) }
            ],
            headline: husLabel,
            // No reason pair for now (2026-10-26): the code → display text has no source yet and the
            // driver-side reason is parked (Story 2.1.1, DP-2907). Revisit with product.
            tags: [V2ChipSlot("identifier") { V2TaskIdentifierChip(kind: kind) }]
                + tags.map { tag in
                    V2ChipSlot("tag-\(tag)") {
                        HFPillChip(text: tag, bg: HFColor.screen, fg: HFColor.textSecondary, dot: false)
                    }
                },
            onTap: onTap)
    }
}

extension V2Task {
    /// Task page header — the same node as the stop header. A clubbed task (hub pickup / handback,
    /// frames 26, 99) names the club, not one order: `n CLUBBED ORDERS`, no status chip.
    /// Mark failed is disabled rather than hidden while a partner dwell timer runs (frame 82).
    func headerCard(clubbed: Int?,
                    fallbackTitle: String,
                    dwellBlocked: Bool,
                    onCall: @escaping () -> Void,
                    onMarkFailed: @escaping () -> Void) -> V2CardModel {
        var actions = [V2CardAction(id: "call", label: "Call", icon: "LCall", action: onCall)]
        if status == .inProgress && clubbed == nil {
            actions.append(V2CardAction(id: "fail", label: "Mark failed", role: .danger,
                                        enabled: !dwellBlocked, action: onMarkFailed))
        }
        return V2CardModel(
            shape: .card,
            chrome: .plain,
            eyebrow: clubbed.map { V2Text.clubbedOrders($0) } ?? orderId,
            // Customer-facing order id — the internal task id never surfaces. This page is ABOUT the
            // order, so its eyebrow is the copyable one; a club has no single id to copy.
            eyebrowEntity: clubbed == nil ? "Order" : nil,
            eyebrowValue: clubbed == nil ? HFEntityID.order : nil,
            chips: clubbed != nil ? [] : [
                V2ChipSlot("status") { V2TaskStatusChip(status: status) }
            ],
            address: V2Address(headline: contactName ?? fallbackTitle, subtext: contactSub ?? ""),
            actions: status.isTerminal ? [] : actions)
    }
}

/// A stop whose kind clubs its tasks shows ONE row for the whole stop rather than a row per order.
extension V2Stop {
    func clubbedTaskCard(onTap: @escaping () -> Void) -> V2CardModel {
        let lead = clubbedTasks.first
        return V2CardModel(
            shape: .clickable,
            chrome: .plain,
            eyebrow: V2Text.clubbedOrders(clubbedTasks.count),
            eyebrowGap: V2Space.taskEyebrowToHeadline,
            // NO status chip. A status chip states the status of ONE entity; a clubbed row names n of
            // them, and borrowing the first task's status presents a claim the row cannot make — the
            // others may have diverged. Figma hides `Task Status` on this card outright
            // (node 10956:673365, hidden) and again on the clubbed task-detail header (frame 37).
            // The stop header carries the aggregate status instead, and the per-order rows this card
            // expands into each carry their own.
            headline: "\(totalHUs) HUs",
            tags: [V2ChipSlot("identifier") { V2TaskIdentifierChip(kind: lead?.kind ?? .pickup) }]
                + (lead?.tags ?? []).map { tag in
                    V2ChipSlot("tag-\(tag)") {
                        HFPillChip(text: tag, bg: HFColor.screen, fg: HFColor.textSecondary, dot: false)
                    }
                },
            orderSummary: clubOrderSummary,
            onTap: onTap)
    }

    /// The club's orders grouped by status — the per-order outcome this status-less card can't put in
    /// a chip. Absent while every order is still pending (nothing to summarise yet).
    var clubOrderSummary: [V2OrderSummaryRow] {
        let tasks = clubbedTasks
        guard tasks.contains(where: { $0.status != .pending }) else { return [] }
        let order: [V2TaskStatus] = [.inProgress, .completed, .partial, .failed, .cancelled]
        return order.compactMap { st in
            let group = tasks.filter { $0.status == st }
            guard !group.isEmpty else { return nil }
            let hus = group.reduce(0) { $0 + $1.hus }
            let orders = group.count == 1 ? "1 order" : "\(group.count) orders"
            return V2OrderSummaryRow(status: st, text: "\(orders) (\(hus == 1 ? "1 HU" : "\(hus) HUs"))")
        }
    }
}
