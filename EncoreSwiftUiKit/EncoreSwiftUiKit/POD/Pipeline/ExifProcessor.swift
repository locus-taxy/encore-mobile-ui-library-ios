import CoreLocation
import ImageIO
import UIKit

internal final class ExifProcessor: ImageProcessor {
    func process(
        image: UIImage,
        config: PODImageProcessingConfig,
        context: PODCaptureData,
        metadata: ProcessingMetadata
    ) async throws -> ProcessingStepResult {
        let data = NSMutableData()
        let jpegUTI = "public.jpeg" as CFString
        guard let dest = CGImageDestinationCreateWithData(data, jpegUTI, 1, nil),
              let cgImage = image.cgImage else {
            throw PODProcessorError.exportFailed
        }

        var props: [String: Any] = [
            kCGImageDestinationLossyCompressionQuality as String: 0.9
        ]
        if config.exifEnabled, let coord = context.location {
            props[kCGImagePropertyGPSDictionary as String] = makeGPSDictionary(coord: coord, timestamp: context.timestamp)
        }
        CGImageDestinationAddImage(dest, cgImage, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw PODProcessorError.exportFailed
        }

        let podDir = FileManager.default.temporaryDirectory.appendingPathComponent("pod_images")
        try FileManager.default.createDirectory(at: podDir, withIntermediateDirectories: true)
        let fileURL = podDir.appendingPathComponent("\(UUID().uuidString).jpg")
        try (data as Data).write(to: fileURL)

        var updated = metadata
        updated.savedURL = fileURL
        return .success(image, updated)
    }

    private func makeGPSDictionary(coord: CLLocationCoordinate2D, timestamp: Date) -> [String: Any] {
        let latRef = coord.latitude >= 0 ? "N" : "S"
        let lngRef = coord.longitude >= 0 ? "E" : "W"
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        df.timeZone = TimeZone(identifier: "UTC")
        let timePart = df.string(from: timestamp)
        df.dateFormat = "yyyy:MM:dd"
        let datePart = df.string(from: timestamp)
        return [
            kCGImagePropertyGPSLatitude as String: abs(coord.latitude),
            kCGImagePropertyGPSLatitudeRef as String: latRef,
            kCGImagePropertyGPSLongitude as String: abs(coord.longitude),
            kCGImagePropertyGPSLongitudeRef as String: lngRef,
            kCGImagePropertyGPSTimeStamp as String: timePart,
            kCGImagePropertyGPSDateStamp as String: datePart
        ]
    }
}
