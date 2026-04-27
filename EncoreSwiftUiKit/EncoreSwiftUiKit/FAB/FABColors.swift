import SwiftUI

internal func fabBackgroundColor(_ color: FABColor) -> Color {
    switch color {
    case .primary:   return Color.encore("Primary/Main")
    case .secondary: return Color.encore("Secondary/Main")
    case .default:   return Color.encore("Grey/300")
    }
}

internal func fabContentColor(_ color: FABColor) -> Color {
    switch color {
    case .primary:   return Color.encore("Primary/ContrastText")
    case .secondary: return Color.encore("Secondary/ContrastText")
    case .default:   return Color.encore("Text/Primary")
    }
}
