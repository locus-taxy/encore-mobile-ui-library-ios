import SwiftUI

/// Validation state for `LTextField`.
public enum LTextFieldValidationState {
    case normal
    case validating
    case success
    case error
}

/// Variant of `LTextField`.
/// `password` and `pin` are reserved for follow-up tasks (T003).
public enum LTextFieldVariant {
    case standard
    case number
    case decimal
    case password
    case pin
    case multiline
    case payment
}

/// Reusable text field component matching Figma design specifications
/// (node 24720:45411). Mirrors Android's `LTextField` composable.
public struct LTextField: View {
    @Binding public var value: String
    public let onValueChange: (String) -> Void
    public var variant: LTextFieldVariant
    public var label: String?
    public var isRequired: Bool
    public var placeholder: String?
    public var helperText: String?
    public var validationState: LTextFieldValidationState
    public var errorMessage: String?
    public var isReadOnly: Bool
    public var isDisabled: Bool

    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible: Bool = false

    private static let pinLength: Int = 6

    public init(
        value: Binding<String>,
        onValueChange: @escaping (String) -> Void,
        variant: LTextFieldVariant = .standard,
        label: String? = nil,
        isRequired: Bool = false,
        placeholder: String? = nil,
        helperText: String? = nil,
        validationState: LTextFieldValidationState = .normal,
        errorMessage: String? = nil,
        isReadOnly: Bool = false,
        isDisabled: Bool = false
    ) {
        self._value = value
        self.onValueChange = onValueChange
        self.variant = variant
        self.label = label
        self.isRequired = isRequired
        self.placeholder = placeholder
        self.helperText = helperText
        self.validationState = validationState
        self.errorMessage = errorMessage
        self.isReadOnly = isReadOnly
        self.isDisabled = isDisabled
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let label = label {
                labelRow(label)
                    .padding(.bottom, Spacing.spacing4)
            }

            if variant == .pin {
                pinContainer
            } else {
                inputContainer
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: containerMinHeight, alignment: .top)
                    .background(backgroundFill)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
            }

