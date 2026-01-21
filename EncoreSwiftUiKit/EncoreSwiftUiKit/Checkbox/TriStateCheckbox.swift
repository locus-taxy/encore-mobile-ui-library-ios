import Foundation
import SwiftUI

public enum TriState {
    case on
    case off
    case indeterminate
}

public struct TriStateCheckbox: View {
    var state: TriState
    var action: () -> Void

    public init(state: TriState, action: @escaping () -> Void) {
        self.state = state
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            switch state {
            case .on:
                EncoreIcon(iconName: "LCheckboxFilled", size: 16)
            case .indeterminate:
                EncoreIcon(iconName: "LCheckboxIndeterminate", size: 16)
            case .off:
                EncoreIcon(iconName: "LCheckboxOutline", size: 16)
            }
        }
        .padding(2)
        .buttonStyle(.plain)
    }
}
