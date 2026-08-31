@testable import EncoreSwiftUiKit
import XCTest

/// Whole-template option resolution helpers — keying, static fallback, substitution, stale-key diff.
/// Mirrors Android's `DynamicOptionsResolutionTest`.
final class DynamicOptionsResolutionTests: XCTestCase {
    private func makeTemplate() -> ChecklistTemplate {
        ChecklistTemplate(groups: [
            ChecklistGroup(groupId: "G", show: nil, childGroups: [], items: [
                dynamicChoiceItem("dyn", expression: "e1", fallback: ["fb"]),
                dynamicChoiceItem("dynNoResult", expression: "e2"),
                singleChoiceItem("stat", ["s"]),
            ]),
        ])
    }

    func testResolvesOnlyDynamicItemsWithAResult() {
        let e = StubEvaluator()
        e.valueFor = { _, expr in expr == "e1" ? [pv("x")] : nil }
        let resolved = DynamicOptionsResolution.resolveDynamicOptions(makeTemplate(), e)
        XCTAssertEqual(resolved[GroupItemKey(groupId: "G", itemKey: "dyn")]?.map(\.key), ["x"])
        // evaluateValue returned nil → not resolved (item will fall back / drop).
        XCTAssertNil(resolved[GroupItemKey(groupId: "G", itemKey: "dynNoResult")])
    }

    func testEffectiveOptionsFallsBackToStatic() {
        let item = dynamicChoiceItem("dyn", expression: "e1", fallback: ["fb"])
        XCTAssertEqual(DynamicOptionsResolution.effectiveOptions(item, [pv("x")]).map(\.key), ["x"])
        XCTAssertEqual(DynamicOptionsResolution.effectiveOptions(item, nil).map(\.key), ["fb"]) // static fallback
        XCTAssertTrue(DynamicOptionsResolution.effectiveOptions(dynamicChoiceItem("d2", expression: "e"), nil).isEmpty)
    }

    func testEffectiveItemsSubstitutesResolvedAndLeavesStaticAlone() {
        let e = StubEvaluator()
        e.valueFor = { _, expr in expr == "e1" ? [pv("x"), pv("y")] : nil }
        let resolved = DynamicOptionsResolution.resolveDynamicOptions(makeTemplate(), e)
        let items = DynamicOptionsResolution.effectiveItems(makeTemplate(), resolved)
        XCTAssertEqual(items.first { $0.key == "dyn" }?.allowedValues?.map(\.key), ["x", "y"])
        XCTAssertEqual(items.first { $0.key == "stat" }?.allowedValues?.map(\.key), ["s"]) // unchanged
    }

    func testStaleSelectionKeys() {
        let k = GroupItemKey(groupId: "G", itemKey: "dyn")
        XCTAssertTrue(DynamicOptionsResolution.staleSelectionKeys([k: [pv("x")]], [k: [pv("x")]]).isEmpty)
        XCTAssertEqual(DynamicOptionsResolution.staleSelectionKeys([k: [pv("x")]], [k: [pv("z")]]), [k])
    }
}
