import Foundation

/// Group-visibility state machine for one checklist screen (HLD §5.2). Mirrors Android's
/// `ChecklistVisibilityEngine`.
///
/// The evaluator must arrive pre-seeded with the use-case entity arguments; this engine manages the
/// controller-input arguments (keyed `"<groupId>/<itemKey>"`) and the per-group visibility they
/// drive.
///
/// Semantics:
/// - absent `show` ⇒ always visible
/// - unresolvable `show` ⇒ hidden (fail closed) + `onEvaluationFailed`
/// - a controller input change re-evaluates the group's `childGroups`, and the change cascades: a
///   child that flips has its own `childGroups` re-evaluated, and no descendant of a hidden group
///   ever stays visible
/// - the construction-time pass never fires `onEvaluationFailed`: controllers are unanswered then,
///   so "unresolvable" is the expected state, not a fault
final class ChecklistVisibilityEngine {
    private let template: ChecklistTemplate
    private let evaluator: ChecklistExpressionEvaluator
    private let onEvaluationFailed: (String) -> Void

    private let groupsById: [String: ChecklistGroup]
    private var visibility: [String: Bool] = [:]

    init(
        template: ChecklistTemplate,
        evaluator: ChecklistExpressionEvaluator,
        onEvaluationFailed: @escaping (String) -> Void = { _ in }
    ) {
        self.template = template
        self.evaluator = evaluator
        self.onEvaluationFailed = onEvaluationFailed
        self.groupsById = Dictionary(template.groups.map { ($0.groupId, $0) }, uniquingKeysWith: { first, _ in first })

        for group in template.groups {
            visibility[group.groupId] = evaluate(group, reportFailure: false)
        }
        // A conditional group whose expression happens to resolve true (e.g. from entity arguments)
        // must still not show while its parent is hidden.
        for group in template.groups where visibility[group.groupId] != true {
            var visited = Set<String>()
            hideDescendants(group, visited: &visited)
        }
    }

    /// Records a controller input and re-evaluates the source group's `childGroups`, cascading
    /// through descendants of any group that flipped. Returns the groups whose visibility changed,
    /// in template order — what the renderer animates in or out.
    @discardableResult
    func onControllerInput(groupId: String, itemKey: String, valueJson: String) -> [ChecklistGroup] {
        evaluator.putArgument(name: "\(groupId)/\(itemKey)", valueJson: valueJson)
        guard let source = groupsById[groupId] else { return [] }
        var flipped = Set<String>()
        var visited = Set<String>()
        reevaluateChildren(source, parentVisible: true, flipped: &flipped, visited: &visited)
        return template.groups.filter { flipped.contains($0.groupId) }
    }

    func isVisible(_ groupId: String) -> Bool { visibility[groupId] == true }

    /// Currently visible groups, in template order.
    func visibleGroups() -> [ChecklistGroup] {
        template.groups.filter { visibility[$0.groupId] == true }
    }

    /// Items counted for validation and submission — visible groups only (§3.4).
    func visibleItems() -> [ChecklistItem] { visibleGroups().flatMap { $0.items } }

    // MARK: - Private

    private func reevaluateChildren(
        _ parent: ChecklistGroup,
        parentVisible: Bool,
        flipped: inout Set<String>,
        visited: inout Set<String>
    ) {
        for childId in parent.childGroups {
            if visited.contains(childId) { continue } // malformed cycle — stop, don't recurse forever
            visited.insert(childId)
            guard let child = groupsById[childId] else { continue }
            let wasVisible = visibility[childId] == true
            let nowVisible = parentVisible && evaluate(child)
            visibility[childId] = nowVisible
            if nowVisible != wasVisible { flipped.insert(childId) }
            // Descendants follow: a re-shown child's own children re-materialize from their retained
            // controller answers; a hidden child takes its subtree down.
            reevaluateChildren(child, parentVisible: nowVisible, flipped: &flipped, visited: &visited)
        }
    }

    private func hideDescendants(_ parent: ChecklistGroup, visited: inout Set<String>) {
        for childId in parent.childGroups {
            if visited.contains(childId) { continue }
            visited.insert(childId)
            visibility[childId] = false
            if let child = groupsById[childId] { hideDescendants(child, visited: &visited) }
        }
    }

    private func evaluate(_ group: ChecklistGroup, reportFailure: Bool = true) -> Bool {
        guard let show = group.show else { return true }
        let result = evaluator.evaluateBoolean(show)
        if result == nil, reportFailure { onEvaluationFailed(group.groupId) }
        return result ?? false
    }
}
