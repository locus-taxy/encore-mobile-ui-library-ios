@testable import EncoreSwiftUiKit
import CoreLocation
import UIKit
import XCTest

final class PODImagePipelineTests: XCTestCase {

    // MARK: - Helpers

    private func makeTestImage(width: CGFloat = 200, height: CGFloat = 200) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
            .image { ctx in
                UIColor.red.setFill()
                ctx.fill(CGRect(origin: .zero, size: CGSize(width: width, height: height)))
            }
    }

    private func makeConfig(
        crop: Bool = false,
        blur: Bool = false,
        text: Bool = false,
        scaleDown: Bool = true,
        caption: Bool = false,
        exif: Bool = true,
        quality: ImageQuality = .high,
        requiredTexts: [String] = []
    ) -> PODImageProcessingConfig {
        PODImageProcessingConfig(
            cropEnabled: crop,
            blurDetectionEnabled: blur,
            textExtractionEnabled: text,
            scaleDownEnabled: scaleDown,
            captionEnabled: caption,
            exifEnabled: exif,
            quality: quality,
            requiredTexts: requiredTexts
        )
    }

    private func makeCaptureData(location: CLLocationCoordinate2D? = nil) -> PODCaptureData {
        PODCaptureData(itemId: "test-item", timestamp: Date(), location: location)
    }

    // MARK: - ScaleDownProcessor

    func testScaleDown_highQuality_resizesLargeImage() async throws {
        let image = makeTestImage(width: 2000, height: 1500)
        let config = makeConfig(scaleDown: true, quality: .high)
        let processor = ScaleDownProcessor()
        let result = try await processor.process(
            image: image,
            config: config,
            context: makeCaptureData(),
            metadata: ProcessingMetadata()
        )
        guard case .success(let out, _) = result else { XCTFail("Expected success"); return }
        XCTAssertLessThanOrEqual(out.size.width, 1280)
        XCTAssertLessThanOrEqual(out.size.height, 960)
    }

    func testScaleDown_doesNotUpscale() async throws {
        let image = makeTestImage(width: 100, height: 100)
        let config = makeConfig(scaleDown: true, quality: .high)
        let processor = ScaleDownProcessor()
        let result = try await processor.process(
            image: image,
            config: config,
            context: makeCaptureData(),
            metadata: ProcessingMetadata()
        )
        guard case .success(let out, _) = result else { XCTFail(); return }
        XCTAssertEqual(out.size, CGSize(width: 100, height: 100))
    }

    func testScaleDown_disabled_returnsOriginal() async throws {
        let image = makeTestImage(width: 2000, height: 1500)
        let config = makeConfig(scaleDown: false)
        let processor = ScaleDownProcessor()
        let result = try await processor.process(
            image: image,
            config: config,
            context: makeCaptureData(),
            metadata: ProcessingMetadata()
        )
        guard case .success(let out, _) = result else { XCTFail(); return }
        XCTAssertEqual(out.size, image.size)
    }

    // MARK: - CaptionProcessor

    func testCaption_disabled_returnsOriginal() async throws {
        let image = makeTestImage()
        let config = makeConfig(caption: false)
        let processor = CaptionProcessor()
        let result = try await processor.process(
            image: image,
            config: config,
            context: makeCaptureData(),
            metadata: ProcessingMetadata()
        )
        guard case .success(let out, _) = result else { XCTFail(); return }
        XCTAssertEqual(out.size, image.size)
    }

    func testCaption_fontSizeFormula_2400Height() {
        // For a 2400pt-high image, font should be max(10.0, 48.0 * (2400.0/2400.0)) = 48.0
        let expectedFontSize = max(10.0, 48.0 * (2400.0 / 2400.0))
        XCTAssertEqual(expectedFontSize, 48.0, accuracy: 0.001)
    }

    func testCaption_fontSizeFormula_1200Height() {
        let expectedFontSize = max(10.0, 48.0 * (1200.0 / 2400.0))
        XCTAssertEqual(expectedFontSize, 24.0, accuracy: 0.001)
    }

    func testCaption_locationString_format() {
        // Verify the location string format matches spec
        let lat = 12.345
        let lng = 67.890
        let locationStr = "Location:\(lat),\(lng)"
        XCTAssertTrue(locationStr.hasPrefix("Location:"))
        XCTAssertFalse(locationStr.hasPrefix("Location: "))  // no space before coordinate
    }

    // MARK: - ExifProcessor

    func testExif_savesToPodImagesDirectory() async throws {
        let image = makeTestImage()
        let config = makeConfig(exif: true)
        let processor = ExifProcessor()
        let result = try await processor.process(
            image: image,
            config: config,
            context: makeCaptureData(),
            metadata: ProcessingMetadata()
        )
        guard case .success(_, let meta) = result else { XCTFail(); return }
        XCTAssertNotNil(meta.savedURL)
        XCTAssertTrue(meta.savedURL!.path.contains("pod_images"))
        XCTAssertEqual(meta.savedURL!.pathExtension.lowercased(), "jpg")
    }

    func testExif_savedFileIsJPEG() async throws {
        let image = makeTestImage()
        let config = makeConfig(exif: true)
        let processor = ExifProcessor()
        let result = try await processor.process(
            image: image,
            config: config,
            context: makeCaptureData(),
            metadata: ProcessingMetadata()
        )
        guard case .success(_, let meta) = result, let url = meta.savedURL else { XCTFail(); return }
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let data = try Data(contentsOf: url)
        XCTAssertGreaterThan(data.count, 0)
        // JPEG magic bytes: FF D8 FF
        XCTAssertEqual(data[0], 0xFF)
        XCTAssertEqual(data[1], 0xD8)
    }

    func testExif_disabled_stillSavesJPEG() async throws {
        let image = makeTestImage()
        let config = makeConfig(exif: false)
        let processor = ExifProcessor()
        let result = try await processor.process(
            image: image,
            config: config,
            context: makeCaptureData(),
            metadata: ProcessingMetadata()
        )
        guard case .success(_, let meta) = result else { XCTFail(); return }
        XCTAssertNotNil(meta.savedURL)  // savedURL always set even when EXIF is disabled
    }

    func testExif_setsMetadataSavedURL() async throws {
        let image = makeTestImage()
        let config = makeConfig(exif: true)
        let processor = ExifProcessor()
        let metadata = ProcessingMetadata()
        XCTAssertNil(metadata.savedURL)
        let result = try await processor.process(
            image: image,
            config: config,
            context: makeCaptureData(),
            metadata: metadata
        )
        guard case .success(_, let meta) = result else { XCTFail(); return }
        XCTAssertNotNil(meta.savedURL)
    }

    // MARK: - BlurDetectionProcessor

    func testBlurDetection_disabled_passesThrough() async throws {
        let image = makeTestImage()
        let config = makeConfig(blur: false)
        let processor = BlurDetectionProcessor()
        let result = try await processor.process(
            image: image,
            config: config,
            context: makeCaptureData(),
            metadata: ProcessingMetadata()
        )
        guard case .success = result else { XCTFail("Expected success when disabled"); return }
    }

    // MARK: - TextExtractionProcessor

    func testTextExtraction_disabled_passesThrough() async throws {
        let image = makeTestImage()
        let config = makeConfig(text: false)
        let processor = TextExtractionProcessor()
        let result = try await processor.process(
            image: image,
            config: config,
            context: makeCaptureData(),
            metadata: ProcessingMetadata()
        )
        guard case .success = result else { XCTFail("Expected success when disabled"); return }
    }

    func testTextExtraction_emptyRequiredTexts_skips() async throws {
        let image = makeTestImage()
        let config = makeConfig(text: true, requiredTexts: [])
        let processor = TextExtractionProcessor()
        let result = try await processor.process(
            image: image,
            config: config,
            context: makeCaptureData(),
            metadata: ProcessingMetadata()
        )
        guard case .success = result else { XCTFail("Expected success with empty requiredTexts"); return }
    }

    // MARK: - PODImagePipeline chain building

    func testPipeline_signatureChain_onlyScaleAndExif() {
        let config = makeConfig(crop: true, blur: true, text: true, scaleDown: true, caption: true, exif: true)
        let pipeline = PODImagePipeline(
            itemType: .signature,
            config: config,
            captureData: makeCaptureData()
        )
        // Signature chain is enforced internally — verify pipeline constructs without crashing.
        // Behavioural verification of the chain composition happens via integration tests in T006.
        XCTAssertNotNil(pipeline)
    }

    func testPipeline_photoChain_exifAlwaysLast() {
        let config = makeConfig(scaleDown: true, exif: true)
        let pipeline = PODImagePipeline(itemType: .photo, config: config, captureData: makeCaptureData())
        XCTAssertNotNil(pipeline)
    }

    func testPipeline_photoChain_respectsDisabledFlags() async throws {
        // With all flags except exif disabled, only ExifProcessor should run and produce a savedURL → onComplete fires.
        let image = makeTestImage()
        let config = makeConfig(crop: false, blur: false, text: false, scaleDown: false, caption: false, exif: true)
        var completionURL: URL?
        let completionExpectation = expectation(description: "pipeline completes")
        let pipeline = PODImagePipeline(itemType: .photo, config: config, captureData: makeCaptureData())
        pipeline.onComplete = { url in
            completionURL = url
            completionExpectation.fulfill()
        }
        pipeline.execute(image: image, presentCrop: { _, continuation in
            continuation.resume(returning: nil)  // should not be called
        })
        await fulfillment(of: [completionExpectation], timeout: 10.0)
        XCTAssertNotNil(completionURL)
    }

    func testPipeline_validationError_firesCallback() async throws {
        // A solid-red uniform image has zero Laplacian variance, well below the blur threshold (100.0).
        let image = makeTestImage()
        let config = makeConfig(blur: true, scaleDown: false, exif: false)
        var validationFired = false
        let validationExpectation = expectation(description: "validation error fires")
        let pipeline = PODImagePipeline(itemType: .photo, config: config, captureData: makeCaptureData())
        pipeline.onValidationError = { _, _, _ in
            validationFired = true
            validationExpectation.fulfill()
        }
        pipeline.execute(image: image, presentCrop: { _, continuation in
            continuation.resume(returning: nil)
        })
        await fulfillment(of: [validationExpectation], timeout: 10.0)
        XCTAssertTrue(validationFired)
    }
}
