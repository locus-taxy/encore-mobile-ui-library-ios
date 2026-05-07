import SwiftUI

#Preview("LTextField-Standard") {
    LTextFieldPreviewLayout(variant: .standard)
}

#Preview("LTextField-Password") {
    LTextFieldPreviewLayout(variant: .password)
}

#Preview("LTextField-PIN") {
    LTextFieldPINPreviewLayout()
}

#Preview("LTextField-Multiline") {
    LTextFieldPreviewLayout(variant: .multiline)
}

#Preview("LTextField-Number") {
    LTextFieldPreviewLayout(variant: .number)
}

#Preview("LTextField-Decimal") {
    LTextFieldPreviewLayout(variant: .decimal)
}

#Preview("LTextField-Payment") {
    LTextFieldPreviewLayout(variant: .payment)
}

private struct LTextFieldPreviewLayout: View {
    let variant: LTextFieldVariant
    @State private var value = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.spacing24) {
                LTextField(
                    value: $value,
                    onValueChange: { _ in },
                    variant: variant,
                    label: "Label",
                    placeholder: "Placeholder",
                    helperText: "Supporting text"
                )
                LTextField(
                    value: .constant("Input text"),
                    onValueChange: { _ in },
                    variant: variant,
                    label: "Label",
                    helperText: "Supporting text"
                )
                LTextField(
                    value: .constant("Input text"),
                    onValueChange: { _ in },
                    variant: variant,
                    label: "Label",
                    helperText: "Supporting text",
                    validationState: .validating
                )
                LTextField(
                    value: .constant("Input text"),
                    onValueChange: { _ in },
                    variant: variant,
                    label: "Label",
                    helperText: "Supporting text",
                    validationState: .success
                )
                LTextField(
                    value: .constant("Input text"),
                    onValueChange: { _ in },
                    variant: variant,
                    label: "Label",
                    validationState: .error,
                    errorMessage: "Error message"
                )
                LTextField(
                    value: .constant("Read-only value"),
                    onValueChange: { _ in },
                    variant: variant,
                    label: "Label",
                    helperText: "Supporting text",
                    isReadOnly: true
                )
                LTextField(
                    value: .constant(""),
                    onValueChange: { _ in },
                    variant: variant,
                    label: "Label",
                    helperText: "Supporting text",
                    isDisabled: true
                )
            }
            .padding(Spacing.spacing16)
        }
        .preferredColorScheme(.light)
    }
}

private struct LTextFieldPINPreviewLayout: View {
    @State private var pinValue = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.spacing24) {
                LTextField(
                    value: $pinValue,
                    onValueChange: { _ in },
                    variant: .pin,
                    label: "PIN"
                )
                LTextField(
                    value: .constant("123"),
                    onValueChange: { _ in },
                    variant: .pin,
                    label: "PIN"
                )
                LTextField(
                    value: .constant("123456"),
                    onValueChange: { _ in },
                    variant: .pin,
                    label: "PIN",
                    validationState: .error,
                    errorMessage: "Incorrect PIN"
                )
                LTextField(
                    value: .constant(""),
                    onValueChange: { _ in },
                    variant: .pin,
                    label: "PIN",
                    isDisabled: true
                )
            }
            .padding(Spacing.spacing16)
        }
        .preferredColorScheme(.light)
    }
}