            helperRow
                .padding(.top, Spacing.spacing2)
        }
    }

    // MARK: - Subviews

    private func labelRow(_ text: String) -> some View {
        HStack(spacing: 0) {
            Text(text)
            if isRequired {
                Text(" *")
            }
        }
        .typography(Typography.Input.label)
        .foregroundColor(labelColor)
    }

    private var inputContainer: some View {
        HStack(spacing: Spacing.spacing8) {
            leadingAdornment
            inputField
            trailingAdornment
        }
        .padding(.horizontal, Spacing.spacing16)
        .padding(.vertical, Spacing.spacing12)
    }

    @ViewBuilder
    private var leadingAdornment: some View {
        if variant == .payment {
            Image(systemName: "creditcard")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(Color.encore("Action/Active"))
        }
    }

    @ViewBuilder
    private var inputField: some View {
        if variant == .password {
            if isPasswordVisible {
                TextField(placeholder ?? "", text: fieldBinding)
                    .focused($isFocused)
                    .typography(Typography.Input.value)
                    .foregroundColor(textColor)
                    .disabled(isDisabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                SecureField(placeholder ?? "", text: fieldBinding)
                    .focused($isFocused)
                    .typography(Typography.Input.value)
                    .foregroundColor(textColor)
                    .disabled(isDisabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else if variant == .multiline {
            ZStack(alignment: .topLeading) {
                if value.isEmpty, let placeholder = placeholder {
                    Text(placeholder)
                        .typography(Typography.Input.value)
                        .foregroundColor(Color.encore("Text/Secondary"))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: editorBinding)
                    .focused($isFocused)
                    .typography(Typography.Input.value)
                    .foregroundColor(textColor)
                    .frame(minHeight: 80)
                    .padding(.horizontal, -4)
                    .scrollContentBackgroundHidden()
                    .disabled(isDisabled)
            }
        } else {
            TextField(placeholder ?? "", text: fieldBinding)
                .focused($isFocused)
                .typography(Typography.Input.value)
                .foregroundColor(textColor)
                .keyboardType(keyboardType)
                .disabled(isDisabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var trailingAdornment: some View {
        HStack(spacing: Spacing.spacing4) {
            switch validationState {
            case .validating:
                ProgressView()
                    .controlSize(.small)
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color.encore("Error/Main"))
            case .error:
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color.encore("Error/Main"))
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color.encore("Success/Main"))
            case .normal:
                EmptyView()
            }

            if variant == .password {
                passwordToggleButton
            }
        }
    }

    private var passwordToggleButton: some View {
        Button(action: { isPasswordVisible.toggle() }) {
            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(Color.encore("Action/Active"))
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var pinContainer: some View {
        GeometryReader { geometry in
            let totalSpacing = Spacing.spacing8 * CGFloat(Self.pinLength - 1)
            let boxWidth = max(0, (geometry.size.width - totalSpacing) / CGFloat(Self.pinLength))
            ZStack(alignment: .leading) {
                HStack(spacing: Spacing.spacing8) {
                    ForEach(0 ..< Self.pinLength, id: \.self) { index in
                        pinBox(index: index)
                            .frame(width: boxWidth, height: 48)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { isFocused = true }

                TextField("", text: fieldBinding)
                    .focused($isFocused)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .disabled(isDisabled)
                    .frame(width: 1, height: 1)
                    .opacity(0.001)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: 48)
    }

    @ViewBuilder
    private func pinBox(index: Int) -> some View {
        let activeIndex = min(value.count, Self.pinLength - 1)
        let isActive = isFocused && index == activeIndex
        let hasDigit = index < value.count

        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(pinBoxFill)
            RoundedRectangle(cornerRadius: 4)
                .stroke(pinBoxBorderColor(isActive: isActive), lineWidth: pinBoxBorderWidth(isActive: isActive))
            if hasDigit {
                Text("\u{25CF}")
                    .typography(Typography.Input.value)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func pinBoxBorderColor(isActive: Bool) -> Color {
        if isDisabled { return .clear }
        if validationState == .error { return Color.encore("Error/Main") }
        if isActive { return Color.encore("Primary/Main") }
        return Color.encore("Input/OutlinedEnabledBorder")
    }

    private func pinBoxBorderWidth(isActive: Bool) -> CGFloat {
        if isDisabled { return 0 }
        if validationState == .error { return 1 }
        return isActive ? 2 : 1
    }

    private var pinBoxFill: Color {
        isDisabled ? Color.encore("Action/DisabledBackground") : .clear
    }

    @ViewBuilder
    private var helperRow: some View {
        let displayText = (validationState == .error ? errorMessage : nil) ?? helperText
        if let displayText = displayText, !displayText.isEmpty {
            HStack(spacing: Spacing.spacing4) {
                if let symbol = helperIconSymbol {
                    Image(systemName: symbol)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(helperColor)
                }
                Text(displayText)
                    .typography(Typography.Input.helper)
                    .foregroundColor(helperColor)
            }
        }
    }

    // MARK: - Bindings

    private var fieldBinding: Binding<String> {
        Binding(
            get: { value },
            set: { newValue in
                let filtered = filter(newValue)
                if isReadOnly { return }
                if filtered != value {
                    onValueChange(filtered)
                }
            }
        )
    }

    private var editorBinding: Binding<String> {
        Binding(
            get: { value },
            set: { newValue in
                if isReadOnly { return }
                if newValue != value {
                    onValueChange(newValue)
                }
            }
        )
    }

    func filter(_ input: String) -> String {
        switch variant {
        case .number:
            return input.filter { $0.isNumber }
        case .pin:
            return String(input.filter { $0.isNumber }.prefix(Self.pinLength))
        case .decimal:
            var seenSeparator = false
            var result = ""
            for ch in input {
                if ch.isNumber {
                    result.append(ch)
                } else if (ch == "." || ch == ",") && !seenSeparator {
                    seenSeparator = true
                    result.append(ch)
                }
            }
            return result
        case .payment:
            let digits = input.filter { $0.isNumber }.prefix(16)
            var formatted = ""
            for (idx, ch) in digits.enumerated() {
                if idx > 0 && idx % 4 == 0 {
                    formatted.append(" ")
                }
                formatted.append(ch)
            }
            return formatted
        default:
            return input
        }
    }

    // MARK: - State-derived styling

    private var keyboardType: UIKeyboardType {
        switch variant {
        case .number: return .numberPad
        case .decimal: return .decimalPad
        case .payment: return .numberPad
        default: return .default
        }
    }

    private var containerMinHeight: CGFloat {
        variant == .multiline ? 80 : 48
    }

    private var labelColor: Color {
        if isDisabled { return Color.encore("Text/Disabled") }
        switch validationState {
        case .success: return Color.encore("Success/Main")
        case .error: return Color.encore("Error/Main")
        case .validating: return Color.encore("Primary/Main")
        case .normal:
            return isFocused ? Color.encore("Primary/Main") : Color.encore("Text/Secondary")
        }
    }

    private var textColor: Color {
        isDisabled ? Color.encore("Text/Disabled") : Color.encore("Text/Primary")
    }

    private var borderColor: Color {
        if isDisabled { return .clear }
        if isReadOnly { return Color.encore("Input/OutlinedEnabledBorder") }
        switch validationState {
        case .success: return Color.encore("Success/Main")
        case .error: return Color.encore("Error/Main")
        case .validating: return Color.encore("Primary/Main")
        case .normal:
            return isFocused ? Color.encore("Primary/Main") : Color.encore("Input/OutlinedEnabledBorder")
        }
    }

    private var borderWidth: CGFloat {
        if isDisabled { return 0 }
        switch validationState {
        case .validating: return 2
        case .normal: return isFocused ? 2 : 1
        case .success, .error: return 1
        }
    }

    private var backgroundFill: Color {
        if isDisabled { return Color.encore("Action/DisabledBackground") }
        if isReadOnly { return Color.encore("Input/OutlinedReadOnlyFill") }
        return .clear
    }

    private var helperColor: Color {
        switch validationState {
        case .success: return Color.encore("Success/Main")
        case .error: return Color.encore("Error/Main")
        case .normal, .validating: return Color.encore("Text/Secondary")
        }
    }

    private var helperIconSymbol: String? {
        switch validationState {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        case .normal, .validating: return nil
        }
    }
}

// MARK: - iOS 15 compatibility helper for TextEditor background

private extension View {
    @ViewBuilder
    func scrollContentBackgroundHidden() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}
