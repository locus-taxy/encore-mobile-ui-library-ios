import XCTest
import SwiftUI
@testable import EncoreSwiftUiKit

final class TypographyTests: XCTestCase {

    func testH1TrackingIsZero() {
        XCTAssertEqual(Typography.h1.tracking, 0)
    }

    func testLabel3HasCorrectTracking() {
        XCTAssertEqual(Typography.label3.tracking, 0.46, accuracy: 0.001)
    }

    func testCaptionTracking() {
        XCTAssertEqual(Typography.caption.tracking, 0.4, accuracy: 0.001)
    }

    func testAlertTitleTracking() {
        XCTAssertEqual(Typography.Alert.title.tracking, 0.15, accuracy: 0.001)
    }

    func testChipLabelXLgTracking() {
        XCTAssertEqual(Typography.Chip.labelXLg.tracking, 0.16, accuracy: 0.001)
    }

    func testNavSidebarCompactTracking() {
        XCTAssertEqual(Typography.Nav.sidebarCompact.tracking, 0.04, accuracy: 0.001)
    }

    func testAllBaseStylesAreDefined() {
        let styles: [TypographyStyle] = [
            Typography.h1, Typography.h2, Typography.h3, Typography.h4, Typography.h5, Typography.h6,
            Typography.label0, Typography.label1, Typography.label2, Typography.label3,
            Typography.body0, Typography.body1, Typography.body2, Typography.body3,
            Typography.italics0, Typography.italics1, Typography.italics2, Typography.italics3,
            Typography.link0, Typography.link1, Typography.link2,
            Typography.subtitle1, Typography.subtitle2,
            Typography.overline0, Typography.overline1, Typography.overline2, Typography.overline3,
            Typography.caption
        ]
        XCTAssertEqual(styles.count, 28)
    }
}
