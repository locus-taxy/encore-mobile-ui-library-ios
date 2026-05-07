@testable import EncoreSwiftUiKit
import SwiftUI
import XCTest

final class LTextFieldTests: XCTestCase {

    // MARK: - Helpers

    @MainActor private func makeField(variant: LTextFieldVariant, isRequired: Bool = false) -> LTextField {
        var stored = ""
        let binding = Binding<String>(get: { stored }, set: { stored = $0 })
        return LTextField(
            value: binding,
            onValueChange: { _ in },
            variant: variant,
            isRequired: isRequired
        )
    }

    // MARK: - Filter behavior

    @MainActor func testStandardFilter_passesAllInputUnchanged() {
        let field = makeField(variant: .standard)
        XCTAssertEqual(field.filter("Hello, World! 123"), "Hello, World! 123")
        XCTAssertEqual(field.filter(""), "")
        XCTAssertEqual(field.filter("emoji ✓"), "emoji ✓")
    }

    @MainActor func testNumberFilter_onlyDigitsPass() {
        let field = makeField(variant: .number)
        XCTAssertEqual(field.filter("abc123def456"), "123456")
        XCTAssertEqual(field.filter("12.34"), "1234")
        XCTAssertEqual(field.filter("no digits"), "")
        XCTAssertEqual(field.filter("0987"), "0987")
    }

    @MainActor func testDecimalFilter_oneSeparatorAllowed() {
        let field = makeField(variant: .decimal)
        XCTAssertEqual(field.filter("12.34"), "12.34")
        XCTAssertEqual(field.filter("12,34"), "12,34")
        // Only the first separator is kept
        XCTAssertEqual(field.filter("12.34.56"), "12.3456")
        XCTAssertEqual(field.filter("12.34,56"), "12.3456")
        XCTAssertEqual(field.filter("abc12.3xy"), "12.3")
    }

    @MainActor func testPINFilter_maxSixDigits() {
        let field = makeField(variant: .pin)
        XCTAssertEqual(field.filter("123456"), "123456")
        XCTAssertEqual(field.filter("1234567890"), "123456")
        XCTAssertEqual(field.filter("12ab34cd56ef78"), "123456")
        XCTAssertEqual(field.filter("12"), "12")
    }

    @MainActor func testPaymentFormat_insertsSpaceEveryFourDigits() {
        let field = makeField(variant: .payment)
        XCTAssertEqual(field.filter("1234"), "1234")
        XCTAssertEqual(field.filter("12345"), "1234 5")
        XCTAssertEqual(field.filter("12345678"), "1234 5678")
        XCTAssertEqual(field.filter("1234567890123456"), "1234 5678 9012 3456")
    }

    @MainActor func testPaymentFormat_maxSixteenDigits() {
        let field = makeField(variant: .payment)
        // 20 digits supplied, only 16 should remain (formatted to 19 chars including 3 spaces)
        let formatted = field.filter("12345678901234567890")
        XCTAssertEqual(formatted, "1234 5678 9012 3456")
        XCTAssertEqual(formatted.count, 19)
        // Non-digits stripped before grouping
        XCTAssertEqual(field.filter("4111-1111-1111-1111"), "4111 1111 1111 1111")
    }

    @MainActor func testPaymentFormat_emptyAndShortInputs() {
        let field = makeField(variant: .payment)
        XCTAssertEqual(field.filter(""), "")
        XCTAssertEqual(field.filter("1"), "1")
        XCTAssertEqual(field.filter("123"), "123")
        XCTAssertEqual(field.filter("abcd"), "")
    }

    @MainActor func testMultilineVariant_returnsInputUnchangedFromFilter() {
        // Multiline doesn't go through filter() in production (uses editorBinding),
        // but the filter switch falls through to default — verify it preserves input.
        let field = makeField(variant: .multiline)
        XCTAssertEqual(field.filter("line1\nline2"), "line1\nline2")
    }

    // MARK: - Required label flag

    @MainActor func testIsRequired_flagIsExposed() {
        let required = makeField(variant: .standard, isRequired: true)
        let optional = makeField(variant: .standard, isRequired: false)
        XCTAssertTrue(required.isRequired)
        XCTAssertFalse(optional.isRequired)
    }
}
