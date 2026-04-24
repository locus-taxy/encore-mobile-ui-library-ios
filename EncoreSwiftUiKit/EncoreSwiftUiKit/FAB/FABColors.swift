import SwiftUI

internal func fabBackgroundColor(_ color: FABColor) -> Color {
    switch color {
    case .primary:   return Color("Primary/Main")
    case .secondary: return Color("Secondary/Main")
    case .default:   return Color("Grey/300")
    }
}

internal func fabContentColor(_ color: FABColor) -> Color {
    switch color {
    case .primary:   return Color("Primary/ContrastText")
    case .secondary: return Color("Secondary/ContrastText")
    case .default:   return Color("Text/Primary")
    }
}
