import SwiftUI

/// Signature checklist item for signature capture matching Figma design specifications.
/// Composes ChecklistHeader + SignatureCanvasView.
/// Mirrors Android's `SignatureCheckListItem` composable.
public struct SignatureCheckListItem: View {
    let title: String
    let initialSignatureURL: URL?
    let onSignatureSelected: (URL?) -> Void
    var onRemoveSignature: (() -> Void)?
    let isRequired: Bool
    var onGetCaptionText: (() -> String?)?

    @State private var signatureURL: URL?

    public init(
        title: String,
        initialSignatureURL: URL?,
        onSignatureSelected: @escaping (URL?) -> Void,
        onRemoveSignature: (() -> Void)? = nil,
        isRequired: Bool,
        onGetCaptionText: (() -> String?)? = nil
    ) {
        self.title = title
        self.initialSignatureURL = initialSignatureURL
        self.onSignatureSelected = onSignatureSelected
        self.onRemoveSignature = onRemoveSignature
        self.isRequired = isRequired
        self.onGetCaptionText = onGetCaptionText
        self._signatureURL = State(initialValue: initialSignatureURL)
    }

    private var isValid: Bool {
        ChecklistValidator.validateSignature(signatureURL, isRequired: isRequired)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired && !isValid
            )

            SignatureCanvasView(
                signatureURL: signatureURL,
                onSignatureSelected: { url in
                    signatureURL = url
                    onSignatureSelected(url)
                },
                onRemoveSignature: {
                    signatureURL = nil
                    onRemoveSignature?()
                },
                onGetCaptionText: onGetCaptionText
            )
            .padding(.top, ChecklistItemConstants.innerTopPadding)
        }
        .padding(ChecklistItemConstants.itemPadding)
        .onChange(of: initialSignatureURL) { newValue in
            signatureURL = newValue
        }
    }
}

