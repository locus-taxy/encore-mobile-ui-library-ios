import SwiftUI
import UIKit

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
    var processingConfig: PODImageProcessingConfig?
    var captureDataProvider: (() -> PODCaptureData)?
    var podDelegate: (any PODImageProcessingDelegate)?

    @State private var signatureURL: URL?
    @State private var pipeline: PODImagePipeline?
    @State private var validationState: ValidationState?

    public init(
        title: String,
        initialSignatureURL: URL?,
        onSignatureSelected: @escaping (URL?) -> Void,
        onRemoveSignature: (() -> Void)? = nil,
        isRequired: Bool,
        onGetCaptionText: (() -> String?)? = nil,
        processingConfig: PODImageProcessingConfig? = nil,
        captureDataProvider: (() -> PODCaptureData)? = nil,
        podDelegate: (any PODImageProcessingDelegate)? = nil
    ) {
        self.title = title
        self.initialSignatureURL = initialSignatureURL
        self.onSignatureSelected = onSignatureSelected
        self.onRemoveSignature = onRemoveSignature
        self.isRequired = isRequired
        self.onGetCaptionText = onGetCaptionText
        self.processingConfig = processingConfig
        self.captureDataProvider = captureDataProvider
        self.podDelegate = podDelegate
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
                    handleSavedSignature(url)
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
        .sheet(item: $validationState) { state in
            let action = CallbackValidationAction()
            action.onRetry = {
                validationState = nil
                runPipeline(on: state.image)
            }
            action.onContinueAnyway = {
                validationState = nil
                deliverProcessedURL(state.metadata.savedURL)
            }
            return PODValidationView(
                errorMessage: errorMessage(for: state.errorType),
                action: action
            )
        }
    }

    // MARK: - Pipeline integration

    private func handleSavedSignature(_ url: URL?) {
        guard let url = url else {
            signatureURL = nil
            onSignatureSelected(nil)
            return
        }
        guard processingConfig != nil,
              captureDataProvider != nil,
              let image = loadImage(from: url) else {
            signatureURL = url
            onSignatureSelected(url)
            return
        }
        runPipeline(on: image)
    }

    private func runPipeline(on image: UIImage) {
        guard let config = processingConfig,
              let captureDataProvider = captureDataProvider else { return }
        let captureData = captureDataProvider()
        let p = PODImagePipeline(
            itemType: .signature,
            config: config,
            captureData: captureData
        )
        p.delegate = podDelegate
        p.onValidationError = { errorType, image, metadata in
            validationState = ValidationState(
                errorType: errorType,
                image: image,
                metadata: metadata
            )
        }
        p.onComplete = { url in
            deliverProcessedURL(url)
        }
        pipeline = p
        // Signatures do not require a crop step — the pipeline's
        // buildProcessors skips CropProcessor for `.signature`.
        p.execute(image: image) { _, continuation in
            continuation.resume(returning: nil)
        }
    }

    private func deliverProcessedURL(_ url: URL?) {
        guard let url = url else { return }
        signatureURL = url
        onSignatureSelected(url)
    }

    private func loadImage(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func errorMessage(for errorType: ValidationErrorType) -> String {
        switch errorType {
        case .blurDetected:
            return "Image appears blurry. Please retake or continue anyway."
        case let .textMismatch(missing):
            return "Required text not found: \(missing.joined(separator: ", ")). Please retake or continue."
        }
    }

    // MARK: - Nested types

    private struct ValidationState: Identifiable {
        let id = UUID()
        let errorType: ValidationErrorType
        let image: UIImage
        let metadata: ProcessingMetadata
    }
}
