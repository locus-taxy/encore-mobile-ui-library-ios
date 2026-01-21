import Foundation
import SwiftUI

public enum TriState {
    case on
    case off
    case indeterminate
}

public struct TriStateCheckbox: View {
    public var state: TriState
    public var action: () -> Void

    public var body: some View {
        Button(action: action) {
            switch state {
            case .on:
                EncoreImage(iconName: "LCheckboxFilled", size: 16)
            case .indeterminate:
                EncoreImage(iconName: "LCheckboxIndeterminate", size: 16)
            case .off:
                EncoreImage(iconName: "LCheckboxOutline", size: 16)
            }
        }
        .padding(2)
        .buttonStyle(.plain)
    }
}
