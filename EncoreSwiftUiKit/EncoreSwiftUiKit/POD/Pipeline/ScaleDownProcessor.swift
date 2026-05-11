import UIKit

internal final class ScaleDownProcessor: ImageProcessor {
    func process(
        image: UIImage,
        config: PODImageProcessingConfig,
        context: PODCaptureData,
        metadata: ProcessingMetadata
    ) async throws -> ProcessingStepResult {
        fatalError("not implemented")
    }
}
