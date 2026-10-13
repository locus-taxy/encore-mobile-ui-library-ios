import SwiftUI

// MARK: - Happy Flow V2 — stateful, in-place rerendering
//
// V1 swapped a whole screen on every action. V2 follows the interaction grammar
// (ui-decisions #15–17): an entity surface holds its own state and **advances it
// in place** (content cross-fades on the same surface); the page/surface only
// changes when a **card is tapped** — Home→Trip (push), Trip→Stop (full-page
// bottom sheet), Stop→Task (dissolve inside the sheet). X / drag-down abandons a
// sheet back to its base, state preserved; back steps one level.
//
// Per-state content reuses the faithful Figma frames (HFScreenNN) so fidelity is
// kept; the flow-state model just picks which frame renders on each surface.

enum HFTripState { case preStart, started, checklist, inTransit, completed }
enum HFStopState { case pre, enRoute, reached, arrived, inProgress, completed }
enum HFTaskKind { case delivery, pickup }
enum HFTaskPhase { case ready, inProgress, pod, done }
/// Full-screen covers presented over the base/sheet: trip view-details (03), Google-Maps
/// hand-off (08 far / 10 near), arrived-stop undo-arrival menu (13).
enum HFOverlay: Equatable { case details, mapFar, mapNear, stopMenu }

final class HFFlowState: ObservableObject {
    // base
    @Published var onTrip = false
    @Published var tripCompleted = false
    @Published var trip: HFTripState = .preStart
    // stop sheet
    @Published var stopPresented = false
    @Published var stop: HFStopState = .pre
    // task detail (dissolve inside the stop sheet)
    @Published var activeTask: HFTaskKind? = nil
    @Published var delivery: HFTaskPhase = .ready
    @Published var pickup: HFTaskPhase = .ready
    // full-screen cover (view-details / maps / undo-arrival menu) + arrived resting variant (15)
    @Published var overlay: HFOverlay? = nil
    @Published var arrivedResting = false

    private func tx(_ b: () -> Void) { withAnimation(.easeInOut(duration: 0.25)) { b() } }

    // overlays
    func present(_ o: HFOverlay) { tx { overlay = o } }
    func dismissOverlay()        { tx { overlay = nil } }
    /// Undo-arrival menu closed → arrived stop settles into its resting state (screen 15).
    func closeStopMenu()         { tx { overlay = nil; arrivedResting = true } }

    // base transitions (card taps / commits)
    func enterTrip()  { tx { onTrip = true } }
    func leaveTrip()  { tx { onTrip = false } }
    func endTrip()    { tx { onTrip = false; tripCompleted = true } }
    func restart()    { tx { onTrip = false; tripCompleted = false; trip = .preStart
                              stopPresented = false; stop = .pre; activeTask = nil
                              delivery = .ready; pickup = .ready
                              overlay = nil; arrivedResting = false } }

    // stop sheet present / dismiss (drill / abandon)
    func presentStop() { tx { stop = .pre; stopPresented = true } }
    func dismissStop() { tx { stopPresented = false } }   // state held; re-open resumes
    func completeStop(){ tx { stopPresented = false; trip = .completed } }

    // task drill / close (dissolve within the sheet)
    func openTask(_ i: Int) { tx { activeTask = (i == 1 ? .pickup : .delivery) } }
    func closeTask()        { tx { activeTask = nil } }

    private var bothDone: Bool { delivery == .done && pickup == .done }

    func finishDelivery() {
        tx { delivery = .done; activeTask = nil
             stop = bothDone ? .completed : .inProgress }
    }
    func finishPickup() {
        tx { pickup = .done; activeTask = nil
             stop = bothDone ? .completed : .inProgress }
    }

    // in-place state advances (same surface rerenders)
    func advanceTrip(_ s: HFTripState) { tx { trip = s } }
    func advanceStop(_ s: HFStopState) { tx { stop = s } }
    func advanceDelivery(_ p: HFTaskPhase) { tx { delivery = p } }
    func advancePickup(_ p: HFTaskPhase)   { tx { pickup = p } }
}

public struct HFFlowV2: View {
    @StateObject private var s = HFFlowState()
    @StateObject private var toast = HFToastCenter()
    public init() {}

