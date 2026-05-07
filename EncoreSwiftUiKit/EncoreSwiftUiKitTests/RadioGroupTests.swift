@testable import EncoreSwiftUiKit
import SwiftUI
import XCTest

final class RadioGroupTests: XCTestCase {

    // MARK: - RadioView prop assignment

    @MainActor func testRadioView_storesPropsAsPassed() {
        let view = RadioView(
            label: "Option A",
            secondaryLabel: "details",
            isSelected: true,
            isDisabled: false,
            labelPlacement: .start,
            onTap: {}
        )
        XCTAssertEqual(view.label, "Option A")
        XCTAssertEqual(view.secondaryLabel, "details")
        XCTAssertTrue(view.isSelected)
        XCTAssertFalse(view.isDisabled)
        if case .start = view.labelPlacement {} else { XCTFail("expected .start placement") }
    }

    @MainActor func testRadioView_defaultsForOptionalParams() {
        let view = RadioView(label: "Plain", isSelected: false, onTap: {})
        XCTAssertNil(view.secondaryLabel)
        XCTAssertFalse(view.isDisabled)
        if case .end = view.labelPlacement {} else { XCTFail("expected default .end placement") }
    }

    // MARK: - RadioView onTap behaviour

    @MainActor func testRadioView_onTapClosureFires() {
        var fired = false
        let view = RadioView(label: "Tap", isSelected: false, onTap: { fired = true })
        view.onTap()
        XCTAssertTrue(fired)
    }

    // The view itself guards `onTap` behind `!isDisabled` inside its tap gesture
    // (RadioGroupView.swift). The closure stored on `RadioView` is the raw callback,
    // so we cannot exercise the guard directly without rendering. Verify the guard
    // semantics indirectly via RadioGroupView, which routes through that gesture
    // when constructed but its `onSelect` is what the parent observes.

    // MARK: - RadioIcon color logic

    @MainActor func testRadioIcon_storesStateProps() {
        let selectedEnabled = RadioIcon(isSelected: true, isDisabled: false)
        let unselectedEnabled = RadioIcon(isSelected: false, isDisabled: false)
        let selectedDisabled = RadioIcon(isSelected: true, isDisabled: true)
        XCTAssertTrue(selectedEnabled.isSelected)
        XCTAssertFalse(selectedEnabled.isDisabled)
        XCTAssertFalse(unselectedEnabled.isSelected)
        XCTAssertTrue(selectedDisabled.isDisabled)
    }

    // MARK: - RadioGroupView prop assignment

    @MainActor func testRadioGroupView_storesPropsAsPassed() {
        let group = RadioGroupView(
            options: ["A", "B", "C"],
            selectedIndex: 1,
            isDisabled: true,
            isRow: true,
            label: "Group label",
            helperText: "helper",
            isError: true,
            onSelect: { _ in }
        )
        XCTAssertEqual(group.options, ["A", "B", "C"])
        XCTAssertEqual(group.selectedIndex, 1)
        XCTAssertTrue(group.isDisabled)
        XCTAssertTrue(group.isRow)
        XCTAssertEqual(group.label, "Group label")
        XCTAssertEqual(group.helperText, "helper")
        XCTAssertTrue(group.isError)
    }

    @MainActor func testRadioGroupView_defaultsForOptionalParams() {
        let group = RadioGroupView(
            options: ["X", "Y"],
            selectedIndex: nil,
            onSelect: { _ in }
        )
        XCTAssertNil(group.selectedIndex)
        XCTAssertFalse(group.isDisabled)
        XCTAssertFalse(group.isRow)
        XCTAssertNil(group.label)
        XCTAssertNil(group.helperText)
        XCTAssertFalse(group.isError)
    }

    // MARK: - RadioGroupView onSelect callback

    @MainActor func testRadioGroupView_onSelectPassesIndex() {
        var receivedIndex: Int?
        let group = RadioGroupView(
            options: ["A", "B", "C"],
            selectedIndex: 0,
            onSelect: { idx in receivedIndex = idx }
        )
        group.onSelect(2)
        XCTAssertEqual(receivedIndex, 2)
    }

    @MainActor func testRadioGroupView_onSelectFiresMultipleTimes() {
        var calls: [Int] = []
        let group = RadioGroupView(
            options: ["A", "B"],
            selectedIndex: nil,
            onSelect: { calls.append($0) }
        )
        group.onSelect(0)
        group.onSelect(1)
        group.onSelect(0)
        XCTAssertEqual(calls, [0, 1, 0])
    }
}
