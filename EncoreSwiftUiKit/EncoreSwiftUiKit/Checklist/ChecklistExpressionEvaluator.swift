import Foundation

/// Evaluates checklist `show` and dynamic `optionsSource` expressions against a mutable argument
/// context (HLD §3.3).
///
/// Defined by the kit as a protocol so the library carries no evalex dependency — the app supplies
/// the implementation (evalex-backed). Expressions and argument values cross this boundary as
/// **JSON strings** (the app's evaluator decodes them). Mirrors Android's
/// `ChecklistExpressionEvaluator`.
public protocol ChecklistExpressionEvaluator: AnyObject {
    /// Adds or replaces an argument in the evaluation context. [valueJson] is a JSON-encoded value
    /// (e.g. `"\"DAMAGED\""`, `"true"`, `"[\"A\",\"B\"]"`, `"null"`).
    func putArgument(name: String, valueJson: String)

    /// Evaluates [expressionJson] against the current arguments. Returns the boolean result, or nil
    /// when it cannot be resolved (unknown argument, parse error, non-boolean result) — callers fail
    /// closed on nil.
    func evaluateBoolean(_ expressionJson: String) -> Bool?

    /// Evaluates [expressionJson] to a list of ready-to-render choices — the option list of a
    /// `SINGLE_CHOICE_DYNAMIC` item (HLD §9). The implementation owns evaluation, mapping the raw
    /// result into `ChecklistPossibleValue`s (seed `code` → key, `label` → displayText with code
    /// fallback), and absorbing parse failures. Returns nil when unresolvable or unparseable —
    /// callers hide/drop the item, never block (fail open, §3.5).
    ///
    /// Default nil so boolean-only evaluators keep working unchanged.
    func evaluateValue(_ expressionJson: String) -> [ChecklistPossibleValue]?
}

public extension ChecklistExpressionEvaluator {
    func evaluateValue(_ expressionJson: String) -> [ChecklistPossibleValue]? { nil }
}
