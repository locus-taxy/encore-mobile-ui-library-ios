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
                        await MainActor.run {
                            onValidationError?(errorType, img, meta)
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
                let itemId = captureData.itemId
                await MainActor.run {
                    delegate?.podPipeline(didFailWithError: error, itemId: itemId)
                }
            }
        }
    }

    func resume(image: UIImage, metadata: ProcessingMetadata) {
        Task {
            do {
                var currentImage = image
                var currentMetadata = metadata
                for processor in buildPostValidationProcessors() {
                    let result = try await processor.process(
                        image: currentImage,
                        config: config,
                        context: captureData,
                        metadata: currentMetadata
                    )
                    switch result {
                    case let .success(img, meta):
                        currentImage = img
                        currentMetadata = meta
                    case let .validationError(_, img, meta):
                        currentImage = img
                        currentMetadata = meta
                    }
                }
                if let url = currentMetadata.savedURL {
                    let itemId = captureData.itemId
                    await MainActor.run {
                        delegate?.podPipeline(didCompleteWithURL: url, itemId: itemId)
                        onComplete?(url)
                    }
                }
            } catch {
                let itemId = captureData.itemId
                await MainActor.run {
                    delegate?.podPipeline(didFailWithError: error, itemId: itemId)
                }
            }
        }
    }

    private func buildPostValidationProcessors() -> [any ImageProcessor] {
        var list: [any ImageProcessor] = []
        if config.scaleDownEnabled { list.append(ScaleDownProcessor()) }
        if config.captionEnabled { list.append(CaptionProcessor()) }
        list.append(ExifProcessor())
        return list
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
