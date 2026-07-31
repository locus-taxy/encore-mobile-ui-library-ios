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

    private var isValid: Bool {
        ChecklistValidator.validateTextField(textValue, isRequired: isRequired, regexPattern: regexPattern)
    }

    private var validationState: TextFieldValidationState {
        isValid ? .normal : .error
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired && !isValid,
                helperText: helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: isCompleted
            )

            TextFieldView(
                value: $textValue,
                onValueChange: { newValue in
                    onValueChange(newValue)
                },
                label: hint.isEmpty ? nil : hint,
                validationState: validationState,
                isRequired: isRequired,
                keyboardType: keyboardType
            )
            .padding(.top, ChecklistItemConstants.innerTopPadding)
        }
        .padding(ChecklistItemConstants.itemPadding)
        .onChange(of: initialValue) { newValue in
            textValue = newValue
        }
    }
}
