@testable import EncoreSwiftUiKit
import XCTest

/// `isVisibilityController` + `controllerArgument` — mirrors Android's `ChecklistVisibleScopeTest`
/// (index → option key, booleans, multi-choice arrays, numeric text, unanswered → null).
final class ChecklistControllerArgumentTests: XCTestCase {
    func testIsVisibilityController() {
        XCTAssertTrue(ChecklistItem(key: "a", item: "a", format: .singleChoice).isVisibilityController)
        XCTAssertTrue(ChecklistItem(key: "a", item: "a", format: .singleChoiceDynamic).isVisibilityController)
        XCTAssertTrue(ChecklistItem(key: "a", item: "a", format: .boolean).isVisibilityController)
        XCTAssertTrue(ChecklistItem(key: "a", item: "a", format: .multiChoice).isVisibilityController)
        XCTAssertFalse(ChecklistItem(key: "a", item: "a", format: .photo).isVisibilityController)
        XCTAssertFalse(ChecklistItem(key: "a", item: "a", format: .textField).isVisibilityController)
        XCTAssertTrue(ChecklistItem(key: "a", item: "a", format: .textField, additionalOptions: ["inputType": "NUMBER"]).isVisibilityController)
        XCTAssertTrue(ChecklistItem(key: "a", item: "a", format: .textField, additionalOptions: ["inputType": "decimal"]).isVisibilityController)
    }

    func testControllerArgumentBoolean() {
        let b = ChecklistItem(key: "b", item: "b", format: .boolean)
        XCTAssertEqual(b.controllerArgument(true), "true")
        XCTAssertEqual(b.controllerArgument(false), "false")
        XCTAssertEqual(b.controllerArgument(nil), "false")
    }

    func testControllerArgumentSingleChoice() {
        let c = ChecklistItem(key: "c", item: "c", format: .singleChoice, allowedValues: [pv("a"), pv("damaged")])
        XCTAssertEqual(c.controllerArgument(1), "\"damaged\"")
        XCTAssertEqual(c.controllerArgument(-1), "null")
        XCTAssertEqual(c.controllerArgument(99), "null")
        XCTAssertEqual(c.controllerArgument(nil), "null")
    }

    func testControllerArgumentMultiChoice() {
        let m = ChecklistItem(key: "m", item: "m", format: .multiChoice, allowedValues: [pv("a"), pv("b"), pv("c")])
        XCTAssertEqual(m.controllerArgument(Set([2, 0])), "[\"a\",\"c\"]") // sorted by index → keys a, c
        XCTAssertEqual(m.controllerArgument(Set<Int>()), "[]")
    }

    func testControllerArgumentNumericText() {
        let t = ChecklistItem(key: "t", item: "t", format: .textField, additionalOptions: ["inputType": "NUMBER"])
        XCTAssertEqual(Double(t.controllerArgument("3")), 3.0) // "3" or "3.0" both parse to 3
        XCTAssertEqual(t.controllerArgument("not a number"), "null")
    }
}
