import SwiftUI

// MARK: - Navigation as a stack of routes
//
// The rule this file exists to enforce: **a route names an entity by id and nothing else.** No route
// carries a copy of a stop or a task, so every surface re-reads the live entity from `V2Engine` on
// each render. That is what makes "go back and the entity still holds the right state" structural
// rather than something each screen has to remember to do.
//
// It also removes the side-channel `pending…` flags the flow used to keep next to the workflow cover.
// What a workflow RESOLVES now travels inside the route, so abandoning the cover discards the intent
// with it instead of leaving it armed for whatever opens next.

/// What a full-pager workflow will do to the entity state when its CTA completes.
enum V2WorkflowIntent: Equatable {
    /// Scan the units for a task, then hand off to its completion checklist.
    case scanTask(stop: Int, task: Int)
    case completeTask(stop: Int, task: Int)
    case failTask(stop: Int, task: Int)
    case failStop(stop: Int)
    /// Trip completion checklist (108) → ends the trip.
    case endTrip
}

struct V2Workflow: Equatable {
    var intent: V2WorkflowIntent

    var title: String {
        switch intent {
        case .scanTask:     return "Scan HUs"
        case .completeTask: return "Task checklist"
        case .failTask:     return "Report task failure"
        case .failStop:     return "Mark stop as failed"
        case .endTrip:      return "Trip completion checklist"
        }
    }

    var cta: String {
        switch intent {
        case .scanTask:     return "Next"
        case .completeTask: return "Swipe to complete task"
        case .failTask:     return "Swipe to mark failed"
        case .failStop:     return "Swipe to mark failed"
        case .endTrip:      return "Swipe to end trip"
        }
    }

    /// The task an intent was opened from, if it has one.
    var taskId: Int? {
        switch intent {
        case .scanTask(_, let t), .completeTask(_, let t), .failTask(_, let t): return t
        case .failStop, .endTrip: return nil
        }
    }

    /// The stop every intent belongs to — used to repair the stack when that stop disappears.
    /// Trip-level intents belong to none.
    var stopId: Int? {
        switch intent {
        case .scanTask(let s, _), .completeTask(let s, _), .failTask(let s, _): return s
        case .failStop(let s): return s
        case .endTrip: return nil
        }
    }
}

enum V2Route: Equatable {
    /// Base pages — law 1, one dissolves into the other. Home and the trip list are the two tabs;
    /// Profile is pushed over a tab and backs out to Home.
    case home
    case tripList
    case trip
    case profile
    /// Law 2 — a stop is a subset of the trip, so it rises as a sheet over it.
    case stop(Int)
    /// Law 3 — the task dissolves into the sheet's own real estate.
    case task(stop: Int, task: Int)
    /// Law 4 — a workflow takes the whole screen.
    case workflow(V2Workflow)
    /// The camera scanner, over the scan page it was opened from.
    case scanner(stop: Int, task: Int)
    /// Modals that sit over whatever is showing.
    case exceptionSheet(stop: Int)
    case tripDetails
    case tripSummary
    case clockIn
    case clockOut
    case logOut

    /// A base page owns the screen; everything else is layered over one.
    var isBasePage: Bool {
        switch self {
        case .home, .tripList, .trip, .profile: return true
        default: return false
        }
    }
}

struct V2Router {
    private(set) var stack: [V2Route] = [.tripList]

    var current: V2Route { stack.last ?? .tripList }

    // MARK: Resolution — the topmost route that names each thing

    /// The base page under everything.
    var page: V2Route { stack.last(where: \.isBasePage) ?? .tripList }

    var stopId: Int? {
        for route in stack.reversed() {
            switch route {
            case .stop(let s), .task(let s, _), .exceptionSheet(let s), .scanner(let s, _): return s
            case .workflow(let w):
                if let s = w.stopId { return s }
            default: continue
            }
        }
        return nil
    }

    var taskId: Int? {
        for route in stack.reversed() {
            if case .task(_, let t) = route { return t }
        }
        return nil
    }

    var workflow: V2Workflow? {
        for route in stack.reversed() {
            if case .workflow(let w) = route { return w }
        }
        return nil
    }

    /// The scanner is its own layer over the scan page, so it resolves separately from `workflow`.
    var scanner: (stop: Int, task: Int)? {
        if case .scanner(let s, let t) = current { return (s, t) }
        return nil
    }

    var exceptionStopId: Int? {
        if case .exceptionSheet(let s) = current { return s }
        return nil
    }

    var showsTripDetails: Bool { current == .tripDetails }
    var showsTripSummary: Bool { current == .tripSummary }
    var showsClockIn: Bool { current == .clockIn }
    var showsClockOut: Bool { current == .clockOut }
    var showsLogOut: Bool { current == .logOut }

    /// True while a stop sheet (or anything layered on it) is showing. A workflow cover rises OVER the
    /// sheet and leaves it in place — hiding it made the sheet sink as the cover rose and rise again as
    /// it closed: two surfaces moving where one should.
    var sheetIsPresented: Bool { stopId != nil }

    // MARK: Moves

    mutating func push(_ route: V2Route) {
        guard current != route else { return }
        stack.append(route)
    }

    /// Swap the base page. `tripList → trip` is a dissolve, not a push: there is nothing to come
    /// back to *through* the trip page, only the list itself.
    mutating func setPage(_ route: V2Route) {
        stack = [route]
    }

    /// Back = one step. This is the ONLY back: task → stop → base page.
    mutating func back() {
        guard stack.count > 1 else { return }
        stack.removeLast()
    }

    /// ✕ or drag-down = abandon the whole layer stack down to the base page (ui-decisions §16).
    mutating func dismissToBase() {
        while let last = stack.last, !last.isBasePage {
            stack.removeLast()
        }
    }

    /// Close just the topmost modal (exception sheet / trip details) without touching the sheet
    /// underneath it.
    mutating func dismissModal() {
        switch current {
        case .exceptionSheet, .tripDetails, .tripSummary, .clockIn, .clockOut, .logOut:
            stack.removeLast()
        default:
            break
        }
    }

    // MARK: Repair
    //
    // Called after every engine mutation. A route that names an entity which no longer exists — a
    // task cancelled by its stop failing, a stop dropped from the plan — cannot render, so it pops
    // instead of leaving a surface pointed at nothing.

    mutating func repair(against trip: V2Trip) {
        stack = stack.filter { route in
            switch route {
            case .home, .tripList, .trip, .profile, .tripDetails, .tripSummary, .clockIn, .clockOut, .logOut:
                return true
            case .stop(let s), .exceptionSheet(let s):
                return trip.stops.contains { $0.id == s }
            case .scanner(let s, let t):
                return trip.stops.first { $0.id == s }?.tasks.contains { $0.id == t } ?? false
            case .task(let s, let t):
                return trip.stops.first { $0.id == s }?.tasks.contains { $0.id == t } ?? false
            case .workflow(let w):
                switch w.intent {
                case .scanTask(let s, let t), .completeTask(let s, let t), .failTask(let s, let t):
                    return trip.stops.first { $0.id == s }?.tasks.contains { $0.id == t } ?? false
                case .failStop(let s):
                    return trip.stops.contains { $0.id == s }
                case .endTrip:
                    return true
                }
            }
        }
        if stack.isEmpty || !(stack.first?.isBasePage ?? false) {
            stack.insert(.trip, at: 0)
        }
    }
}
