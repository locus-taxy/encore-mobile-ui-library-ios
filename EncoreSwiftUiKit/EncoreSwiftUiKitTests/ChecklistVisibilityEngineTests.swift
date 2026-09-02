@testable import EncoreSwiftUiKit
import XCTest

/// Stateful visibility engine: init pass, fail-closed, incremental childGroups cascade, and
/// parent-gating (a child stays hidden under a hidden parent even when its own `show` is true).
final class ChecklistVisibilityEngineTests: XCTestCase {
    /// A: always visible, controls B. B: shown when reason == "damaged", controls D. D: `show` is
    /// always true (tests parent-gating). C: always visible.
    private func makeTemplate() -> ChecklistTemplate {
        ChecklistTemplate(groups: [
            ChecklistGroup(groupId: "A", show: nil, childGroups: ["B"], items: [singleChoiceItem("reason", ["a", "damaged"])]),
            ChecklistGroup(groupId: "B", show: "showB", childGroups: ["D"], items: [textItem("note")]),
            ChecklistGroup(groupId: "D", show: "alwaysTrue", childGroups: [], items: [textItem("d")]),
            ChecklistGroup(groupId: "C", show: nil, childGroups: [], items: [textItem("c")]),
        ])
    }

    private func makeEvaluator() -> StubEvaluator {
        let e = StubEvaluator()
        e.boolFor = { args, expr in
            switch expr {
            case "showB": return args["A/reason"] == "\"damaged\"" ? true : nil // unresolved (fail-closed) otherwise
            case "alwaysTrue": return true
            default: return nil
            }
        }
        return e
    }

    func testInitHidesConditionalAndParentGatesDescendant() {
        let engine = ChecklistVisibilityEngine(template: makeTemplate(), evaluator: makeEvaluator())
        // B hidden (unresolved show) ⇒ D hidden too, even though D.show is true. A, C always visible.
        XCTAssertEqual(engine.visibleGroups().map(\.groupId), ["A", "C"])
    }

    func testControllerInputRevealsChildAndCascades() {
        let engine = ChecklistVisibilityEngine(template: makeTemplate(), evaluator: makeEvaluator())
        let flipped = engine.onControllerInput(groupId: "A", itemKey: "reason", valueJson: "\"damaged\"").map(\.groupId)
        XCTAssertEqual(Set(flipped), Set(["B", "D"])) // B flips visible; D cascades visible
        XCTAssertEqual(engine.visibleGroups().map(\.groupId), ["A", "B", "D", "C"])
    }

    func testControllerInputHidesSubtreeAgain() {
        let engine = ChecklistVisibilityEngine(template: makeTemplate(), evaluator: makeEvaluator())
        _ = engine.onControllerInput(groupId: "A", itemKey: "reason", valueJson: "\"damaged\"")
        let flipped = engine.onControllerInput(groupId: "A", itemKey: "reason", valueJson: "\"a\"").map(\.groupId)
        XCTAssertEqual(Set(flipped), Set(["B", "D"])) // both hide
        XCTAssertEqual(engine.visibleGroups().map(\.groupId), ["A", "C"])
    }

    func testMalformedCycleTerminates() {
        // A → B → A: the cycle guard must stop rather than recurse forever.
        let template = ChecklistTemplate(groups: [
            ChecklistGroup(groupId: "A", show: nil, childGroups: ["B"], items: [singleChoiceItem("r", ["x"])]),
            ChecklistGroup(groupId: "B", show: "t", childGroups: ["A"], items: [textItem("b")]),
        ])
        let e = StubEvaluator()
        e.boolFor = { _, _ in true }
        let engine = ChecklistVisibilityEngine(template: template, evaluator: e)
        _ = engine.onControllerInput(groupId: "A", itemKey: "r", valueJson: "\"x\"") // must return, not hang
        XCTAssertTrue(engine.isVisible("B"))
    }
}
