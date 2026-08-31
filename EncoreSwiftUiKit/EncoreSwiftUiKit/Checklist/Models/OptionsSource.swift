import Foundation

/// Source for dynamically resolved options (`SINGLE_CHOICE_DYNAMIC`, HLD §9).
///
/// Holds an evalex expression — evaluated by the injected `ChecklistExpressionEvaluator` via
/// `evaluateValue`, at prepare and again on controller input — as an **opaque JSON string**. The
/// kit carries no evalex dependency and never parses it; the app owns evaluation and mapping the
/// result into `[ChecklistPossibleValue]`. A fixed pointer is just the simplest expression.
///
/// Mirrors Android's `OptionsSource` (there the expression is a `JsonElement`; here it is the same
/// tree serialised to a JSON string, which the app's evaluator decodes).
public struct OptionsSource: Codable, Equatable {
    /// The evalex expression tree, serialised as a JSON string. Opaque to the kit.
    public let expression: String

    public init(expression: String) {
        self.expression = expression
    }
}
