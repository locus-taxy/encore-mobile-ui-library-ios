//
//  TriStateCheckbox.swift
//  EncoreSwiftUiKit
//
//  Created by Kanj on 21/01/26.
//

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
                Image("LCheckboxFilled")
                    .frame(width: 16, height: 16)
            case .indeterminate:
                Image("LCheckboxIndeterminate")
                    .frame(width: 16, height: 16)
            case .off:
                Image("LCheckboxOutline")
                    .frame(width: 16, height: 16)
            }
        }
        .padding(2)
        .buttonStyle(.plain)
    }
}
