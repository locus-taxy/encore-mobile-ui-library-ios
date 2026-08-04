@testable import EncoreSwiftUiKit
import XCTest

final class ChecklistItemHelperTextTests: XCTestCase {

    func testHelperTextDefaultsToNil() {
        let item = ChecklistItem(key: "k", item: "Title", format: .textField)
        XCTAssertNil(item.helperText)
    }

    func testHelperTextDecodesFromJSON() throws {
        let json = """
        { "key": "k", "item": "Title", "optional": false, "format": "TEXT_FIELD", "helperText": "Fill me" }
        """
        let item = try JSONDecoder().decode(ChecklistItem.self, from: Data(json.utf8))
        XCTAssertEqual(item.helperText, "Fill me")
    }
}
