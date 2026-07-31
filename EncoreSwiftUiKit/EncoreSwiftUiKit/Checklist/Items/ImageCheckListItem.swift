import SwiftUI
import UIKit

/// Image checklist item for photo/gallery upload matching Figma design specifications.
/// Composes ChecklistHeader + ImagePickerView.
/// Mirrors Android's `ImageCheckListItem` composable.
public struct ImageCheckListItem: View {
    let title: String
    var helperText: String? = nil
    var itemIndex: Int? = nil
    var totalItems: Int? = nil
    var isCompleted: Bool = false
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
    @State private var activeSheet: ActiveSheet?

    private enum ActiveSheet: Identifiable {
        case crop(UIImage, CheckedContinuation<UIImage?, Never>)
        case validation(ValidationState)
        var id: String {
            switch self {
            case .crop: return "crop"
            case .validation: return "validation"
            }
        }
    }

    public init(
        title: String,
        helperText: String? = nil,
        itemIndex: Int? = nil,
        totalItems: Int? = nil,
        isCompleted: Bool = false,
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
        self.helperText = helperText
        self.itemIndex = itemIndex
        self.totalItems = totalItems
        self.isCompleted = isCompleted
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
                isRequired: isRequired && !isValid,
                helperText: helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: isCompleted
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
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case let .crop(img, continuation):
                CropImageView(
                    image: img,
                    onConfirm: { cropped in
                        continuation.resume(returning: cropped)
                        activeSheet = nil
                    },
                    onCancel: {
                        continuation.resume(returning: nil)
                        activeSheet = nil
                    }
                )
            case let .validation(state):
                PODValidationView(
                    errorMessage: errorMessage(for: state.errorType),
                    action: {
                        let action = CallbackValidationAction()
                        action.onRetry = { activeSheet = nil }
                        action.onContinueAnyway = {
                            activeSheet = nil
                            pipeline?.resume(image: state.image, metadata: state.metadata)
                        }
                        return action
                    }()
                )
            }
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
            activeSheet = .validation(ValidationState(
                errorType: errorType,
                image: image,
                metadata: metadata
            ))
        }
        p.onComplete = { url in
            appendProcessedURL(url)
        }
        pipeline = p
        p.execute(image: image) { rawImage, continuation in
            let decoded = rawImage.preparingForDisplay() ?? rawImage
            DispatchQueue.main.async {
                activeSheet = .crop(decoded, continuation)
            }
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
