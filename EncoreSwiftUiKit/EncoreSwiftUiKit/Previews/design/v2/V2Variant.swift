import Foundation

// MARK: - Design variants
//
// Why this file exists: new UI thoughts are tried as switches on the ONE prototype, never as copied
// screens. A variant picks up every Figma and Jira fix for free, A and B run from the same build, and
// promoting a winner is a one-line change (make it the default, delete the old branch of the `if`).
//
// Turn variants on at launch (comma-separated), alongside any demo state:
//   SIMCTL_CHILD_POC_VARIANT=denseCards,boldChips SIMCTL_CHILD_POC_STATE=v2-stop \
//     xcrun simctl launch --terminate-running-process booted sh.locus.encore.SnapshotTestHost
//
// Adding one:
//   1. Add a `static let` below with a one-line comment: the idea and what it changes.
//   2. Branch on it where the surface differs: `if V2Variant.isOn(.denseCards) { … } else { … }`.
//   3. Log it in the workspace's `v2-variants.md` (idea, why, how to launch, screens, outcome).
// Retiring one: keep the winning side of every `if`, delete the key and its log entry's open status.

struct V2Variant: Hashable {
    let key: String
    private init(_ key: String) { self.key = key }

    // Registry — one line per live variant.
    // static let denseCards = V2Variant("denseCards")   // example: tighter task-card rhythm (12 → 8)
    /// DP-2956: inbox rows drop the severity chip; only open critical/high rows say "• Action required"
    /// (the scan page's "• Damaged" label), pinned on top, with an "Action required (n)" tab.
    static let actionRequired = V2Variant("actionRequired")

    /// Variants switched on for this launch, from `POC_VARIANT`.
    static let active: Set<String> = {
        let raw = ProcessInfo.processInfo.environment["POC_VARIANT"] ?? ""
        return Set(raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty })
    }()

    static func isOn(_ variant: V2Variant) -> Bool { active.contains(variant.key) }
}
