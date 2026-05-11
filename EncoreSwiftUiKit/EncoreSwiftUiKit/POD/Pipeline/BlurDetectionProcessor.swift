import Accelerate
import UIKit

internal final class BlurDetectionProcessor: ImageProcessor {
    private static let blurThreshold: Double = 100.0

    func process(
        image: UIImage,
        config: PODImageProcessingConfig,
        context: PODCaptureData,
        metadata: ProcessingMetadata
    ) async throws -> ProcessingStepResult {
        guard config.blurDetectionEnabled else { return .success(image, metadata) }

        guard let cgImage = image.cgImage else { return .success(image, metadata) }

        var sourceBuffer = vImage_Buffer()
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            colorSpace: Unmanaged.passUnretained(CGColorSpaceCreateDeviceGray()),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )
        guard vImageBuffer_InitWithCGImage(
            &sourceBuffer,
            &format,
            nil,
            cgImage,
            vImage_Flags(kvImageNoFlags)
        ) == kvImageNoError else {
            return .success(image, metadata)
        }
        defer { sourceBuffer.data.deallocate() }

        var destBuffer = vImage_Buffer()
        guard vImageBuffer_Init(
            &destBuffer,
            sourceBuffer.height,
            sourceBuffer.width,
            8,
            vImage_Flags(kvImageNoFlags)
        ) == kvImageNoError else {
            return .success(image, metadata)
        }
        defer { destBuffer.data.deallocate() }

        let kernel: [Int16] = [
            0,  1,  0,
            1, -4,  1,
            0,  1,  0
        ]
        let divisor: Int32 = 1
        let backgroundColor: Pixel_8 = 0
        guard vImageConvolve_Planar8(
            &sourceBuffer,
            &destBuffer,
            nil,
            0,
            0,
            kernel,
            3,
            3,
            divisor,
            backgroundColor,
            vImage_Flags(kvImageEdgeExtend)
        ) == kvImageNoError else {
            return .success(image, metadata)
        }

        let pixelCount = Int(destBuffer.width * destBuffer.height)
        guard pixelCount > 0 else { return .success(image, metadata) }
        let pixels = destBuffer.data.bindMemory(to: UInt8.self, capacity: pixelCount)
        var sum: Double = 0
        var sumSq: Double = 0
        for i in 0..<pixelCount {
            let v = Double(pixels[i])
            sum += v
            sumSq += v * v
        }
        let mean = sum / Double(pixelCount)
        let variance = sumSq / Double(pixelCount) - mean * mean

        if variance < Self.blurThreshold {
            var updated = metadata
            updated.blurDetected = true
            return .validationError(.blurDetected, image, updated)
        }
        return .success(image, metadata)
    }
}
