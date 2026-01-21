import Foundation
import SwiftUI

enum TriState {
    case on
    case off
    case indeterminate
}

struct TriStateCheckbox: View {
    var state: TriState
    var action: () -> Void

    var body: some View {
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
