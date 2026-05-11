import SwiftUI
import UIKit

/// Image checklist item for photo/gallery upload matching Figma design specifications.
/// Composes ChecklistHeader + ImagePickerView.
/// Mirrors Android's `ImageCheckListItem` composable.
public struct ImageCheckListItem: View {
    let title: String
    let initialImageURLs: [URL]
    let onImageListChanged: ([URL]) -> Void
    let isRequired: Bool
    let allowMultiple: Bool
    let imageSourceType: ImageSourceType
    var onGetCaptionText: (() -> String?)?
    var processingConfig: PODImageProcessingConfig?
    var captureDataProvider: (() -> PODCaptureData)?
    var podDelegate: (any PODImageProcessingDelegate)?

    @State private var imageURLs: [URL]
    @State private var pipeline: PODImagePipeline?
    @State private var validationState: ValidationState?
    @State private var cropContinuation: CheckedContinuation<UIImage?, Never>?
    @State private var showCropSheet = false
    @State private var pendingCropImage: UIImage?

    public init(
        title: String,
        initialImageURLs: [URL],
        onImageListChanged: @escaping ([URL]) -> Void,
        isRequired: Bool,
        allowMultiple: Bool,
        imageSourceType: ImageSourceType,
        onGetCaptionText: (() -> String?)? = nil,
        processingConfig: PODImageProcessingConfig? = nil,
        captureDataProvider: (() -> PODCaptureData)? = nil,
        podDelegate: (any PODImageProcessingDelegate)? = nil
    ) {
        self.title = title
        self.initialImageURLs = initialImageURLs
        self.onImageListChanged = onImageListChanged
        self.isRequired = isRequired
        self.allowMultiple = allowMultiple
        self.imageSourceType = imageSourceType
        self.onGetCaptionText = onGetCaptionText
        self.processingConfig = processingConfig
        self.captureDataProvider = captureDataProvider
        self.podDelegate = podDelegate
        self._imageURLs = State(initialValue: initialImageURLs)
    }

    private var isValid: Bool {
        ChecklistValidator.validateImage(imageURLs, isRequired: isRequired)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired && !isValid
            )

            ImagePickerView(
                imageURLs: imageURLs,
                onImageSelected: { url in
                    guard let url = url else { return }
                    handleSelectedImage(at: url)
                },
                onRemoveImage: { index in
                    var newURLs = imageURLs
                    if newURLs.count == 1 {
                        newURLs = []
                    } else {
                        newURLs.remove(at: index)
                    }
                    imageURLs = newURLs
                    onImageListChanged(newURLs)
                },
                allowMultiple: allowMultiple,
                imageSourceType: imageSourceType,
                onGetCaptionText: onGetCaptionText
            )
            .padding(.top, ChecklistItemConstants.innerTopPadding)
        }
        .padding(ChecklistItemConstants.itemPadding)
        .onChange(of: initialImageURLs) { newValue in
            imageURLs = newValue
        }
        .sheet(isPresented: $showCropSheet) {
            if let img = pendingCropImage {
                CropImageView(
                    image: img,
                    onConfirm: { cropped in
                        cropContinuation?.resume(returning: cropped)
                        cropContinuation = nil
                        showCropSheet = false
                        pendingCropImage = nil
                    },
                    onCancel: {
                        cropContinuation?.resume(returning: nil)
                        cropContinuation = nil
                        showCropSheet = false
                        pendingCropImage = nil
                    }
                )
            }
        }
        .sheet(item: $validationState) { state in
            let action = CallbackValidationAction()
            action.onRetry = {
                validationState = nil
                runPipeline(on: state.image)
            }
            action.onContinueAnyway = {
                validationState = nil
                appendProcessedURL(state.metadata.savedURL)
            }
            return PODValidationView(
                errorMessage: errorMessage(for: state.errorType),
                action: action
            )
        }
    }

    // MARK: - Pipeline integration

    private func handleSelectedImage(at url: URL) {
        guard processingConfig != nil,
              captureDataProvider != nil,
              let image = loadImage(from: url) else {
            let newURLs = allowMultiple ? imageURLs + [url] : [url]
            imageURLs = newURLs
            onImageListChanged(newURLs)
            return
        }
        runPipeline(on: image)
    }

    private func runPipeline(on image: UIImage) {
        guard let config = processingConfig,
              let captureDataProvider = captureDataProvider else { return }
        let captureData = captureDataProvider()
        let p = PODImagePipeline(
            itemType: .photo,
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
            appendProcessedURL(url)
        }
        pipeline = p
        p.execute(image: image) { image, continuation in
            pendingCropImage = image
            cropContinuation = continuation
            showCropSheet = true
        }
    }

    private func appendProcessedURL(_ url: URL?) {
        guard let url = url else { return }
        let newURLs = allowMultiple ? imageURLs + [url] : [url]
        imageURLs = newURLs
        onImageListChanged(newURLs)
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

/// Closure-backed `PODValidationAction` used by checklist items to wire
/// retry / continue-anyway from the validation sheet back to local state.
internal final class CallbackValidationAction: PODValidationAction {
    var onRetry: () -> Void = {}
    var onContinueAnyway: () -> Void = {}

    func retry() { onRetry() }
    func continueAnyway() { onContinueAnyway() }
}
