import SwiftUI

// MARK: - Flow root
//
// Everything the flow knows is in two places and nowhere else:
//   • `V2Engine` — entity state. The only thing that mutates a stop or a task.
//   • `V2Router` — which surfaces are showing, as a stack of routes that name entities by id.
//
// No surface holds a copy of an entity, and no intent is parked in a side-channel flag, so going
// back always lands on the live state of whatever the route names.

public struct V2Flow: View {
    @StateObject private var engine = V2Engine()
    @StateObject private var toast = HFToastCenter()
    /// DP-2959 — inbox entries and what they put on screen.
    @StateObject private var notes = V2NotificationCenter()
    /// Prototype-only push panel (shake the device).
    @State private var showsPushPanel = false
    @Environment(\.v2Jump) private var jump
    /// DP-2956 — where the inbox was opened from (Back returns there), and its applied filter.
    @State private var inboxOrigin: V2Route = .home
    @State private var inboxFilter = V2InboxFilter()
    @State private var inboxDemoSelection: Set<Int> = []
    @State private var inboxDemoSwipe: Int? = nil
    @State private var inboxDemoMenu: Int? = nil
    @State private var inboxDemoCollapsed: Set<V2Ago.Group> = []
    @State private var inboxDemoScroll = false
    @State private var filterStartFacet: V2InboxFilterSheet.Facet = .severity
    @State private var showsInboxFilter = false
    @State private var router = V2Router()

    private let demo: String
    /// Prototype time compression for waits (seconds of dwell per real second).
    static let dwellSpeed = 10
    /// The full walk starts at launch (01); a demo entry point jumps straight into a signed-in state.
    @State private var session: V2Session
    @State private var orgId = "ikea-ind-blr03"
    @State private var showsIdP = false
    /// The stop-sheet kebab menu (frame 21).
    @State private var undoMenuOpen = false
    /// The page Profile was opened from, so Back returns there (Home or the Delivery tab).
    @State private var profileOrigin: V2Route = .home
    /// "Loading the trip…" interstitial (36, 54, 72, 89, 103) and what lands once it finishes.
    @State private var loading: String? = nil
    @State private var afterLoading: (() -> Void)? = nil

    public init(demo: String = "") {
        self.demo = demo
        _session = State(initialValue: demo.isEmpty ? .splash : .signedIn)
    }

    private var trip: V2Trip { engine.trip }
    private var stop: V2Stop? { router.stopId.flatMap { id in trip.stops.first { $0.id == id } } }
    private var task: V2Task? {
        guard let stop, let taskId = router.taskId else { return nil }
        return stop.tasks.first { $0.id == taskId }
    }

