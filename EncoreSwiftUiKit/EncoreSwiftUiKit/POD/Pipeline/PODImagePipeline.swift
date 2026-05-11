import UIKit

final class PODImagePipeline {
    private let itemType: ChecklistItemType
    private let config: PODImageProcessingConfig
    private let captureData: PODCaptureData
    weak var delegate: (any PODImageProcessingDelegate)?
    var onValidationError: ((ValidationErrorType, UIImage, ProcessingMetadata) -> Void)?
    var onComplete: ((URL) -> Void)?

    init(itemType: ChecklistItemType, config: PODImageProcessingConfig, captureData: PODCaptureData) {
        self.itemType = itemType
        self.config = config
        self.captureData = captureData
    }

    func execute(
        image: UIImage,
        presentCrop: @escaping (UIImage, CheckedContinuation<UIImage?, Never>) -> Void
    ) {
        Task {
            do {
                let (processors, effectiveConfig) = buildProcessors(presentCrop: presentCrop)
                var currentImage = image
                var metadata = ProcessingMetadata()
                for processor in processors {
                    let result = try await processor.process(
                        image: currentImage,
                        config: effectiveConfig,
                        context: captureData,
                        metadata: metadata
                    )
                    switch result {
                    case let .success(img, meta):
                        currentImage = img
                        metadata = meta
                    case let .validationError(errorType, img, meta):
                        let errType = errorType
                        let errImg = img
                        let errMeta = meta
                        await MainActor.run {
                            onValidationError?(errType, errImg, errMeta)
                        }
                        return
                    }
                }
                if let url = metadata.savedURL {
                    let itemId = captureData.itemId
                    await MainActor.run {
                        delegate?.podPipeline(didCompleteWithURL: url, itemId: itemId)
                        onComplete?(url)
                    }
                }
            } catch {
                let err = error
                let itemId = captureData.itemId
                await MainActor.run {
                    delegate?.podPipeline(didFailWithError: err, itemId: itemId)
                }
            }
        }
    }

    private func buildProcessors(
        presentCrop: @escaping (UIImage, CheckedContinuation<UIImage?, Never>) -> Void
    ) -> (processors: [any ImageProcessor], effectiveConfig: PODImageProcessingConfig) {
        switch itemType {
        case .signature:
            var signatureConfig = config
            signatureConfig.quality = .low
            signatureConfig.scaleDownEnabled = true
            var list: [any ImageProcessor] = [ScaleDownProcessor()]
            if signatureConfig.exifEnabled { list.append(ExifProcessor()) }
            return (list, signatureConfig)
        default:
            var list: [any ImageProcessor] = []
            if config.cropEnabled { list.append(CropProcessor(presentCrop: presentCrop)) }
            if config.blurDetectionEnabled { list.append(BlurDetectionProcessor()) }
            if config.textExtractionEnabled { list.append(TextExtractionProcessor()) }
            if config.scaleDownEnabled { list.append(ScaleDownProcessor()) }
            if config.captionEnabled { list.append(CaptionProcessor()) }
            list.append(ExifProcessor())
            return (list, config)
        }
    }
}
