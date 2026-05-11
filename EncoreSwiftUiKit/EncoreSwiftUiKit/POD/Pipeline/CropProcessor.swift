import UIKit

internal final class CropProcessor: ImageProcessor {
    let presentCrop: (UIImage, CheckedContinuation<UIImage?, Never>) -> Void

    init(presentCrop: @escaping (UIImage, CheckedContinuation<UIImage?, Never>) -> Void) {
        self.presentCrop = presentCrop
    }

    func process(
        image: UIImage,
        config: PODImageProcessingConfig,
        context: PODCaptureData,
        metadata: ProcessingMetadata
    ) async throws -> ProcessingStepResult {
        guard config.cropEnabled else {
            return .success(image, metadata)
        }

        let cropped: UIImage? = await withCheckedContinuation { continuation in
            presentCrop(image, continuation)
        }

        return .success(cropped ?? image, metadata)
    }
}
