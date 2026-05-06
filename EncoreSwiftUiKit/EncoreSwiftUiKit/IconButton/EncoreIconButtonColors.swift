import SwiftUI

func encoreIconButtonIconColor(
    color: EncoreIconButtonColor,
    isEnabled: Bool
) -> Color {
    if !isEnabled { return Color.encore("Action/Disabled") }
    switch color {
    case .defaultColor: return Color.encore("Action/Active")
    case .primary: return Color.encore("Primary/Main")
    case .error: return Color.encore("Error/Main")
    case .success: return Color.encore("Success/Main")
    }
}
