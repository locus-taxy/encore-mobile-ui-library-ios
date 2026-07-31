@testable import EncoreSwiftUiKit
import XCTest

@MainActor
final class ChecklistStateManagerTests: XCTestCase {

    private func requiredText(_ key: String) -> ChecklistItem {
        ChecklistItem(key: key, item: key, optional: false, format: .textField)
    }

    func testSeedsInitialValuesAndValidatesThem() {
        let sm = ChecklistStateManager(
            items: [requiredText("name")],
            initialValues: ["name": "Ada"]
        )
        XCTAssertEqual(sm.getValue(key: "name") as? String, "Ada")
        // A required text field seeded with a non-empty value must already be valid.
        XCTAssertTrue(sm.isValid(key: "name"))
        XCTAssertTrue(sm.areAllRequiredItemsValid())
    }

    func testEmptySeedLeavesRequiredItemInvalid() {
        let sm = ChecklistStateManager(items: [requiredText("name")])
        XCTAssertFalse(sm.isValid(key: "name"))
        XCTAssertFalse(sm.areAllRequiredItemsValid())
    }

    func testUpdateValueFiresOnValueChange() {
        var seen: [(String, Any?)] = []
        let sm = ChecklistStateManager(
            items: [requiredText("name")],
            onValueChange: { key, value in seen.append((key, value)) }
        )
        sm.updateValue(key: "name", value: "Grace")
        XCTAssertEqual(seen.count, 1)
        XCTAssertEqual(seen.first?.0, "name")
        XCTAssertEqual(seen.first?.1 as? String, "Grace")
    }

    func testIsValidReflectsUpdates() {
        let sm = ChecklistStateManager(items: [requiredText("name")])
        XCTAssertFalse(sm.isValid(key: "name"))
        sm.updateValue(key: "name", value: "Katherine")
        XCTAssertTrue(sm.isValid(key: "name"))
    }
}
