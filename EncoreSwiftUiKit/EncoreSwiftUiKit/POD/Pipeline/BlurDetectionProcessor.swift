import UIKit

internal final class BlurDetectionProcessor: ImageProcessor {
    private static let blurThreshold: Double = 100.0
    private static let downsampleWidth: CGFloat = 500

    func process(
        image: UIImage,
        config: PODImageProcessingConfig,
        context: PODCaptureData,
        metadata: ProcessingMetadata
    ) async throws -> ProcessingStepResult {
        guard config.blurDetectionEnabled else { return .success(image, metadata) }

        let variance = computeLaplacianVariance(image)
        if variance < Self.blurThreshold {
            var updated = metadata
            updated.blurDetected = true
            return .validationError(.blurDetected, image, updated)
        }
        return .success(image, metadata)
    }

    private func computeLaplacianVariance(_ image: UIImage) -> Double {
        // Downsample to ~500px wide (matches Android DOWNSAMPLE_WIDTH = 500)
        let aspectRatio = image.size.height / image.size.width
        let targetWidth = Self.downsampleWidth
        let targetHeight = max(1, (targetWidth * aspectRatio).rounded())
        let targetSize = CGSize(width: targetWidth, height: targetHeight)

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1.0
        let scaled = UIGraphicsImageRenderer(size: targetSize, format: fmt).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let cgImage = scaled.cgImage else { return 0 }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 2, height > 2 else { return 0 }

        // Render into a known RGBA8 layout with no row padding
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        guard let ctx = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 0 }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Grayscale conversion (matches Android: 0.299R + 0.587G + 0.114B)
        var gray = [Double](repeating: 0, count: width * height)
        for i in 0..<(width * height) {
            gray[i] = 0.299 * Double(pixelData[i * 4])
                    + 0.587 * Double(pixelData[i * 4 + 1])
                    + 0.114 * Double(pixelData[i * 4 + 2])
        }

        // Laplacian variance — unclamped doubles, border pixels skipped
        var sum = 0.0
        var sumSq = 0.0
        var count = 0
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let lap = gray[(y - 1) * width + x]
                       + gray[(y + 1) * width + x]
                       + gray[y * width + (x - 1)]
                       + gray[y * width + (x + 1)]
                       - 4.0 * gray[y * width + x]
                sum   += lap
                sumSq += lap * lap
                count += 1
            }
        }
        guard count > 0 else { return 0 }
        let mean = sum / Double(count)
        return sumSq / Double(count) - mean * mean
    }
}
