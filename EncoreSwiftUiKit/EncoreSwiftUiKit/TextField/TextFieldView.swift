import SwiftUI

/// Validation state for text field.
public enum TextFieldValidationState {
    case normal
    case error
    case success
}

/// Reusable text field component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `MaterialTextField` composable.
public struct TextFieldView: View {
    @Binding var value: String
    let onValueChange: (String) -> Void
    var label: String?
    var validationState: TextFieldValidationState
    var isRequired: Bool
    var keyboardType: UIKeyboardType

    public init(
        value: Binding<String>,
        onValueChange: @escaping (String) -> Void,
        label: String? = nil,
        validationState: TextFieldValidationState = .normal,
        isRequired: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) {
        self._value = value
        self.onValueChange = onValueChange
        self.label = label
        self.validationState = validationState
        self.isRequired = isRequired
        self.keyboardType = keyboardType
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(label ?? "", text: $value)
                .keyboardType(keyboardType)
                .textFieldStyle(.roundedBorder)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: validationState == .error ? 1.5 : 0)
                )
                .onChange(of: value) { newValue in
                    onValueChange(newValue)
                }
        }
    }

    private var borderColor: Color {
        switch validationState {
        case .normal: return .clear
        case .error: return .red
        case .success: return .green
        }
    }
}