    public var body: some View {
        ZStack {
            base
                .zIndex(0)
            if s.stopPresented {
                stopSheet
                    .zIndex(1)
                    .transition(.move(edge: .bottom))
                    .gesture(dragToDismiss)
            }
            // Full-screen covers (maps, undo-arrival menu). View-details is a modal bottom sheet
            // handled separately below so the real page shows through the scrim.
            if let o = s.overlay, o != .details {
                overlayCover(o)
                    .zIndex(2)
                    .transition(o == .stopMenu ? .opacity : .move(edge: .bottom))
            }
        }
        // Modal bottom sheet over the current page (scrim + sliding sheet).
        .overlay {
            HFBottomSheet(isPresented: s.overlay == .details, onDismiss: { s.dismissOverlay() }) {
                HFViewDetailsSheet(onClose: { s.dismissOverlay() })
            }
        }
        // Sheets/screens pin their sticky footer to the physical bottom (no safe-area gap below).
        .ignoresSafeArea(.container, edges: .bottom)
        // Copyable page-header eyebrows call this to copy the entity ID + show a toast.
        .environment(\.hfCopyEntity) { entity, id in toast.copy(label: entity, id: id) }
        // Sticky footers host the toast so it rises from behind the button and sinks back under it.
        .environment(\.hfToast, toast)
        // Leaf controls → flow-level presentations (see HFOverlay).
        .environment(\.hfViewDetails, { s.present(.details) })
        .environment(\.hfNavigate, { s.present(s.stop == .reached ? .mapNear : .mapFar) })
        .environment(\.hfStopMenu, { s.present(.stopMenu) })
        // Preview hook: HF_DEMO=trip,toast opens the trip page and fires a copy toast for headless QA.
        .onAppear {
            if let demo = ProcessInfo.processInfo.environment["HF_DEMO"] {
                if demo.contains("trip") { s.enterTrip() }
                if demo.contains("stop") { s.enterTrip(); s.presentStop() }
                if demo.contains("details") { s.enterTrip(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { s.present(.details) } }
                if demo.contains("toast") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        toast.copy(label: "Trip", id: HFEntityID.trip)
                    }
                }
            }
        }
        // Animation is driven once, explicitly, by HFFlowState.tx(withAnimation);
        // no stacked implicit .animation() modifiers (they compound and cause jank).
    }

    // Drag-down on the sheet ≡ X (abandon to base, state held) — ui-decisions #16.
    private var dragToDismiss: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { v in if v.translation.height > 120 { s.dismissStop() } }
    }

    // MARK: full-screen covers (view-details / maps / undo-arrival menu)

    @ViewBuilder private func overlayCover(_ o: HFOverlay) -> some View {
        switch o {
        case .details:
            EmptyView()   // handled by the HFBottomSheet overlay
        case .mapFar:
            HFScreen08(onPrimary: { s.dismissOverlay() }, onSecondary: { _ in }, onClose: { s.dismissOverlay() })
        case .mapNear:
            HFScreen10(onPrimary: { s.dismissOverlay() }, onSecondary: { _ in }, onClose: { s.dismissOverlay() })
        case .stopMenu:
            HFScreen13(onPrimary: { }, onSecondary: { i in s.dismissOverlay(); s.openTask(i) },
                       onClose: { s.closeStopMenu() })
        }
    }

    // MARK: base surface (Home ↔ Trip)

    @ViewBuilder private var base: some View {
        if s.onTrip {
            tripSurface
                .transition(.move(edge: .trailing))    // push right→left
        } else if s.tripCompleted {
            HFScreen28(onSecondary: { _ in s.restart() })
        } else {
            HFHome(onSecondary: { _ in s.enterTrip() })
        }
    }

    // MARK: trip surface — status advances in place

    private var tripSurface: some View {
        tripFrame
            .id("trip-\(String(describing: s.trip))")
            .transition(.opacity)                       // in-place cross-fade
    }

    @ViewBuilder private var tripFrame: some View {
        switch s.trip {
        case .preStart:
            // Stop card is tappable even pre-start — opens the stop page view-only (CTA gated).
            HFScreen02(onPrimary: { s.advanceTrip(.started); toast.show("Trip 1 started") },
                       onSecondary: { _ in s.presentStop() }, onClose: { s.leaveTrip() })
        case .started:
            HFScreen04(onPrimary: { s.advanceTrip(.checklist) },
                       onSecondary: { _ in }, onClose: { s.leaveTrip() })
        case .checklist:
            HFScreen05(onPrimary: { s.advanceTrip(.inTransit) },
                       onSecondary: { _ in }, onClose: { s.advanceTrip(.preStart) })
        case .inTransit:
            HFScreen06(onPrimary: { }, onSecondary: { _ in s.presentStop() },
                       onClose: { s.leaveTrip() })
        case .completed:
            HFScreen27(onPrimary: { s.endTrip() }, onSecondary: { _ in },
                       onClose: { s.leaveTrip() })
        }
    }

    // MARK: stop sheet — stop status in place; task detail dissolves in

    @ViewBuilder private var stopSheet: some View {
        ZStack {
            if s.activeTask != nil {
                taskFrame
                    .id("task-\(String(describing: s.activeTask))-\(taskPhaseKey)")
                    .transition(.opacity)               // dissolve, same height
            } else {
                stopFrame
                    .id("stop-\(String(describing: s.stop))")
                    .transition(.opacity)               // in-place cross-fade
            }
        }
    }

    @ViewBuilder private var stopFrame: some View {
        switch s.stop {
        case .pre:
            // Gate the "start work" CTA until the trip is actually started.
            HFScreen07(onPrimary: { s.advanceStop(.enRoute) },
                       onSecondary: { _ in }, onClose: { s.dismissStop() },
                       ctaEnabled: s.trip != .preStart,
                       ctaCaption: s.trip == .preStart ? "Trip not started yet" : nil)
        case .enRoute:
            HFScreen09(onPrimary: { s.advanceStop(.reached) },
                       onSecondary: { _ in }, onClose: { s.dismissStop() })
        case .reached:
            HFScreen11(onPrimary: { s.advanceStop(.arrived); toast.show("Arrived stop 1 at HH:MM") },
                       onSecondary: { _ in }, onClose: { s.dismissStop() })
        case .arrived:
            // Kebab → undo-arrival menu (13); once dismissed the stop rests (15). Kebab wiring
            // is via the shared HFStopAppBar/HFTitleBar → \.hfStopMenu.
            if s.arrivedResting {
                HFScreen15(onPrimary: { }, onSecondary: { i in s.openTask(i) },
                           onClose: { s.dismissStop() })
            } else {
                HFScreen12(onPrimary: { }, onSecondary: { i in s.openTask(i) },
                           onClose: { s.dismissStop() })
            }
        case .inProgress:
            HFScreen21(onPrimary: { }, onSecondary: { i in s.openTask(i) },
                       onClose: { s.dismissStop() })
        case .completed:
            HFScreen26(onPrimary: { s.completeStop() }, onSecondary: { _ in },
                       onClose: { s.dismissStop() })
        }
    }

    private var taskPhaseKey: String {
        switch s.activeTask {
        case .delivery: return String(describing: s.delivery)
        case .pickup:   return String(describing: s.pickup)
        case .none:     return "none"
        }
    }

    @ViewBuilder private var taskFrame: some View {
        switch s.activeTask {
        case .delivery: deliveryFrame
        case .pickup:   pickupFrame
        case .none:     EmptyView()
        }
    }

    @ViewBuilder private var deliveryFrame: some View {
        switch s.delivery {
        case .ready:
            HFScreen16(onPrimary: { s.advanceDelivery(.inProgress) },
                       onSecondary: { _ in }, onClose: { s.closeTask() })
        case .inProgress:
            HFScreen17(onPrimary: { s.advanceDelivery(.pod) },
                       onSecondary: { _ in }, onClose: { s.closeTask() })
        case .pod:
            HFScreen18(onPrimary: { s.advanceDelivery(.done) },
                       onSecondary: { _ in }, onClose: { s.closeTask() })
        case .done:
            // Screen 20 = delivery completed (resting); its action finishes the task → back to stop.
            HFScreen20(onPrimary: { s.finishDelivery() },
                       onSecondary: { _ in }, onClose: { s.closeTask() })
        }
    }

    @ViewBuilder private var pickupFrame: some View {
        switch s.pickup {
        case .ready:
            HFScreen22(onPrimary: { s.advancePickup(.inProgress) },
                       onSecondary: { _ in }, onClose: { s.closeTask() })
        case .inProgress:
            HFScreen23(onPrimary: { s.advancePickup(.pod) },
                       onSecondary: { _ in }, onClose: { s.closeTask() })
        case .pod:
            HFScreen24(onPrimary: { s.finishPickup() },
                       onSecondary: { _ in }, onClose: { s.closeTask() })
        case .done:
            HFScreen24(onPrimary: { s.finishPickup() },
                       onSecondary: { _ in }, onClose: { s.closeTask() })
        }
    }
}
