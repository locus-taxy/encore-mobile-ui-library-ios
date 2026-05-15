import CoreGraphics
import Foundation

public enum ImageQuality {
    case high   // 2400 × 1800
    case medium // 1600 × 1200
    case low    //  816 ×  612

    var targetSize: CGSize {
        switch self {
        case .high:   return CGSize(width: 2400, height: 1800)
        case .medium: return CGSize(width: 1600, height: 1200)
        case .low:    return CGSize(width: 816,  height: 612)
        }
    }
}

public struct PODImageProcessingConfig {
    public var cropEnabled: Bool
    public var blurDetectionEnabled: Bool
    public var textExtractionEnabled: Bool
    public var scaleDownEnabled: Bool
    public var captionEnabled: Bool
    public var exifEnabled: Bool
    public var quality: ImageQuality
    public var requiredTexts: [String]

    public init(
        cropEnabled: Bool = false,
        blurDetectionEnabled: Bool = false,
        textExtractionEnabled: Bool = false,
        scaleDownEnabled: Bool = false,
        captionEnabled: Bool = false,
        exifEnabled: Bool = false,
        quality: ImageQuality = .high,
        requiredTexts: [String] = []
    ) {
        self.cropEnabled = cropEnabled
        self.blurDetectionEnabled = blurDetectionEnabled
        self.textExtractionEnabled = textExtractionEnabled
        self.scaleDownEnabled = scaleDownEnabled
        self.captionEnabled = captionEnabled
        self.exifEnabled = exifEnabled
        self.quality = quality
        self.requiredTexts = requiredTexts
    }
}
