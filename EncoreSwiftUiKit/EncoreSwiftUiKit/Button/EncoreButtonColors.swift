import SwiftUI

internal func encoreButtonBackgroundColor(
    color: EncoreButtonColor,
    variant: EncoreButtonVariant,
    isEnabled: Bool
) -> Color {
    guard variant == .contained else { return Color.clear }
    if !isEnabled { return Color.encore("Action/DisabledBackground") }
    switch color {
    case .primary: return Color.encore("Primary/Main")
    case .error:   return Color.encore("Error/Main")
    case .success: return Color.encore("Success/Main")
    }
}

internal func encoreButtonContentColor(
    color: EncoreButtonColor,
    variant: EncoreButtonVariant,
    isEnabled: Bool
) -> Color {
    if !isEnabled { return Color.encore("Action/Disabled") }
    switch variant {
    case .contained:
        switch color {
        case .primary: return Color.encore("Primary/ContrastText")
        case .error:   return Color.encore("Error/ContrastText")
        case .success: return Color.encore("Success/ContrastText")
        }
    case .outlined, .text:
        switch color {
        case .primary: return Color.encore("Primary/Main")
        case .error:   return Color.encore("Error/Main")
        case .success: return Color.encore("Success/Main")
        }
    }
}

internal func encoreButtonBorderColor(
    color: EncoreButtonColor,
    isEnabled: Bool
) -> Color {
    if !isEnabled { return Color.encore("Action/DisabledBackground") }
    switch color {
    case .primary: return Color.encore("Primary/OutlinedBorder")
    case .error:   return Color.encore("Error/OutlinedBorder")
    case .success: return Color.encore("Success/OutlinedBorder")
    }
}
