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
    var helperText: String? = nil
    var itemIndex: Int? = nil
    var totalItems: Int? = nil
    var isCompleted: Bool = false

    public init(
        title: String,
        isRequired: Bool = false,
        showRequiredIndicator: Bool = true,
        requiredText: String = "Required",
        helperText: String? = nil,
        itemIndex: Int? = nil,
        totalItems: Int? = nil,
        isCompleted: Bool = false
    ) {
        self.title = title
        self.isRequired = isRequired
        self.showRequiredIndicator = showRequiredIndicator
        self.requiredText = requiredText
        self.helperText = helperText
        self.itemIndex = itemIndex
        self.totalItems = totalItems
        self.isCompleted = isCompleted
    }

    private var titleFont: Font {
        .system(size: ChecklistItemConstants.titleFontSize, weight: .medium)
    }

    /// Title text with the required asterisk concatenated inline, so `*` sits
    /// immediately after the label (and wraps with it) rather than being pushed
    /// to the trailing edge by a full-width title frame.
    private var titleWithAsterisk: Text {
        let base = Text(title).font(titleFont).foregroundColor(.primary)
        guard isRequired && showRequiredIndicator else { return base }
        return base + Text(" *").font(titleFont).foregroundColor(Color.encore("Error/Main"))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing2) {
            // Row 1: counter + completion tick
            HStack(spacing: Spacing.spacing4) {
                if let itemIndex, let totalItems {
                    Text("\(itemIndex)/\(totalItems)")
                        .typography(Typography.Input.helper)
                        .foregroundColor(Color.encore("Text/Secondary"))
                }
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.encore("Success/Main"))
                }
            }
            // Row 2: title with the persistent required asterisk inline, right
            // after the label text (not pushed to the trailing edge).
            titleWithAsterisk
                .lineSpacing(ChecklistItemConstants.titleLineHeight - ChecklistItemConstants.titleFontSize)
                .frame(maxWidth: .infinity, alignment: .leading)
            // Row 3: helper text
            if let helperText {
                Text(helperText)
                    .typography(Typography.Input.helper)
                    .foregroundColor(Color.encore("Text/Secondary"))
            }
        }
    }
}
