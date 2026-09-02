import Foundation

/// Identifies an item within a group. Item keys are only unique within a group, so resolved options
/// are keyed by the pair (Android uses `Pair<groupId, itemKey>`).
struct GroupItemKey: Hashable {
    let groupId: String
    let itemKey: String
}

/// Pure helpers that turn per-expression option evaluation into whole-template resolved options.
/// Mirrors the free functions in Android's `ChecklistTemplateView`.
enum DynamicOptionsResolution {
    /// Resolves every `SINGLE_CHOICE_DYNAMIC` item's `optionsSource` via the evaluator (HLD §9).
    /// Items without a source are skipped (their static `allowedValues`, if any, are used as-is).
    static func resolveDynamicOptions(
        _ template: ChecklistTemplate,
        _ evaluator: ChecklistExpressionEvaluator
    ) -> [GroupItemKey: [ChecklistPossibleValue]] {
        var resolved: [GroupItemKey: [ChecklistPossibleValue]] = [:]
        for group in template.groups {
            for item in group.items where item.format == .singleChoiceDynamic {
                guard let source = item.optionsSource else { continue }
                if let choices = evaluator.evaluateValue(source.expression) {
                    resolved[GroupItemKey(groupId: group.groupId, itemKey: item.key)] = choices
                }
            }
        }
        return resolved
    }

    /// A dynamic item's effective options: freshly resolved, else its static list.
    static func effectiveOptions(
        _ item: ChecklistItem,
        _ resolved: [ChecklistPossibleValue]?
    ) -> [ChecklistPossibleValue] {
        resolved ?? item.allowedValues ?? []
    }

    /// The template's items with every dynamic item carrying its effective options — what the state
    /// manager must hold so validation and the submission map read the SAME lists the driver renders
    /// (a selection is an index; mapping it through the raw template would drop or mismap the answer).
    static func effectiveItems(
        _ template: ChecklistTemplate,
        _ resolvedOptions: [GroupItemKey: [ChecklistPossibleValue]]
    ) -> [ChecklistItem] {
        template.groups.flatMap { group in
            group.items.map { item -> ChecklistItem in
                guard item.format == .singleChoiceDynamic else { return item }
                let options = effectiveOptions(item, resolvedOptions[GroupItemKey(groupId: group.groupId, itemKey: item.key)])
                return item.withAllowedValues(options)
            }
        }
    }

    /// Keys whose option list changed between two resolutions — the selections that must reset (an
    /// index into a changed list would submit a different option than the driver picked).
    static func staleSelectionKeys(
        _ old: [GroupItemKey: [ChecklistPossibleValue]],
        _ new: [GroupItemKey: [ChecklistPossibleValue]]
    ) -> [GroupItemKey] {
        Array(Set(old.keys).union(new.keys)).filter { old[$0] != new[$0] }
    }
}

extension ChecklistItem {
    /// A copy with `allowedValues` replaced — used to substitute resolved dynamic options.
    func withAllowedValues(_ values: [ChecklistPossibleValue]) -> ChecklistItem {
        ChecklistItem(
            key: key,
            item: item,
            helperText: helperText,
            optional: optional,
            format: format,
            possibleValues: possibleValues,
            allowedValues: values,
            additionalOptions: additionalOptions,
            optionsSource: optionsSource
        )
    }
}
