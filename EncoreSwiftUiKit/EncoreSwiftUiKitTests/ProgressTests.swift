@testable import EncoreSwiftUiKit
import SwiftUI
import XCTest

final class ProgressTests: XCTestCase {

    // MARK: - CircularProgressSize enum

    func testCircularProgressSizeSmall() {
        XCTAssertEqual(CircularProgressSize.small.pt, 16)
        XCTAssertEqual(CircularProgressSize.small.strokeWidth, 2)
    }

    func testCircularProgressSizeMedium() {
        XCTAssertEqual(CircularProgressSize.medium.pt, 32)
        XCTAssertEqual(CircularProgressSize.medium.strokeWidth, 4)
    }

    func testCircularProgressSizeLarge() {
        XCTAssertEqual(CircularProgressSize.large.pt, 40)
        XCTAssertEqual(CircularProgressSize.large.strokeWidth, 5)
    }

    func testCircularProgressSizeXLarge() {
        XCTAssertEqual(CircularProgressSize.xlarge.pt, 64)
        XCTAssertEqual(CircularProgressSize.xlarge.strokeWidth, 8)
    }

    // MARK: - Percentage string formatting

    /// Mirrors the formula used in CircularProgressView and LinearProgressView:
    /// "\(Int(clamped * 100))%"
    private func percentageString(_ value: Double) -> String {
        let clamped = max(0, min(1, value))
        return "\(Int(clamped * 100))%"
    }

    func testPercentageStringZero() {
        XCTAssertEqual(percentageString(0.0), "0%")
    }

    func testPercentageStringHalf() {
        XCTAssertEqual(percentageString(0.5), "50%")
    }

    func testPercentageStringFull() {
        XCTAssertEqual(percentageString(1.0), "100%")
    }

    func testPercentageStringFraction() {
        XCTAssertEqual(percentageString(0.33), "33%")
    }

    func testPercentageStringFloorBehaviour() {
        // Int() truncates toward zero, so 0.999 * 100 = 99.9 -> 99
        XCTAssertEqual(percentageString(0.999), "99%")
    }

    // MARK: - Value clamping

    /// Mirrors the formula used in the progress views:
    /// max(0, min(1, value))
    private func clamp(_ value: Double) -> Double {
        return max(0, min(1, value))
    }

    func testClampNegativeValue() {
        XCTAssertEqual(clamp(-0.1), 0.0, accuracy: 0.0001)
    }

    func testClampValueAboveOne() {
        XCTAssertEqual(clamp(1.5), 1.0, accuracy: 0.0001)
    }

    func testClampValueInRange() {
        XCTAssertEqual(clamp(0.5), 0.5, accuracy: 0.0001)
    }

    // MARK: - Combined clamp + percentage (matches view rendering exactly)

    func testPercentageStringClampsNegative() {
        XCTAssertEqual(percentageString(-0.5), "0%")
    }

    func testPercentageStringClampsAboveOne() {
        XCTAssertEqual(percentageString(1.5), "100%")
    }
}
