import UIKit

internal final class ScaleDownProcessor: ImageProcessor {
    func process(
        image: UIImage,
        config: PODImageProcessingConfig,
        context: PODCaptureData,
        metadata: ProcessingMetadata
    ) async throws -> ProcessingStepResult {
        guard config.scaleDownEnabled else { return .success(image, metadata) }

        var targetSize = config.quality.targetSize
        if image.size.height > image.size.width {
            targetSize = CGSize(width: targetSize.height, height: targetSize.width)
        }

        guard image.size.width > targetSize.width || image.size.height > targetSize.height else {
            return .success(image, metadata)
        }

        let widthRatio = targetSize.width / image.size.width
        let heightRatio = targetSize.height / image.size.height
        let scale = min(widthRatio, heightRatio)
        let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
        return .success(scaled, metadata)
    }
}
