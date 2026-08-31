import Combine
import Foundation

/// Drives one checklist screen: owns the visibility engine, the resolved dynamic options, and the
/// `ChecklistStateManager`, and runs the launch + re-resolve/reset lifecycle (HLD §5.2 / §9).
///
/// The app supplies the parsed `template` and an `evaluator` (pre-seeded with the use-case entity
/// arguments). Mirrors the orchestration half of Android's `ChecklistTemplateView`.
final class ChecklistTemplateDriver: ObservableObject {
    /// Visible items in order, each carrying its effective (resolved) options — what the view renders.
    @Published private(set) var visibleItems: [ChecklistItem] = []

    /// Per-item answer state / validation / submission. Rows observe this directly.
    let stateManager: ChecklistStateManager

    private let template: ChecklistTemplate
    private let evaluator: ChecklistExpressionEvaluator
    private let onValueChanged: (([String: Any]) -> Void)?
    private let onDynamicOptionsUnresolved: (String) -> Void

    private var engine: ChecklistVisibilityEngine!
    private var resolvedOptions: [GroupItemKey: [ChecklistPossibleValue]] = [:]

    /// Guards reset re-entrancy: `updateValue` fires `onKeyChange`, and the reset path calls
    /// `updateValue` again — nested calls must not restart orchestration.
    private var isProcessing = false
    /// Items already reported unresolved this screen (fire-once telemetry).
    private var firedUnresolved = Set<GroupItemKey>()
    private var cancellables = Set<AnyCancellable>()

