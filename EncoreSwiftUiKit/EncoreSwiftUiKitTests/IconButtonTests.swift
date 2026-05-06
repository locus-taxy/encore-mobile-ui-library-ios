@testable import EncoreSwiftUiKit
import SwiftUI
import XCTest

final class IconButtonTests: XCTestCase {

    func testEncoreIconButtonColorHasFourCases() {
        let cases: [EncoreIconButtonColor] = [.defaultColor, .primary, .error, .success]
        XCTAssertEqual(cases.count, 4)
    }

    func testEncoreIconButtonSizeHasThreeCases() {
        let cases: [EncoreIconButtonSize] = [.small, .medium, .large]
        XCTAssertEqual(cases.count, 3)
    }

    func testIconColorDefaultEnabled() {
        XCTAssertNotNil(encoreIconButtonIconColor(color: .defaultColor, isEnabled: true))
    }

    func testIconColorDefaultDisabled() {
        XCTAssertNotNil(encoreIconButtonIconColor(color: .defaultColor, isEnabled: false))
    }

    func testIconColorPrimaryEnabled() {
        XCTAssertNotNil(encoreIconButtonIconColor(color: .primary, isEnabled: true))
    }

    func testIconColorPrimaryDisabled() {
        XCTAssertNotNil(encoreIconButtonIconColor(color: .primary, isEnabled: false))
    }

    func testIconColorErrorEnabled() {
        XCTAssertNotNil(encoreIconButtonIconColor(color: .error, isEnabled: true))
    }

    func testIconColorErrorDisabled() {
        XCTAssertNotNil(encoreIconButtonIconColor(color: .error, isEnabled: false))
    }

    func testIconColorSuccessEnabled() {
        XCTAssertNotNil(encoreIconButtonIconColor(color: .success, isEnabled: true))
    }

    func testIconColorSuccessDisabled() {
        XCTAssertNotNil(encoreIconButtonIconColor(color: .success, isEnabled: false))
    }
}
