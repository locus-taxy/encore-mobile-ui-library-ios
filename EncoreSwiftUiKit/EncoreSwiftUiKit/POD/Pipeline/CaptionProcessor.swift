import CoreLocation
import UIKit

internal final class CaptionProcessor: ImageProcessor {
    func process(
        image: UIImage,
        config: PODImageProcessingConfig,
        context: PODCaptureData,
        metadata: ProcessingMetadata
    ) async throws -> ProcessingStepResult {
        guard config.captionEnabled else { return .success(image, metadata) }

        let fontSize = max(10.0, 48.0 * (image.size.height / 2400.0))
        let font = UIFont.boldSystemFont(ofSize: fontSize)

        let df = DateFormatter()
        df.dateFormat = "hh:mm a zzz, dd-MMM-yyyy"
        df.locale = Locale(identifier: "en_US")
        let dateStr = df.string(from: context.timestamp)

        let locationStr: String
        if let coord = context.location {
            locationStr = "Location:\(coord.latitude),\(coord.longitude)"
        } else {
            locationStr = "Location: Unknown"
        }

        let captionText = [dateStr, locationStr].joined(separator: "\n")

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        let attrStr = NSAttributedString(string: captionText, attributes: attrs)
        let textSize = attrStr.size()

        let padding: CGFloat = max(4.0, fontSize * 0.25)
        let bgRect = CGRect(
            x: 0,
            y: image.size.height - textSize.height - padding * 2,
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )

        let renderer = UIGraphicsImageRenderer(size: image.size)
        let captioned = renderer.image { ctx in
            image.draw(at: .zero)
            UIColor.black.withAlphaComponent(0.5).setFill()
            ctx.fill(bgRect)
            attrStr.draw(at: CGPoint(x: bgRect.origin.x + padding, y: bgRect.origin.y + padding))
        }
        return .success(captioned, metadata)
    }
}
