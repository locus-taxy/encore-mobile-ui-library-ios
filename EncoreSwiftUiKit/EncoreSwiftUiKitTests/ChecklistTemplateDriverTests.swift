@testable import EncoreSwiftUiKit
import XCTest

/// End-to-end driver lifecycle (HLD §9): dynamic options resolve on parent selection, drop when
/// unresolved (fail-open + telemetry), and reset the child selection when the parent changes.
@MainActor
final class ChecklistTemplateDriverTests: XCTestCase {
    /// One group: a static `reason` (a/b) and a dynamic `sub` scoped by the reason answer.
    private func makeTemplate() -> ChecklistTemplate {
        ChecklistTemplate(groups: [
            ChecklistGroup(groupId: "G1", show: nil, childGroups: [], items: [
                singleChoiceItem("reason", ["a", "b"]),
                dynamicChoiceItem("sub", expression: "subExpr"),
            ]),
        ])
    }

    private func makeEvaluator() -> StubEvaluator {
        let e = StubEvaluator()
        e.boolFor = { _, _ in nil }
        e.valueFor = { args, expr in
            guard expr == "subExpr" else { return nil }
            switch args["G1/reason"] {
            case "\"a\"": return [pv("x"), pv("y")]
            case "\"b\"": return [pv("z")]
            default: return nil // unresolved until reason answered
            }
        }
        return e
    }

    func testDynamicItemDroppedUntilParentAnswered() {
        var unresolved: [String] = []
        let driver = ChecklistTemplateDriver(
            template: makeTemplate(),
            evaluator: makeEvaluator(),
            onDynamicOptionsUnresolved: { unresolved.append($0) }
        )
        XCTAssertEqual(driver.visibleItems.map(\.key), ["reason"]) // sub dropped (fail-open)
        XCTAssertEqual(unresolved, ["sub"])
    }

    func testDynamicOptionsResolveOnParentSelection() {
        let driver = ChecklistTemplateDriver(template: makeTemplate(), evaluator: makeEvaluator())
        driver.stateManager.updateValue(key: "reason", value: 0) // select "a"
        XCTAssertEqual(driver.visibleItems.map(\.key), ["reason", "sub"])
        XCTAssertEqual(driver.visibleItems.first { $0.key == "sub" }?.allowedValues?.map(\.key), ["x", "y"])
    }

    func testStaleSelectionResetsWhenParentChanges() {
        let driver = ChecklistTemplateDriver(template: makeTemplate(), evaluator: makeEvaluator())
        driver.stateManager.updateValue(key: "reason", value: 0) // "a" → sub [x, y]
        driver.stateManager.updateValue(key: "sub", value: 0)    // pick x
        XCTAssertEqual(driver.stateManager.getValue(key: "sub") as? Int, 0)

        driver.stateManager.updateValue(key: "reason", value: 1) // "b" → sub [z]; list changed → reset
        XCTAssertEqual(driver.visibleItems.first { $0.key == "sub" }?.allowedValues?.map(\.key), ["z"])
        XCTAssertNil(driver.stateManager.getValue(key: "sub")) // selection reset
    }
}
