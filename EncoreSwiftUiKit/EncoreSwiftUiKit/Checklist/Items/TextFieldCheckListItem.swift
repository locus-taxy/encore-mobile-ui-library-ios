import SwiftUI

/// Text field checklist item matching Figma design specifications.
/// Composes ChecklistHeader + TextFieldView.
/// Mirrors Android's `TextFieldCheckListItem` composable.
public struct TextFieldCheckListItem: View {
    let title: String
    var helperText: String? = nil
    var itemIndex: Int? = nil
    var totalItems: Int? = nil
    var isCompleted: Bool = false
    let initialValue: String
    let onValueChange: (String) -> Void
    let isRequired: Bool
    let hint: String
    let regexPattern: String?
    var keyboardType: UIKeyboardType

    @State private var textValue: String

    public init(
        title: String,
        helperText: String? = nil,
        itemIndex: Int? = nil,
        totalItems: Int? = nil,
        isCompleted: Bool = false,
        initialValue: String,
        onValueChange: @escaping (String) -> Void,
        isRequired: Bool,
        hint: String = "",
        regexPattern: String? = nil,
        keyboardType: UIKeyboardType = .default
    ) {
        self.title = title
        self.helperText = helperText
        self.itemIndex = itemIndex
        self.totalItems = totalItems
        self.isCompleted = isCompleted
        self.initialValue = initialValue
        self.onValueChange = onValueChange
        self.isRequired = isRequired
        self.hint = hint
        self.regexPattern = regexPattern
        self.keyboardType = keyboardType
        self._textValue = State(initialValue: initialValue)
    }

    /// Maps the item's keyboard type to the LTextField variant that drives the
    /// keyboard + numeric filtering.
    private var fieldVariant: LTextFieldVariant {
        switch keyboardType {
        case .numberPad: return .number
        case .decimalPad: return .decimal
        default: return .standard
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Helper text is NOT passed to the header for text fields — it renders
            // below the input (with an info icon) inside LTextField, per Figma.
            ChecklistHeader(
                title: title,
                isRequired: isRequired,
                helperText: nil,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: isCompleted
            )

            LTextField(
                value: $textValue,
                onValueChange: { newValue in
                    onValueChange(newValue)
                },
                variant: fieldVariant,
                label: nil,
                isRequired: false,
                placeholder: hint.isEmpty ? nil : hint,
                helperText: helperText,
                validationState: .normal
            )
            .padding(.top, ChecklistItemConstants.innerTopPadding)
        }
        .padding(ChecklistItemConstants.itemPadding)
        .onChange(of: initialValue) { newValue in
            textValue = newValue
        }
    }
}
