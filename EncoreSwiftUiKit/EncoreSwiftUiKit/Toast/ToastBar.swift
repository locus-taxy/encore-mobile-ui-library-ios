import SwiftUI

public enum ToastVariant {
    case success
    case failure

    var iconName: String {
        switch self {
        case .success: return "LCheckCircle"
        case .failure: return "LInfo"
        }
    }
}

public struct ToastBar: View {
    let text: String
    let variant: ToastVariant
    let onDismiss: () -> Void

    public init(text: String, variant: ToastVariant, onDismiss: @escaping () -> Void) {
        self.text = text
        self.variant = variant
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: 0) {
            EncoreIcon(iconName: variant.iconName, size: 20)
                .foregroundStyle(Color.white)
                .padding(.trailing, 12)

            Text(text)
                .typography(Typography.subtitle1)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDismiss) {
                EncoreIcon(iconName: "LClose", size: 24)
                    .foregroundStyle(Color.white)
                    .frame(width: 48, height: 48)
            }
            .padding(.leading, 16)
        }
        .padding(.leading, 12)
        .padding(.vertical, 4)
        .background(Color.encore("Action/Active"))
        .cornerRadius(8)
        .shadow(color: Color(red: 17/255, green: 19/255, blue: 24/255).opacity(0.16), radius: 4, x: 0, y: 0)
    }
}

#Preview("Success") {
    ToastBar(text: "Clocked in to shift 1", variant: .success, onDismiss: {})
        .padding()
}

#Preview("Failure") {
    ToastBar(text: "Something went wrong. Try again.", variant: .failure, onDismiss: {})
        .padding()
}
