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

    func testUpdateValueFiresOnValueChangeWithFullState() {
        var seen: [[String: Any]] = []
        let sm = ChecklistStateManager(
            items: [requiredText("name")],
            onValueChange: { state in seen.append(state) }
        )
        sm.updateValue(key: "name", value: "Grace")
        XCTAssertEqual(seen.count, 1)
        XCTAssertEqual(seen.first?["name"] as? String, "Grace")
    }

    func testIsValidReflectsUpdates() {
        let sm = ChecklistStateManager(items: [requiredText("name")])
        XCTAssertFalse(sm.isValid(key: "name"))
        sm.updateValue(key: "name", value: "Katherine")
        XCTAssertTrue(sm.isValid(key: "name"))
    }

    // MARK: - isAnswered tests

    private func item(_ key: String, format: ChecklistItemFormat, optional: Bool = false) -> ChecklistItem {
        ChecklistItem(key: key, item: key, optional: optional, format: format)
    }

    // .textField — false when empty/unset, true after non-empty value
    func testIsAnswered_textField_falseWhenEmpty() {
        let sm = ChecklistStateManager(items: [item("note", format: .textField)])
        XCTAssertFalse(sm.isAnswered(key: "note"))
    }

    func testIsAnswered_textField_trueAfterNonEmptyValue() {
        let sm = ChecklistStateManager(items: [item("note", format: .textField)])
        sm.updateValue(key: "note", value: "hello")
        XCTAssertTrue(sm.isAnswered(key: "note"))
    }

    // isAnswered is independent of isValid for optional empty textField
    func testIsAnswered_optionalTextField_isValidTrueButIsAnsweredFalse() {
        let sm = ChecklistStateManager(items: [item("note", format: .textField, optional: true)])
        // Optional empty text field: isValid = true (no requirement), isAnswered = false (no content)
        XCTAssertTrue(sm.isValid(key: "note"))
        XCTAssertFalse(sm.isAnswered(key: "note"))
    }

    // .boolean — false when unset or false, true only when explicitly set to true
    func testIsAnswered_boolean_falseWhenUnset() {
        let sm = ChecklistStateManager(items: [item("ack", format: .boolean)])
        XCTAssertFalse(sm.isAnswered(key: "ack"))
    }

    func testIsAnswered_boolean_falseWhenExplicitlyFalse() {
        let sm = ChecklistStateManager(items: [item("ack", format: .boolean)])
        sm.updateValue(key: "ack", value: false)
        XCTAssertFalse(sm.isAnswered(key: "ack"))
    }

    func testIsAnswered_boolean_trueWhenTrue() {
        let sm = ChecklistStateManager(items: [item("ack", format: .boolean)])
        sm.updateValue(key: "ack", value: true)
        XCTAssertTrue(sm.isAnswered(key: "ack"))
    }

    // isValid for boolean is always true (regardless of check state), isAnswered differs
    func testIsAnswered_boolean_isValidAlwaysTrueButIsAnsweredDependsOnValue() {
        let sm = ChecklistStateManager(items: [item("ack", format: .boolean)])
        // Unset: isValid = true (validateBoolean always returns true), isAnswered = false
        XCTAssertTrue(sm.isValid(key: "ack"))
        XCTAssertFalse(sm.isAnswered(key: "ack"))
    }

    // .singleChoice — false at -1/nil, true after a real selection
    func testIsAnswered_singleChoice_falseAtDefaultMinusOne() {
        let sm = ChecklistStateManager(items: [item("color", format: .singleChoice)])
        XCTAssertFalse(sm.isAnswered(key: "color"))
    }

    func testIsAnswered_singleChoice_falseWhenExplicitlyMinusOne() {
        let sm = ChecklistStateManager(items: [item("color", format: .singleChoice)])
        sm.updateValue(key: "color", value: -1)
        XCTAssertFalse(sm.isAnswered(key: "color"))
    }

    func testIsAnswered_singleChoice_trueAfterValidIndex() {
        let sm = ChecklistStateManager(items: [item("color", format: .singleChoice)])
        sm.updateValue(key: "color", value: 0)
        XCTAssertTrue(sm.isAnswered(key: "color"))
    }

    // .multiChoice — false when empty set, true when non-empty
    func testIsAnswered_multiChoice_falseWhenEmpty() {
        let sm = ChecklistStateManager(items: [item("tags", format: .multiChoice)])
        XCTAssertFalse(sm.isAnswered(key: "tags"))
    }

    func testIsAnswered_multiChoice_trueWhenNonEmpty() {
        let sm = ChecklistStateManager(items: [item("tags", format: .multiChoice)])
        sm.updateValue(key: "tags", value: Set([0, 2]))
        XCTAssertTrue(sm.isAnswered(key: "tags"))
    }

    // Unknown key returns false
    func testIsAnswered_unknownKeyReturnsFalse() {
        let sm = ChecklistStateManager(items: [item("x", format: .textField)])
        XCTAssertFalse(sm.isAnswered(key: "nonexistent"))
    }
}