    init(
        template: ChecklistTemplate,
        evaluator: ChecklistExpressionEvaluator,
        initialValues: [String: Any] = [:],
        onValueChanged: (([String: Any]) -> Void)? = nil,
        onGroupEvaluationFailed: @escaping (String) -> Void = { _ in },
        onDynamicOptionsUnresolved: @escaping (String) -> Void = { _ in }
    ) {
        self.template = template
        self.evaluator = evaluator
        self.onValueChanged = onValueChanged
        self.onDynamicOptionsUnresolved = onDynamicOptionsUnresolved
        self.stateManager = ChecklistStateManager(items: template.allItems, initialValues: initialValues)

        // ----- Ordered launch (HLD §5.7 restore rule + §9). onKeyChange is set AFTER this block, so
        // the out-of-bounds clears below are pure setters (no orchestration mid-launch). -----
        // 1. Seed static (non-dynamic) controller arguments from the restored draft.
        seedControllerArguments(dynamicOnly: false, resolved: [:])
        // 2. Resolve dynamic options against the static controller args.
        resolvedOptions = DynamicOptionsResolution.resolveDynamicOptions(template, evaluator)
        // 3. Seed dynamic controller arguments using the RESOLVED options (clear out-of-bounds indices).
        seedControllerArguments(dynamicOnly: true, resolved: resolvedOptions)
        // 4. Resolve again — options may chain off dynamic controllers.
        resolvedOptions = DynamicOptionsResolution.resolveDynamicOptions(template, evaluator)
        // 5. Build the visibility engine now that every controller argument is seeded.
        self.engine = ChecklistVisibilityEngine(
            template: template, evaluator: evaluator, onEvaluationFailed: onGroupEvaluationFailed
        )
        // 6. Publish the initial visible rows and sync the state manager's item list.
        refreshVisibleItems()
        stateManager.updateItems(visibleItems)

        // Now wire change handling and re-publish on any answer/validation change.
        stateManager.onKeyChange = { [weak self] key in self?.handleKeyChange(key) }
        stateManager.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - Submission (read by the view)

    func submissionMap() -> [String: ChecklistItemValue] { stateManager.buildSubmissionMap() }
    func canSubmit() -> Bool { stateManager.areAllRequiredItemsValid() }
    func firstInvalidRequiredItemID() -> ChecklistItem.ID? { stateManager.firstInvalidRequiredItemID() }

    // MARK: - Change handling

    private func handleKeyChange(_ key: String) {
        // Always forward to the app for draft persistence, even for nested resets.
        onValueChanged?(stateManager.currentValues())
        if isProcessing { return } // reset re-entrancy — orchestration already running
        guard let (group, item) = locate(key), item.isVisibilityController else { return }

        isProcessing = true
        defer { isProcessing = false }

        let effective = item.withAllowedValues(
            DynamicOptionsResolution.effectiveOptions(item, resolvedOptions[GroupItemKey(groupId: group.groupId, itemKey: key)])
        )
        engine.onControllerInput(
            groupId: group.groupId,
            itemKey: key,
            valueJson: effective.controllerArgument(stateManager.getValue(key: key))
        )

        // Re-resolve options to a fixpoint, resetting selections whose list changed (HLD §9).
        var refreshed = DynamicOptionsResolution.resolveDynamicOptions(template, evaluator)
        var guardCount = template.allItems.count + 1
        while refreshed != resolvedOptions, guardCount > 0 {
            guardCount -= 1
            for stale in DynamicOptionsResolution.staleSelectionKeys(resolvedOptions, refreshed)
            where stateManager.getValue(key: stale.itemKey) != nil {
                stateManager.updateValue(key: stale.itemKey, value: nil) // reset (re-entrant, guarded)
                if let staleItem = itemByKey(stale.itemKey), staleItem.isVisibilityController {
                    engine.onControllerInput(groupId: stale.groupId, itemKey: stale.itemKey, valueJson: "null")
                }
            }
            resolvedOptions = refreshed
            refreshed = DynamicOptionsResolution.resolveDynamicOptions(template, evaluator)
        }
        resolvedOptions = refreshed

        refreshVisibleItems()
        stateManager.updateItems(visibleItems)
    }

    // MARK: - Visible rows

    private func refreshVisibleItems() {
        var rows: [ChecklistItem] = []
        for group in engine.visibleGroups() {
            for item in group.items {
                guard item.format == .singleChoiceDynamic else {
                    rows.append(item)
                    continue
                }
                let giKey = GroupItemKey(groupId: group.groupId, itemKey: item.key)
                let options = DynamicOptionsResolution.effectiveOptions(item, resolvedOptions[giKey])
                if options.isEmpty {
                    // Fail open (§3.5): drop the item and report it once.
                    if firedUnresolved.insert(giKey).inserted { onDynamicOptionsUnresolved(item.key) }
                    continue
                }
                rows.append(item.withAllowedValues(options))
            }
        }
        visibleItems = rows
    }

    // MARK: - Helpers

    /// Seeds the evaluator with restored controller answers. `dynamicOnly` selects the pass:
    /// static controllers first (against nothing), then dynamic ones against `resolved` options.
    private func seedControllerArguments(dynamicOnly: Bool, resolved: [GroupItemKey: [ChecklistPossibleValue]]) {
        for group in template.groups {
            for item in group.items {
                let isDynamic = item.format == .singleChoiceDynamic
                if dynamicOnly != isDynamic { continue }
                guard item.isVisibilityController, let restored = stateManager.getValue(key: item.key) else { continue }

                if isDynamic {
                    let options = DynamicOptionsResolution.effectiveOptions(item, resolved[GroupItemKey(groupId: group.groupId, itemKey: item.key)])
                    if let index = restored as? Int, index >= options.count {
                        stateManager.updateValue(key: item.key, value: nil) // out-of-bounds — clear it
                        continue
                    }
                    let effective = item.withAllowedValues(options)
                    evaluator.putArgument(name: "\(group.groupId)/\(item.key)", valueJson: effective.controllerArgument(restored))
                } else {
                    evaluator.putArgument(name: "\(group.groupId)/\(item.key)", valueJson: item.controllerArgument(restored))
                }
            }
        }
    }

    private func locate(_ key: String) -> (ChecklistGroup, ChecklistItem)? {
        for group in template.groups {
            if let item = group.items.first(where: { $0.key == key }) { return (group, item) }
        }
        return nil
    }

    private func itemByKey(_ key: String) -> ChecklistItem? {
        template.allItems.first { $0.key == key }
    }
}
