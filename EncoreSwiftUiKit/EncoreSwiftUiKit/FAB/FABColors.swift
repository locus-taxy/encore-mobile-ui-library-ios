import SwiftUI

internal func fabBackgroundColor(_ color: FABColor) -> Color {
    switch color {
    case .primary:   return Color("Primary/Main", bundle: BundleToken.bundle)
    case .secondary: return Color("Secondary/Main", bundle: BundleToken.bundle)
    case .default:   return Color("Grey/300", bundle: BundleToken.bundle)
    }
}

internal func fabContentColor(_ color: FABColor) -> Color {
    switch color {
    case .primary:   return Color("Primary/ContrastText", bundle: BundleToken.bundle)
    case .secondary: return Color("Secondary/ContrastText", bundle: BundleToken.bundle)
    case .default:   return Color("Text/Primary", bundle: BundleToken.bundle)
    }
}
