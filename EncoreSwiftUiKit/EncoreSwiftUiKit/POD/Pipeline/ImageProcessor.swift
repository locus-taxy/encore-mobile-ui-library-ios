import UIKit

internal protocol ImageProcessor {
    func process(
        image: UIImage,
        config: PODImageProcessingConfig,
        context: PODCaptureData,
        metadata: ProcessingMetadata
    ) async throws -> ProcessingStepResult
}
