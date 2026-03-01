import SwiftUI

/// Reusable required field indicator.
/// Mirrors Android's `RequiredIndicator` composable.
public struct RequiredIndicator: View {
    let isVisible: Bool
    var requiredText: String = "Required"

    public init(isVisible: Bool, requiredText: String = "Required") {
        self.isVisible = isVisible
        self.requiredText = requiredText
    }

    public var body: some View {
        if isVisible {
            Text(requiredText)
                .font(.system(size: ChecklistItemConstants.requiredTextFontSize))
                .foregroundColor(.red)
                .lineSpacing(ChecklistItemConstants.requiredTextLineHeight - ChecklistItemConstants.requiredTextFontSize)
        }
    }
}

/// Common header with title and required indicator.
/// Mirrors Android's `ChecklistHeader` composable.
public struct ChecklistHeader: View {
    let title: String
    var isRequired: Bool = false
    var showRequiredIndicator: Bool = true
    var requiredText: String = "Required"

    public init(
        title: String,
        isRequired: Bool = false,
        showRequiredIndicator: Bool = true,
        requiredText: String = "Required"
    ) {
        self.title = title
        self.isRequired = isRequired
        self.showRequiredIndicator = showRequiredIndicator
        self.requiredText = requiredText
    }

    public var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: ChecklistItemConstants.titleFontSize, weight: .medium))
                .foregroundColor(.primary)
                .lineSpacing(ChecklistItemConstants.titleLineHeight - ChecklistItemConstants.titleFontSize)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)

            if showRequiredIndicator {
                RequiredIndicator(isVisible: isRequired, requiredText: requiredText)
            }
        }
    }
}

