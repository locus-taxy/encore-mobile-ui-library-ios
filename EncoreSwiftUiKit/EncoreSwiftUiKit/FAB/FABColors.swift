import SwiftUI

internal func fabBackgroundColor(_ color: FABColor) -> Color {
    switch color {
    case .primary:   return Color("primary/main")
    case .secondary: return Color("secondary/main")
    case .default:   return Color("grey/300")
    }
}

internal func fabContentColor(_ color: FABColor) -> Color {
    switch color {
    case .primary:   return Color("primary/contrast_text")
    case .secondary: return Color("secondary/contrast_text")
    case .default:   return Color("text/primary")
    }
}
