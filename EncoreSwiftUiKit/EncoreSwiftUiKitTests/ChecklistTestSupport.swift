@testable import EncoreSwiftUiKit
import Foundation

/// Programmable evaluator for kit checklist tests. Boolean/value results are computed from the
/// current arguments + the expression string, so a test can model scoped visibility and options.
final class StubEvaluator: ChecklistExpressionEvaluator {
    private(set) var args: [String: String] = [:]
    var boolFor: (([String: String], String) -> Bool?)?
    var valueFor: (([String: String], String) -> [ChecklistPossibleValue]?)?

    func putArgument(name: String, valueJson: String) { args[name] = valueJson }
    func evaluateBoolean(_ expressionJson: String) -> Bool? { boolFor?(args, expressionJson) }
    func evaluateValue(_ expressionJson: String) -> [ChecklistPossibleValue]? { valueFor?(args, expressionJson) }
}

func pv(_ key: String) -> ChecklistPossibleValue { ChecklistPossibleValue(key: key, displayText: key) }

func singleChoiceItem(_ key: String, _ optionKeys: [String]) -> ChecklistItem {
    ChecklistItem(key: key, item: key, format: .singleChoice, allowedValues: optionKeys.map(pv))
}

func dynamicChoiceItem(_ key: String, expression: String, fallback: [String] = []) -> ChecklistItem {
    ChecklistItem(
        key: key,
        item: key,
        format: .singleChoiceDynamic,
        allowedValues: fallback.isEmpty ? nil : fallback.map(pv),
        optionsSource: OptionsSource(expression: expression)
    )
}

func textItem(_ key: String) -> ChecklistItem {
    ChecklistItem(key: key, item: key, format: .textField)
}
