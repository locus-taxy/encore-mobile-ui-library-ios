import UIKit
import Vision

internal final class TextExtractionProcessor: ImageProcessor {
    func process(
        image: UIImage,
        config: PODImageProcessingConfig,
        context: PODCaptureData,
        metadata: ProcessingMetadata
    ) async throws -> ProcessingStepResult {
        guard config.textExtractionEnabled, !config.requiredTexts.isEmpty else {
            return .success(image, metadata)
        }
        guard let cgImage = image.cgImage else { return .success(image, metadata) }

        var recognizedStrings: [String] = []
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else { return }
            for obs in observations {
                if let top = obs.topCandidates(1).first {
                    recognizedStrings.append(top.string)
                }
            }
        }
        request.recognitionLevel = .accurate
        request.minimumTextHeight = 0.0

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        var updated = metadata
        updated.extractedTexts = recognizedStrings

        let missing = config.requiredTexts.filter { required in
            !recognizedStrings.contains { $0.localizedCaseInsensitiveContains(required) }
        }
        if !missing.isEmpty {
            return .validationError(.textMismatch(missingTexts: missing), image, updated)
        }
        return .success(image, updated)
    }
}