    public var body: some View {
        Group {
            // Log in and log out are the same fade in opposite directions.
            if session == .signedIn {
                app.transition(.opacity)
            } else {
                login.transition(.opacity)
            }
        }
        // Network alert above everything signed-in, covers and sheets included: it becomes the top of
        // the safe area, so every app bar / sheet title lays out directly under the strip.
        .safeAreaInset(edge: .top, spacing: 0) {
            if session == .signedIn { V2NetworkAlert(center: notes) }
        }
        .environment(\.v2NetworkInset, session == .signedIn && notes.showsNetworkAlert ? V2NetworkAlert.height : 0)
        .environment(\.hfToast, toast)
        // History first, so a demo state can then reshape it.
        .onAppear { notes.seed(V2NotificationCenter.history()) }
        .onAppear(perform: applyDemo)
        .onAppear(perform: scheduleLaunchPushes)
        // The camera holds medium banners; they land on the Scan HUs page once the rider is back out.
        .onChange(of: router.scanner != nil) { notes.holdBanners($0) }
        .environment(\.v2InboxEntry, V2InboxEntry(unread: notes.unread, open: { openInbox() }))
        .environment(\.v2Banner, V2BannerContext(center: notes, onOpen: { openNotification($0) }))
        .onReceive(NotificationCenter.default.publisher(for: .v2DeviceShaken)) { _ in
            guard session == .signedIn else { return }
            V2Motion.txSurface { showsPushPanel = true }
        }
        // One clock for the whole prototype. Dwell runs at `dwellSpeed`× so the partner wait (8:23 in
        // frame 81) can be walked through in under a minute; the copy still shows real minutes.
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            engine.tickDwell(Self.dwellSpeed)
            if let stop, !canUndoArrival(stop) { undoMenuOpen = false }
        }
    }

    // MARK: Session — frames 01–06

    @ViewBuilder private var login: some View {
        switch session {
        case .splash:
            V2SplashPage { V2Motion.txSurface { session = .workspace } }
                .transition(.opacity)
        case .workspace:
            V2WorkspacePage { id in
                orgId = id
                V2Motion.txSurface { session = .credentials; showsIdP = true }
            }
            .transition(.opacity)
        case .credentials:
            V2CredentialsPage(orgId: orgId,
                              onChangeOrg: { V2Motion.txSurface { session = .workspace } },
                              onSSO: { V2Motion.txSurface { showsIdP = true } },
                              onLogIn: { V2Motion.txSurface { session = .loadingApp } })
                .transition(.opacity)
                .overlay {
                    HFBottomSheet(isPresented: showsIdP,
                                  onDismiss: { V2Motion.txSurface { showsIdP = false } }) {
                        V2IdPSheet(onClose: { V2Motion.txSurface { showsIdP = false } },
                                   onContinue: {
                                       V2Motion.txSurface { showsIdP = false; session = .loadingApp }
                                   })
                    }
                }
        case .loadingApp:
            V2LoadingPage(copy: "Loading the app...") {
                router.setPage(.home)
                V2Motion.txSurface { session = .signedIn }
            }
            .transition(.opacity)
        case .signedIn:
            EmptyView()
        }
    }

    // MARK: App — tabs, trip flow, sheets

    // The base page is the ONLY thing in the layout. Every layer above it — stop sheet, workflow
    // cover, scanner, loading, bottom sheets — is an OVERLAY: an overlay is sized to its host and never
    // feeds back into the host's layout. As siblings in one ZStack, any layer that grew (a scrim
    // reaching into the status strip, a sheet mid-rise) re-centred the stack, and the page underneath
    // visibly jumped ~16pt as the stop sheet came up.
    private var app: some View {
        base
        .overlay {
            ZStack {
                V2SheetLayer(isPresented: router.sheetIsPresented,
                             onDismiss: { V2Motion.txSurface { router.dismissToBase() } }) {
                    sheet
                }
                .zIndex(1)

                if let workflow = router.workflow {
                    // The cover rises and sinks once; when one workflow hands to the next (scan →
                    // checklist) the content dissolves inside it instead of cutting.
                    ZStack {
                        workflowSurface(workflow)
                            .id(String(describing: workflow.intent))
                            .transition(V2Motion.dissolve)
                    }
                    // Opaque backing: mid-dissolve both pages are half transparent, and without it
                    // the stop sheet underneath showed through the cross-fade.
                    .background(HFColor.surface)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .transition(V2Motion.riseFromBottom)
                    .zIndex(2)
                }
            }
        }
        // The scanner reaches into the status strip, so it gets an overlay of its own rather than
        // growing the one the sheet and workflow share.
        .overlay {
            ZStack {
                if let scan = router.scanner, let task = engine.subject(scan.stop, scan.task) {
                    V2ScannerPage(task: task,
                                  result: scanResult,
                                  onClose: { closeScanner() },
                                  onRead: { readNextUnit(scan.stop, scan.task) },
                                  onUndo: { undoLastScan(scan.stop, scan.task) })
                        .ignoresSafeArea()
                        .transition(V2Motion.riseFromBottom)
                }
            }
        }
        .overlay {
            ZStack {
                if let loading {
                    V2LoadingPage(copy: loading) {
                        let land = afterLoading
                        afterLoading = nil
                        V2Motion.txSurface { self.loading = nil }
                        land?()
                    }
                    .transition(.opacity)
                }
            }
        }
        .overlay {
            HFBottomSheet(isPresented: router.exceptionStopId != nil,
                          onDismiss: { V2Motion.txSurface { router.dismissModal() } }) {
                V2ExceptionSheet(options: stop?.exceptions ?? [],
                                 onClose: { V2Motion.txSurface { router.dismissModal() } },
                                 onPick: { handleException($0) })
            }
        }
        .overlay {
            HFBottomSheet(isPresented: router.showsTripDetails,
                          onDismiss: { V2Motion.txSurface { router.dismissModal() } }) {
                V2TripDetailsSheet(trip: trip,
                                   onClose: { V2Motion.txSurface { router.dismissModal() } })
            }
        }
        .overlay {
            // 109 — over the now-completed trip page; Got it / ✕ / scrim all land on 110.
            HFBottomSheet(isPresented: router.showsTripSummary, onDismiss: { closeTripSummary() }) {
                V2SummarySheet(title: "Trip summary", sections: trip.summarySections,
                               onClose: { closeTripSummary() },
                               height: V2Layout.drawableHeight - 42) {
                    HFSheetFooter { V2Button(label: "Got it") { closeTripSummary() } }
                }
            }
        }
        .overlay {
            HFBottomSheet(isPresented: router.showsClockIn,
                          onDismiss: { V2Motion.txSurface { router.dismissModal() } }) {
                V2ClockInSheet(shift: engine.shift,
                               onClose: { V2Motion.txSurface { router.dismissModal() } },
                               onSwipe: { clockIn() })
            }
        }
        .overlay {
            HFBottomSheet(isPresented: router.showsClockOut,
                          onDismiss: { V2Motion.txSurface { router.dismissModal() } }) {
                V2SummarySheet(title: "Clock out summary", sections: trip.shiftSections(engine.shift),
                               onClose: { V2Motion.txSurface { router.dismissModal() } }) {
                    HFSheetFooter {
                        V2SwipeCTA(label: "Swipe to end shift \(engine.shift.seq)") { clockOut() }
                    }
                }
            }
        }
        .overlay {
            HFBottomSheet(isPresented: router.showsLogOut,
                          onDismiss: { V2Motion.txSurface { router.dismissModal() } }) {
                V2LogOutSheet(onLogOut: { logOut() },
                              onCancel: { V2Motion.txSurface { router.dismissModal() } })
            }
        }
        .overlay {
            HFBottomSheet(isPresented: showsPushPanel,
                          onDismiss: { V2Motion.txSurface { showsPushPanel = false } }) {
                V2PushPanel(onFire: { sample in
                                V2Motion.txSurface { showsPushPanel = false }
                                // Let the panel sink first, so the arrival reads as its own event.
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { fire(sample) }
                            },
                            onJump: { key in
                                showsPushPanel = false
                                jump?(key)
                            },
                            onClose: { V2Motion.txSurface { showsPushPanel = false } })
            }
        }
        .overlay {
            HFBottomSheet(isPresented: showsInboxFilter,
                          onDismiss: { V2Motion.txSurface { showsInboxFilter = false } }) {
                V2InboxFilterSheet(entries: notes.entries,
                                   applied: inboxFilter,
                                   onApply: { f in
                                       V2Motion.txSurface { inboxFilter = f; showsInboxFilter = false }
                                   },
                                   onClose: { V2Motion.txSurface { showsInboxFilter = false } },
                                   startFacet: filterStartFacet)
            }
        }
        // Top of the stack: an important notification shows over any sheet, cover or the scanner.
        .overlay {
            V2NotificationLayer(center: notes, onOpen: { openNotification($0) })
        }
    }

    // MARK: Notifications — DP-2959

    /// The bell, from whichever app bar it was tapped on. A sibling page like Profile: pushed in from
    /// the trailing edge, Back returns to the origin.
    private func openInbox() {
        if router.page != .inbox { inboxOrigin = router.page }
        V2Motion.txSurface { router.setPage(.inbox) }
    }

    /// Tap-through opens the target in its current state, through the same routing as a push tap
    /// (Story 5.4.2). Whatever was open is closed first; a target that's gone lands where the driver
    /// is with a toast (E-07).
    private func openNotification(_ n: V2Notification) {
        if n.targetGone {
            toast.show("This \(n.target.noun) is no longer available")
            return
        }
        V2Motion.txSurface {
            switch n.target {
            case .none:
                break
            case .shift:
                router.setPage(.home)
            case .trip:
                router.setPage(.trip)
            case .stop(let s):
                router.setPage(.trip)
                router.push(.stop(s))
            case .task(let s, let t):
                router.setPage(.trip)
                router.push(.stop(s))
                router.push(.task(stop: s, task: t))
            }
        }
    }

    /// Stand-ins for what the platform would send, written against the seeded trip.
    private func fire(_ sample: V2PushSample) {
        let cancelled = trip.stops.first { $0.id == 3 }?.tasks.first { $0.id == 31 }
        switch sample {
        case .critical:
            notes.receive(.critical, .alert,
                          subject: "Task cancelled at stop 3",
                          body: "Order \(cancelled?.orderRef ?? "") for \(cancelled?.contactName ?? "the customer") "
                              + "was cancelled by dispatch. Don't hand it over.",
                          target: .task(stop: 3, task: 31))
        case .high:
            notes.receive(.high, .notification,
                          subject: "Delivery window changed at stop 4",
                          body: "Costa Coffee now accepts deliveries until 12:30 PM. Your route order is unchanged.",
                          target: .stop(4))
        case .medium:
            notes.receive(.medium, .notification,
                          subject: "Shift ends in 30 minutes",
                          body: "Your shift ends at 02:00 PM. Finish the stop you're on, then head back to the hub.",
                          target: .shift)
        case .low:
            notes.receive(.low, .notification,
                          subject: "Message from your hub",
                          body: "Gate 1 is closed today. Use Gate 2 when you return.")
        case .gone:
            notes.receive(.high, .notification,
                          subject: "Trip 2 reassigned",
                          body: "Trip 2 was moved to another driver. You don't need to do anything.",
                          target: .trip, targetGone: true)
        case .pair:
            fire(.critical)
            fire(.high)
        case .connection:
            withAnimation(V2Motion.standard) { notes.offline.toggle() }
        case .criticalInfo:
            notes.receive(.critical, .alert,
                          subject: "Vehicle check overdue",
                          body: "Your vehicle check for KA-03-MX-4412 was due before your shift. Complete it at the hub before your next trip.")
        case .tray:
            // The push arrived while the app was closed; the phone showed it and the rider tapped it.
            // The app opens on its target with the entry already read — no takeover, no banner.
            let id = notes.receive(.high, .notification,
                                   subject: "Delivery window changed at stop 4",
                                   body: "Costa Coffee now accepts deliveries until 12:30 PM. Your route order is unchanged.",
                                   target: .stop(4), surface: false)
            notes.markRead([id])
            if let n = notes.entry(id) { openNotification(n) }
        case .mediumInfo:
            notes.receive(.medium, .notification,
                          subject: "Hub closes early today",
                          body: "The hub closes at 06:00 PM. Hand back anything left before then.")
        }
    }

    /// `POC_PUSH=critical,high,medium` — fired after launch so a recording can capture the arrival.
    private func scheduleLaunchPushes() {
        let raw = ProcessInfo.processInfo.environment["POC_PUSH"] ?? ""
        let samples = raw.split(separator: ",").compactMap { V2PushSample(rawValue: String($0)) }
        for (i, s) in samples.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + Double(i) * 0.4) { fire(s) }
        }
    }

    // MARK: Base — law 1, the trip page rises over the trip list

    @ViewBuilder private var base: some View {
        ZStack {
            if router.page == .home {
                V2HomePage(shift: engine.shift, canClockOut: engine.canClockOut,
                           onClockIn: { V2Motion.txSurface { router.push(.clockIn) } },
                           onClockOut: { V2Motion.txSurface { router.push(.clockOut) } },
                           onAvatar: { openProfile() },
                           onTab: selectTab)
                    .transition(.opacity)
                    .zIndex(0)
            }
            if router.page == .inbox {
                V2InboxPage(center: notes,
                            onBack: { V2Motion.txSurface { router.setPage(inboxOrigin) } },
                            onOpen: { openNotification($0) },
                            onFilter: { V2Motion.txSurface { showsInboxFilter = true } },
                            filter: inboxFilter,
                            onResetFilter: { withAnimation(V2Motion.standard) {
                                inboxFilter = V2InboxFilter(status: inboxFilter.status)
                            } },
                            onStatus: { inboxFilter.status = $0 },
                            demoSelection: inboxDemoSelection,
                            demoSwipe: inboxDemoSwipe,
                            demoMenu: inboxDemoMenu,
                            demoCollapsed: inboxDemoCollapsed,
                            demoScrollToEnd: inboxDemoScroll)
                    .transition(V2Motion.pushFromTrailing)
                    .zIndex(2)
            }
            if router.page == .profile {
                V2ProfilePage(onBack: { V2Motion.txSurface { router.setPage(profileOrigin) } },
                              onLogOut: { V2Motion.txSurface { router.push(.logOut) } })
                    .background(HFColor.screen)
                    .transition(V2Motion.pushFromTrailing)
                    .zIndex(2)
            }
            // The list stays put underneath and gets no transition of its own — it is the surface
            // being covered, not one being swapped out. Giving it one makes the two slide past each
            // other instead of reading as one layer over another.
            if router.page == .tripList || router.page == .trip {
                V2TripListPage(trip: trip,
                               shiftSubtitle: engine.shift.appBarSubtitle,
                               onOpenTrip: { V2Motion.txSurface { router.setPage(.trip) } },
                               onAvatar: { openProfile() },
                               onTab: selectTab)
                    // Fades in/out on a tab switch, like Home. Under the trip page it is simply
                    // present — the trip page rises over it and sinks back to it.
                    .transition(.opacity)
                    .zIndex(0)
            }
            if router.page == .trip {
                V2TripPage(trip: trip,
                           onBack: { V2Motion.txSurface { router.setPage(.tripList) } },
                           onOpenStop: { openStop($0) },
                           onViewDetails: { V2Motion.txSurface { router.push(.tripDetails) } },
                           onStartTrip: { startTrip() },
                           onEndTrip: { endTrip() })
                    .background(HFColor.screen)
                    .transition(V2Motion.riseFromBottom)
                    // Pinned stacking order. A view LEAVING a ZStack loses its implicit order, so
                    // without this the list drew over the trip page as it left — Back looked like a
                    // cut instead of the trip page sinking (the reverse of how it rose).
                    .zIndex(1)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: Sheet — law 3, task dissolves inside the same frame

    @ViewBuilder private var sheet: some View {
        if let stop {
            ZStack {
                if let task {
                    V2TaskDetailSheet(stop: stop,
                                      task: task,
                                      isBlocked: engine.isBlocked(task),
                                      dwellBlocked: stop.kind == .partner && stop.dwellSecondsLeft > 0,
                                      onBack: { V2Motion.tx { router.back() } },
                                      onClose: { V2Motion.txSurface { router.dismissToBase() } },
                                      onPrimary: { taskPrimary(stop, task) },
                                      onMarkFailed: { failTask(stop, task) },
                                      onGoToRelated: { goToRelated(stop, task) })
                        .transition(V2Motion.dissolve)
                } else {
                    V2StopSheet(stop: stop,
                                tripStarted: trip.status == .inTransit,
                                canUndoArrival: canUndoArrival(stop),
                                onClose: { V2Motion.txSurface { router.dismissToBase() } },
                                onKebab: { withAnimation(V2Motion.standard) { undoMenuOpen.toggle() } },
                                onOpenTask: { openTask(stop, $0) },
                                onException: { handleException($0) },
                                onExceptionSheet: {
                                    V2Motion.txSurface { router.push(.exceptionSheet(stop: stop.id)) }
                                },
                                onPrimary: { stopPrimary(stop) },
                                menuOpen: undoMenuOpen && canUndoArrival(stop),
                                onUndoArrival: {
                                    withAnimation(V2Motion.standard) { undoMenuOpen = false }
                                    undoArrival(stop)
                                },
                                onDismissMenu: { withAnimation(V2Motion.standard) { undoMenuOpen = false } })
                        .transition(V2Motion.dissolve)
                }
            }
        }
    }

    // MARK: Workflow surfaces
    //
    // Scan brings its own chrome (it has tabs and a counter footer, so the generic cover bar would
    // be a second bar); the checklist intents use the cover.

    @ViewBuilder private func workflowSurface(_ workflow: V2Workflow) -> some View {
        switch workflow.intent {
        case .scanTask(let stopId, let taskId):
            if let task = engine.subject(stopId, taskId) {
                V2ScanPage(task: task,
                           sections: scanSections(stopId, taskId),
                           // Who / where the units are for: the recipient on a customer stop (48),
                           // the hub itself on a clubbed stop (29) — not the dock.
                           subtitle: (stop.map { $0.isClubbed(task) } == true ? task.contactSub : task.contactName)
                               ?? stop?.title ?? "",
                           onClose: { V2Motion.txSurface { router.back() } },
                           onScan: { openScanner(stopId, taskId) },
                           onNext: { completeWorkflow(workflow) },
                           onMarkScanned: { ids in markScanned(stopId, taskId, ids) })
            }
        default:
            // The checklist brings its own bar too — it is a page, not a body inside a cover.
            V2ChecklistPage(model: V2ChecklistModel.forIntent(
                                workflow.intent,
                                stopKind: workflow.stopId.flatMap { engine.stop($0)?.kind }),
                            onClose: { V2Motion.txSurface { router.back() } },
                            onSubmit: { completeWorkflow(workflow) })
        }
    }

    // MARK: Scanner
    //
    // The last read is view state, not entity state — it describes the surface, not the trip — so it
    // lives here and is cleared whenever the scanner layer goes away.
    @State private var scanResult: V2Engine.ScanResult? = nil

    private func openScanner(_ stopId: Int, _ taskId: Int) {
        scanResult = nil
        V2Motion.txSurface { router.push(.scanner(stop: stopId, task: taskId)) }
    }

    private func closeScanner() {
        scanResult = nil
        V2Motion.txSurface { router.back() }
    }

    /// Stands in for a camera read: offers the next unscanned unit's id to the engine, so every
    /// result branch the design draws is reachable from the same call.
    private func readNextUnit(_ stopId: Int, _ taskId: Int) {
        let ids = engine.scope(stopId, taskId)
        guard let hu = engine.nextUnscanned(stopId, scope: ids) else {
            // Nothing left to read — offering a scanned id is what produces frame 18.
            if let last = engine.subject(stopId, taskId)?.units.last {
                V2Motion.tx { scanResult = engine.scan(stopId, scope: ids, last.id) }
            }
            return
        }
        V2Motion.tx { scanResult = engine.scan(stopId, scope: ids, hu.id) }
        if engine.subject(stopId, taskId)?.allScanned == true {
            toast.show("HUs scanned")                          // frame 32 copy
        }
    }

    /// One section per scoped order on a clubbed stop (29); a single task is one headerless section.
    private func scanSections(_ stopId: Int, _ taskId: Int) -> [V2ScanSection] {
        let ids = engine.scope(stopId, taskId)
        let tasks = engine.stop(stopId)?.tasks.filter { ids.contains($0.id) } ?? []
        guard tasks.count > 1 else {
            return [V2ScanSection(id: taskId, title: nil, units: engine.subject(stopId, taskId)?.units ?? [])]
        }
        return tasks.map { V2ScanSection(id: $0.id, title: $0.orderId, units: $0.units) }
    }

    /// Multi-select `Mark scanned` (30 → 32): marks the chosen units, then confirms.
    private func markScanned(_ stopId: Int, _ taskId: Int, _ huIds: [String]) {
        let ids = engine.scope(stopId, taskId)
        V2Motion.tx { for hu in huIds { engine.scan(stopId, scope: ids, hu) } }
        toast.show("HUs scanned")
    }

    private func undoLastScan(_ stopId: Int, _ taskId: Int) {
        guard case .scanned(let hu)? = scanResult else { return }
        V2Motion.tx {
            engine.undoScan(stopId, scope: engine.scope(stopId, taskId), hu.id)
            scanResult = nil
        }
        toast.show("HU scan undone")
    }

    // MARK: - Intents
    //
    // Every one of these ends in `commit`, which repairs the route stack against the new entity
    // state. That is the single place the two halves are reconciled.

    private func commit(_ mutate: () -> Void) {
        mutate()
        router.repair(against: engine.trip)
    }

    private func startTrip() {
        V2Motion.tx { commit { engine.startTrip() } }
        toast.show("Trip \(trip.seq) started")
    }

    /// 106 → 108: End trip opens the completion checklist; the swipe there ends it (→ 109).
    private func endTrip() {
        guard trip.canEndTrip else { return }
        V2Motion.txSurface { router.push(.workflow(V2Workflow(intent: .endTrip))) }
    }

    /// 109 → 110: the summary closes onto the completed trip, and only then is it announced.
    private func closeTripSummary() {
        V2Motion.txSurface { router.dismissModal() }
        toast.show("Trip \(trip.seq) completed")
    }

    // MARK: Shell intents

    private func openProfile() {
        profileOrigin = router.page
        V2Motion.txSurface { router.setPage(.profile) }
    }

    private func selectTab(_ tab: V2AppTab) {
        switch tab {
        case .home:     V2Motion.txSurface { router.setPage(.home) }
        case .delivery: V2Motion.txSurface { router.setPage(.tripList) }
        case .hubOps:   break                          // no Hub ops frames in the board
        }
    }

    private func clockIn() {
        V2Motion.txSurface {
            engine.clockIn()
            router.dismissModal()
        }
        toast.show("Clocked in to Shift \(engine.shift.seq)")
    }

    private func clockOut() {
        V2Motion.txSurface {
            engine.clockOut()
            router.dismissModal()
        }
        toast.show("Clocked out from shift \(engine.shift.seq) at 02:06 PM")
    }

    private func logOut() {
        V2Motion.txSurface { router.dismissModal() }
        engine.reset()
        router.setPage(.home)
        V2Motion.txSurface { session = .workspace }
    }

    /// Runs `land` behind the "Loading the trip…" interstitial, the way the board shows every
    /// checklist resolving (36, 54, 72, 89, 103).
    private func afterTripLoad(_ land: @escaping () -> Void) {
        afterLoading = land
        V2Motion.txSurface { loading = "Loading the trip..." }
    }

    private func openStop(_ stop: V2Stop) {
        V2Motion.txSurface { router.push(.stop(stop.id)) }
    }

    private func openTask(_ stop: V2Stop, _ task: V2Task) {
        V2Motion.tx { router.push(.task(stop: stop.id, task: task.id)) }
    }

    /// The stop-level swipe: pending → en route → arrived, then the partner dwell action.
    private func stopPrimary(_ stop: V2Stop) {
        switch stop.status {
        case .pending:
            V2Motion.tx { commit { engine.startWork(stop.id) } }
            toast.show("En route Stop \(stop.seq)")
        case .enRoute:
            V2Motion.tx { commit { engine.markArrival(stop.id) } }
            toast.show("Arrived at Stop \(stop.seq)")
        case .arrived where stop.kind == .partner:
            V2Motion.tx { commit { engine.startAllTasks(stop.id) } }
            toast.show("Tasks started")
        case .inProgress where stop.kind == .partner:
            V2Motion.tx { commit { engine.failUndeliveredTasks(stop.id) } }
            announceStopOutcome(stop.id)
        default:
            break
        }
    }

    private func taskPrimary(_ stop: V2Stop, _ task: V2Task) {
        switch task.status {
        case .pending:
            if stop.isClubbed(task) {
                let ids = engine.scope(stop.id, task.id)
                V2Motion.tx { commit { engine.startTasks(stop.id, ids) } }
                toast.show("Tasks started")
            } else {
                V2Motion.tx { commit { engine.startTask(stop.id, task.id) } }
                toast.show("Task started")
            }
        case .inProgress:
            V2Motion.txSurface {
                router.push(.workflow(V2Workflow(intent: .scanTask(stop: stop.id, task: task.id))))
            }
        default:
            break
        }
    }

    private func failTask(_ stop: V2Stop, _ task: V2Task) {
        V2Motion.txSurface {
            router.push(.workflow(V2Workflow(intent: .failTask(stop: stop.id, task: task.id))))
        }
    }

    /// The workflow's own intent says what to resolve, so closing the cover with ✕ discards it —
    /// there is nothing left armed to fire against the next entity.
    private func completeWorkflow(_ workflow: V2Workflow) {
        switch workflow.intent {
        case .scanTask(let stopId, let taskId):
            // Frame 21 → 23: `Next` is only enabled once every unit is scanned, and it hands off to
            // the completion checklist rather than completing the task itself.
            guard engine.subject(stopId, taskId)?.allScanned == true else { return }
            V2Motion.txSurface {
                router.back()
                router.push(.workflow(V2Workflow(intent: .completeTask(stop: stopId, task: taskId))))
            }

        case .completeTask(let stopId, let taskId):
            let ids = engine.scope(stopId, taskId)
            afterTripLoad {
                V2Motion.txSurface {
                    commit { engine.completeTasks(stopId, ids) }
                    // Land back on the task page, now terminal, with the stop beneath it — the rider
                    // sees the outcome on the thing they just finished, then backs out (frames 37,
                    // 55, 61 → 38, 57, 62).
                    router.dismissToBase()
                    router.push(.stop(stopId))
                    router.push(.task(stop: stopId, task: taskId))
                }
                announceStopOutcome(stopId)
            }

        case .failTask(let stopId, let taskId):
            afterTripLoad {
                V2Motion.txSurface {
                    commit { engine.failTask(stopId, taskId) }
                    router.dismissToBase()
                    router.push(.stop(stopId))
                }
                announceStopOutcome(stopId)
            }

        case .failStop(let stopId):
            afterTripLoad {
                V2Motion.txSurface {
                    commit { engine.reportStopFailure(stopId) }
                    // 72 → 73: back on the stop, now Failed with its tasks Cancelled.
                    router.dismissToBase()
                    router.push(.stop(stopId))
                }
                toast.show("Stop failed and all planned tasks have been cancelled")
            }

        case .endTrip:
            // 108 → 109: the trip ends under the summary sheet; the toast waits for Got it.
            V2Motion.txSurface {
                commit { engine.endTrip() }
                router.dismissToBase()
                router.push(.tripSummary)
            }
        }
    }

    private func handleException(_ option: V2StopException) {
        guard let stop else { return }
        V2Motion.txSurface { router.dismissModal() }
        switch option {
        case .markFailed:
            V2Motion.txSurface {
                router.push(.workflow(V2Workflow(intent: .failStop(stop: stop.id))))
            }
        case .deferStop:
            V2Motion.txSurface {
                commit { engine.deferStop(stop.id) }
                router.dismissToBase()
            }
            toast.show("Stop deferred")
        }
    }

    /// The blocking task may sit on another stop (the return delivery waits on stop 2's pickup).
    private func goToRelated(_ stop: V2Stop, _ task: V2Task) {
        guard let blocking = task.dependsOn.first,
              let home = trip.stops.first(where: { $0.tasks.contains { $0.id == blocking } })
        else { return }
        // A plain push: Back pops straight to the task that sent the rider here, even across stops
        // (rebuilding the stack sent Back to the other stop instead).
        V2Motion.tx { router.push(.task(stop: home.id, task: blocking)) }
    }

    /// Undo arrival is allowed only while every task is still pending (STOP-INV-13) — and never on
    /// the return-to-hub leg, which Figma draws without a kebab at arrival (frames 97–98): the rider is
    /// back at their own depot, so there is no "arrived at the wrong place" to undo.
    private func canUndoArrival(_ stop: V2Stop) -> Bool {
        stop.kind != .handback
            && stop.status == .arrived && stop.tasks.allSatisfy { $0.status == .pending }
            && stop.undoSecondsLeft > 0
    }

    private func undoArrival(_ stop: V2Stop) {
        V2Motion.tx { commit { engine.undoArrival(stop.id) } }
        toast.show("Unmarked stop \(stop.seq) arrival")
    }

    /// The stop's terminal state is derived, so the toast reports whatever the cascade produced.
    private func announceStopOutcome(_ stopId: Int) {
        guard let s = engine.stop(stopId) else { return }
        switch s.status {
        case .completed: toast.show("Tasks completed")
        case .partial:
            let failed = s.tasks.filter { $0.status == .failed }.count
            toast.show("\(failed) tasks failed and stop marked as partial")
        case .failed:    toast.show("Stop failed and all planned tasks have been cancelled")
        default:         toast.show("Task completed")
        }
    }

    // MARK: Headless entry points

    /// Plays the trip exactly as the board does (frames 17–105), through the engine's own intents,
    /// so every count downstream — progress, return leg, summaries — comes out as Figma draws it:
    /// hub picked up; stop 2 delivered; stop 3 failed (its tasks cancelled); stop 4 partial (O5 done,
    /// O6 + O7 failed); the return leg hands back O3, O6, O7.
    private func runBoardTrip() {
        engine.startWork(1); engine.markArrival(1); engine.startAllTasks(1); engine.completeAllTasks(1)
        engine.startWork(2); engine.markArrival(2); engine.startAllTasks(2); engine.completeAllTasks(2)
        engine.startWork(3); engine.markArrival(3); engine.reportStopFailure(3)
        engine.startWork(4); engine.markArrival(4); engine.startAllTasks(4)
        engine.completeTask(4, 41); engine.failTask(4, 42); engine.failTask(4, 43)
        if let leg = engine.trip.returnLegIndex.map({ engine.trip.stops[$0].id }) {
            engine.startWork(leg); engine.markArrival(leg); engine.startAllTasks(leg)
            engine.completeAllTasks(leg)
        }
    }

    private func applyDemo() {
        switch demo {
        // Shell states.
        case "home":     router.setPage(.home)
        case "clockedin": engine.clockIn(); router.setPage(.home)
        case "profile":  router.setPage(.profile)
        case "logout":   router.setPage(.profile); router.push(.logOut)
        case "clockin":  router.setPage(.home); router.push(.clockIn)
        case "workspace": session = .workspace
        // DP-2956 inbox states.
        case "inbox":          router.setPage(.inbox)
        case "inbox-offline":  notes.offline = true; router.setPage(.inbox)
        case "inbox-empty":    notes.clear(); router.setPage(.inbox)
        case "inbox-filter":   router.setPage(.inbox); showsInboxFilter = true
        case "inbox-filter-type": filterStartFacet = .type; router.setPage(.inbox); showsInboxFilter = true
        case "inbox-collapsed": inboxDemoCollapsed = [.yesterday]; router.setPage(.inbox)
        case "inbox-paging":   inboxDemoScroll = true; router.setPage(.inbox)
        // End to end: what acting on a notification does.
        case "notif-open":     // tap the "Stop added" row → stop 4 opens, the row is read
            router.setPage(.inbox)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if let n = notes.entry(101) { notes.markRead([101]); openNotification(n) }
            }
        case "notif-gone":     // tap the reassigned trip's row → stay put, toast
            router.setPage(.inbox)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if let n = notes.entry(105) { notes.markRead([105]); openNotification(n) }
            }
        case "notif-viewtask": // critical takeover → "View task" → the cancelled task opens
            router.setPage(.home)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { fire(.critical) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                if let n = notes.closeTakeover() { openNotification(n) }
            }
        case "notif-tray":     router.setPage(.home)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { fire(.tray) }
        case "inbox-read":     inboxFilter.status = .read; router.setPage(.inbox)
        case "inbox-unread":   inboxFilter.status = .unread; router.setPage(.inbox)
        case "inbox-swipe-read":   inboxDemoSwipe = 101; router.setPage(.inbox)   // unread → green ✓
        case "inbox-swipe-unread": inboxDemoSwipe = 103; router.setPage(.inbox)   // read → red ⊖
        case "inbox-menu":         inboxDemoMenu = 102; router.setPage(.inbox)
        case "inbox-select-read": inboxDemoSelection = [103, 104]; router.setPage(.inbox)  // all read → Mark unread
        case "inbox-select":   inboxDemoSelection = [101, 103]; router.setPage(.inbox)
        case "inbox-caughtup": notes.markAllRead(); inboxFilter.status = .unread; router.setPage(.inbox)
        case "inbox-nomatch":
            inboxFilter = V2InboxFilter(status: .unread, severity: [.low, .critical])
            notes.markRead(notes.entries.filter { $0.severity == .critical || $0.severity == .low }.map(\.id))
            router.setPage(.inbox)
        // Shift card states (Components → Shift card states). Multi-leg so the rail, GAP and HUB OPS show.
        case "shift-draft", "shift-locked", "shift-late", "shift-ongoing", "shift-noshow", "shift-collapsed":
            // The board's legs (Components → Shift card states), and its marker positions.
            engine.shift.window = "02:00 PM - 06:00 PM"
            engine.shift.legs = [
                V2ShiftLeg(id: 1, kind: .delivery, window: "02:00 PM - 03:00 PM"),
                V2ShiftLeg(id: 2, kind: .delivery, window: "03:00 PM - 04:00 PM"),
                V2ShiftLeg(id: 3, kind: .gap, window: "04:00 PM - 04:30 PM"),
                V2ShiftLeg(id: 4, kind: .hubOps, window: "04:30 PM - 06:00 PM"),
            ]
            switch demo {
            case "shift-draft":   engine.shift.status = .draft
            case "shift-locked":  engine.shift.canClockIn = false
            case "shift-late":    engine.shift.runningLate = true; engine.shift.nowAt = 0.3
            case "shift-ongoing": engine.clockIn(); engine.shift.nowAt = 2.39
            case "shift-noshow":  engine.shift.status = .noShow
            default: break
            }
            router.setPage(.home)
        // Clubbed card with its order summary (orders in progress), and a cancelled task with its reason.
        case "clubsummary":
            engine.startTrip(); engine.startWork(1); engine.markArrival(1); engine.startAllTasks(1)
            router.setPage(.trip); router.push(.stop(1))
        case "cancelreason":
            engine.startTrip()
            for s in [1, 2] {
                engine.startWork(s); engine.markArrival(s); engine.startAllTasks(s); engine.completeAllTasks(s)
            }
            engine.startWork(3); engine.markArrival(3); engine.reportStopFailure(3)
            router.setPage(.trip); router.push(.stop(3))
        case "credentials": session = .credentials; showsIdP = true
        // Every stop resolved, End trip enabled (106).
        case "tripend", "summary", "clockout", "shiftdone", "empty":
            engine.clockIn(); engine.startTrip()
            runBoardTrip()
            router.setPage(.trip)
            if demo == "summary" { engine.endTrip(); router.push(.tripSummary) }
            if demo == "empty" { engine.endTrip(); router.setPage(.tripList) }
            if demo == "clockout" { engine.endTrip(); router.setPage(.home); router.push(.clockOut) }
            if demo == "shiftdone" { engine.endTrip(); engine.clockOut(); router.setPage(.home) }
        // Arrived at a hub stop, undo window running, kebab menu open (21).
        case "undo":
            engine.startTrip(); engine.startWork(1); engine.markArrival(1)
            router.setPage(.trip); router.push(.stop(1)); undoMenuOpen = true
        // Partner stop in progress with the dwell clock running (81).
        case "dwell":
            engine.startTrip()
            for s in [1, 2, 3] {
                engine.startWork(s); engine.markArrival(s); engine.startAllTasks(s); engine.completeAllTasks(s)
            }
            engine.startWork(4); engine.markArrival(4); engine.startAllTasks(4)
            router.setPage(.trip); router.push(.stop(4))
        // Clubbed pickup task page, all orders in progress (27).
        case "clubtask":
            engine.startTrip(); engine.startWork(1); engine.markArrival(1); engine.startAllTasks(1)
            router.setPage(.trip); router.push(.stop(1)); router.push(.task(stop: 1, task: 11))
        // Opens the scanner over the scan page after launch, to record its rise.
        case "scanner-anim":
            engine.startTrip(); engine.startWork(1); engine.markArrival(1); engine.startAllTasks(1)
            router.setPage(.trip); router.push(.stop(1)); router.push(.task(stop: 1, task: 11))
            router.push(.workflow(V2Workflow(intent: .scanTask(stop: 1, task: 11))))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { openScanner(1, 11) }
        // Scanner before the first read (49).
        case "scanner0":
            engine.startTrip(); engine.startWork(1); engine.markArrival(1); engine.startAllTasks(1)
            router.setPage(.trip); router.push(.stop(1)); router.push(.task(stop: 1, task: 11))
            router.push(.workflow(V2Workflow(intent: .scanTask(stop: 1, task: 11))))
            router.push(.scanner(stop: 1, task: 11))
        // Return hub before it is worked: the return delivery card + the hand-back club (92–94).
        case "returnhub":
            engine.clockIn(); engine.startTrip()
            engine.startWork(1); engine.markArrival(1); engine.startAllTasks(1); engine.completeAllTasks(1)
            engine.startWork(2); engine.markArrival(2); engine.startAllTasks(2); engine.completeAllTasks(2)
            engine.startWork(3); engine.markArrival(3); engine.reportStopFailure(3)
            engine.startWork(4); engine.markArrival(4); engine.startAllTasks(4)
            engine.completeTask(4, 41); engine.failTask(4, 42); engine.failTask(4, 43)
            router.setPage(.trip); router.push(.stop(99))
        // Opens a stop sheet after launch through the real handler, so the presentation can be
        // recorded headlessly.
        case "stop-anim":
            engine.startTrip(); router.setPage(.trip)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if let s = engine.stop(1) { openStop(s) }
            }
        // Round trip for recording: task page → scan cover rises → hands to the checklist → closes.
        case "roundtrip":
            engine.startTrip(); engine.startWork(1); engine.markArrival(1); engine.startAllTasks(1)
            if let units = engine.subject(1, 11)?.units {
                for u in units { engine.scan(1, scope: engine.scope(1, 11), u.id) }
            }
            router.setPage(.trip); router.push(.stop(1)); router.push(.task(stop: 1, task: 11))
            let scanFlow = V2Workflow(intent: .scanTask(stop: 1, task: 11))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                V2Motion.txSurface { router.push(.workflow(scanFlow)) }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { completeWorkflow(scanFlow) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) { V2Motion.txSurface { router.back() } }
        // Opens the trip page over the list, then goes back, to record both directions.
        case "trip-anim":
            engine.startTrip(); router.setPage(.tripList)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { V2Motion.txSurface { router.setPage(.trip) } }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { V2Motion.txSurface { router.setPage(.tripList) } }
        // Transition tour for recording: every open is followed by its close, 1.4 s apart.
        case "tour":
            engine.clockIn(); engine.startTrip(); engine.startWork(2); engine.markArrival(2)
            router.setPage(.tripList)
            let steps: [() -> Void] = [
                { V2Motion.txSurface { router.setPage(.trip) } },              // 1 trip rises
                { V2Motion.txSurface { router.setPage(.tripList) } },          // 2 trip sinks
                { openProfile() },                                             // 3 profile pushes in
                { V2Motion.txSurface { router.setPage(profileOrigin) } },      // 4 profile pushes out
                { selectTab(.home) },                                          // 5 fade to home
                { selectTab(.delivery) },                                      // 6 fade to delivery
                { V2Motion.txSurface { router.setPage(.trip) } },              // 7 trip rises
                { V2Motion.txSurface { router.push(.stop(2)) } },              // 8 stop sheet rises
                { V2Motion.tx { router.push(.task(stop: 2, task: 21)) } },     // 9 task dissolves in
                { V2Motion.tx { router.back() } },                             // 10 task dissolves out
                { V2Motion.txSurface { router.push(.exceptionSheet(stop: 2)) } }, // 11 issues sheet rises
                { V2Motion.txSurface { router.dismissModal() } },              // 12 issues sheet sinks
                { V2Motion.txSurface { router.dismissToBase() } },             // 13 stop sheet sinks
                { V2Motion.txSurface { router.push(.tripDetails) } },          // 14 details rises
                { V2Motion.txSurface { router.dismissModal() } },              // 15 details sinks
                { V2Motion.txSurface { router.setPage(.home) } },              // 16 to home
                { V2Motion.txSurface { router.push(.clockOut) } },             // 17 clock-out rises
                { V2Motion.txSurface { router.dismissModal() } },              // 18 clock-out sinks
                { openProfile() },                                             // 19 profile
                { V2Motion.txSurface { router.push(.logOut) } },               // 20 log-out rises
                { V2Motion.txSurface { router.dismissModal() } },              // 21 log-out sinks
            ]
            for (i, step) in steps.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + 1.4 * Double(i), execute: step)
            }
        case "logout-anim":
            router.setPage(.profile)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { V2Motion.txSurface { router.push(.logOut) } }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { V2Motion.txSurface { router.dismissModal() } }
        case "trip":     router.setPage(.trip)
        // Stop opened while the trip is still pending dispatch: there must be no way to start work.
        case "gate":     router.setPage(.trip); router.push(.stop(1))
        case "started":  engine.startTrip(); router.setPage(.trip)
        case "stop":     engine.startTrip(); router.setPage(.trip); router.push(.stop(1))
        case "task":
            engine.startTrip()
            router.setPage(.trip)
            router.push(.stop(2)); router.push(.task(stop: 2, task: 21))
        case "arrived":
            engine.startTrip(); engine.startWork(2); engine.markArrival(2)
            router.setPage(.trip); router.push(.stop(2))
        case "exception":
            engine.startTrip(); engine.startWork(3); engine.markArrival(3)
            router.setPage(.trip)
            router.push(.stop(3)); router.push(.exceptionSheet(stop: 3))
        case "scan", "scanner", "scanned":
            engine.startTrip()
            engine.startWork(1); engine.markArrival(1); engine.startAllTasks(1)
            router.setPage(.trip)
            router.push(.stop(1)); router.push(.task(stop: 1, task: 11))
            if demo == "scanned", let units = engine.subject(1, 11)?.units {
                for u in units { engine.scan(1, scope: engine.scope(1, 11), u.id) }
            }
            router.push(.workflow(V2Workflow(intent: .scanTask(stop: 1, task: 11))))
            if demo == "scanner" {
                router.push(.scanner(stop: 1, task: 11))
                let ids = engine.scope(1, 11)
                scanResult = engine.scan(1, scope: ids, engine.nextUnscanned(1, scope: ids)?.id ?? "")
            }
        case "details":
            engine.startTrip(); router.setPage(.trip); router.push(.tripDetails)
        // Presents the sheet AFTER launch, through the same transaction a tap uses, so the
        // presentation animation can be recorded headlessly.
        // Starts the trip through the same handler the swipe fires, so the footer swap and the
        // toast's entry can be recorded headlessly.
        case "toast-anim":
            router.setPage(.trip)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { startTrip() }
        case "details-anim":
            engine.startTrip(); router.setPage(.trip)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                V2Motion.txSurface { router.push(.tripDetails) }
            }
        case "checklist":
            engine.startTrip()
            engine.startWork(1); engine.markArrival(1); engine.startAllTasks(1)
            router.setPage(.trip)
            router.push(.stop(1)); router.push(.task(stop: 1, task: 11))
            if let units = engine.subject(1, 11)?.units {
                for u in units { engine.scan(1, scope: engine.scope(1, 11), u.id) }
            }
            router.push(.workflow(V2Workflow(intent: .completeTask(stop: 1, task: 11))))
        case "failtask":
            engine.startTrip()
            engine.startWork(2); engine.markArrival(2); engine.startTask(2, 21)
            router.setPage(.trip)
            router.push(.stop(2)); router.push(.task(stop: 2, task: 21))
            router.push(.workflow(V2Workflow(intent: .failTask(stop: 2, task: 21))))
        // Drives the whole task chain through the SAME intents the UI fires — scan → checklist →
        // complete — so the handoff between workflows is exercised without needing taps.
        case "e2e":
            engine.startTrip()
            engine.startWork(1); engine.markArrival(1); engine.startAllTasks(1)
            router.setPage(.trip); router.push(.stop(1)); router.push(.task(stop: 1, task: 11))
            if let units = engine.subject(1, 11)?.units {
                for u in units { engine.scan(1, scope: engine.scope(1, 11), u.id) }
            }
            let scan = V2Workflow(intent: .scanTask(stop: 1, task: 11))
            router.push(.workflow(scan))
            completeWorkflow(scan)                       // → the completion checklist
            if let next = router.workflow { completeWorkflow(next) }   // → task completed
        case "handback":
            // Fail stop 3, then partial stop 4 — the return leg should appear and accumulate.
            engine.startTrip()
            engine.startWork(3); engine.markArrival(3); engine.reportStopFailure(3)
            engine.startWork(4); engine.markArrival(4); engine.startAllTasks(4)
            engine.completeTask(4, 41)
            engine.failTask(4, 42); engine.failTask(4, 43)
            router.setPage(.trip)
        default: break
        }
        router.repair(against: engine.trip)
    }
}
