import SwiftUI
import EncoreSwiftUiKit

@main
struct SnapshotTestHostApp: App {
    var body: some Scene {
        WindowGroup {
            // V2 prototype. POC_STATE selects an entry point; default is the stitched V1 happy flow
            // until the V2 surfaces (P1) land.
            //   POC_STATE=p0   → V2 paradigm-layer gate harness (all statuses + all five transitions)
            //   POC_STATE=<n>  → a single V1 happy-flow frame in isolation
            // Note: simctl needs the SIMCTL_CHILD_ prefix, e.g. SIMCTL_CHILD_POC_STATE=p0.
            if let screen = ProcessInfo.processInfo.environment["POC_STATE"] {
                if screen == "p0" {
                    V2P0Harness()
                } else if screen.hasPrefix("p0-") {
                    V2P0Harness(demo: String(screen.dropFirst(3)))
                } else if screen.hasPrefix("v2-") {
                    V2Flow(demo: String(screen.dropFirst(3)))
                } else {
                    HFRouter(screen: screen)
                }
            } else {
                V2Flow()
            }
        }
    }
}
