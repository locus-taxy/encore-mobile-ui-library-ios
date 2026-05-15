import Foundation

internal struct ProcessingMetadata {
    var blurDetected: Bool = false
    var extractedTexts: [String] = []
    var savedURL: URL? = nil
}
