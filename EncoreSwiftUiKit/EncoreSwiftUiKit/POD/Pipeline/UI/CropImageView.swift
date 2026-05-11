import SwiftUI
import UIKit

/// Full-screen interactive crop UI presented by the POD image pipeline.
/// The user can drag the crop rectangle's corners and edges to resize the
/// crop region, rotate the image 90° clockwise, and confirm or cancel the
/// crop. On confirm, the corresponding sub-region of the (possibly rotated)
/// source image is extracted and delivered via `onConfirm`.
internal struct CropImageView: View {
    let image: UIImage
    let onConfirm: (UIImage) -> Void
    let onCancel: () -> Void

    /// Normalized 0..1 crop rect within the displayed image bounds.
    @State private var cropRect: CGRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
    /// Rotation applied to the source image, in degrees. Always a multiple of 90.
    @State private var rotationAngle: CGFloat = 0
    /// Snapshot of `cropRect` at the start of the current drag. Drag gestures
    /// report cumulative translation, so we apply deltas against this base
    /// instead of the live `cropRect` to avoid compounding drift.
    @State private var dragBaseRect: CGRect? = nil

    private let handleSize: CGFloat = 24
    private let minCropFraction: CGFloat = 0.1

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    cropArea(in: geometry.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    controlBar
                }
            }
        }
    }

    // MARK: - Crop area

    private func cropArea(in containerSize: CGSize) -> some View {
        let rotated = rotatedImage()
        let displayRect = aspectFitRect(for: rotated.size, in: containerSize)

        return ZStack(alignment: .topLeading) {
            Image(uiImage: rotated)
                .resizable()
                .scaledToFit()
                .frame(width: containerSize.width, height: containerSize.height)

            cropOverlay(displayRect: displayRect)
        }
        .frame(width: containerSize.width, height: containerSize.height)
    }

    private func cropOverlay(displayRect: CGRect) -> some View {
        let pixelRect = CGRect(
            x: displayRect.minX + cropRect.minX * displayRect.width,
            y: displayRect.minY + cropRect.minY * displayRect.height,
            width: cropRect.width * displayRect.width,
            height: cropRect.height * displayRect.height
        )

        return ZStack(alignment: .topLeading) {
            // Dimmed area outside the crop rect.
            Color.black.opacity(0.5)
                .mask(
                    ZStack {
                        Rectangle().fill(Color.white)
                        Rectangle()
                            .frame(width: pixelRect.width, height: pixelRect.height)
                            .position(x: pixelRect.midX, y: pixelRect.midY)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                )
                .allowsHitTesting(false)

            // Crop rectangle border.
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: pixelRect.width, height: pixelRect.height)
                .position(x: pixelRect.midX, y: pixelRect.midY)
                .allowsHitTesting(false)

            // Drag gesture for the rectangle body (move).
            Color.clear
                .contentShape(Rectangle())
                .frame(width: max(0, pixelRect.width - handleSize),
                       height: max(0, pixelRect.height - handleSize))
                .position(x: pixelRect.midX, y: pixelRect.midY)
                .gesture(moveGesture(displayRect: displayRect))

            // Corner + edge handles.
            ForEach(Handle.allCases, id: \.self) { handle in
                handleView(handle: handle, pixelRect: pixelRect, displayRect: displayRect)
            }
        }
    }

    private func handleView(handle: Handle, pixelRect: CGRect, displayRect: CGRect) -> some View {
        let position = handle.position(in: pixelRect)
        return Circle()
            .fill(Color.white)
            .frame(width: handleSize, height: handleSize)
            .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 1))
            .position(x: position.x, y: position.y)
            .gesture(resizeGesture(for: handle, displayRect: displayRect))
    }

    // MARK: - Gestures

    private func moveGesture(displayRect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let base = dragBaseRect ?? cropRect
                if dragBaseRect == nil { dragBaseRect = base }

                let dx = value.translation.width / displayRect.width
                let dy = value.translation.height / displayRect.height

                var newOrigin = CGPoint(x: base.origin.x + dx, y: base.origin.y + dy)
                newOrigin.x = min(max(0, newOrigin.x), 1 - base.width)
                newOrigin.y = min(max(0, newOrigin.y), 1 - base.height)

                cropRect = CGRect(origin: newOrigin, size: base.size)
            }
            .onEnded { _ in dragBaseRect = nil }
    }

    private func resizeGesture(for handle: Handle, displayRect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let base = dragBaseRect ?? cropRect
                if dragBaseRect == nil { dragBaseRect = base }

                let dx = value.translation.width / displayRect.width
                let dy = value.translation.height / displayRect.height
                cropRect = handle.applied(to: base, dx: dx, dy: dy, minSize: minCropFraction)
            }
            .onEnded { _ in dragBaseRect = nil }
    }

    // MARK: - Cropping

    private func confirm() {
        let rotated = rotatedImage()
        guard let cropped = crop(image: rotated, normalizedRect: cropRect) else {
            onConfirm(rotated)
            return
        }
        onConfirm(cropped)
    }

    private func crop(image: UIImage, normalizedRect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        let pixelRect = CGRect(
            x: floor(normalizedRect.minX * width),
            y: floor(normalizedRect.minY * height),
            width: floor(normalizedRect.width * width),
            height: floor(normalizedRect.height * height)
        ).integral

        let clamped = pixelRect.intersection(CGRect(x: 0, y: 0, width: width, height: height))
        guard clamped.width > 0, clamped.height > 0,
              let croppedCG = cgImage.cropping(to: clamped) else {
            return nil
        }
        return UIImage(cgImage: croppedCG, scale: image.scale, orientation: .up)
    }

    private func rotatedImage() -> UIImage {
        let normalizedDegrees = ((rotationAngle.truncatingRemainder(dividingBy: 360)) + 360)
            .truncatingRemainder(dividingBy: 360)
        guard normalizedDegrees != 0 else { return image }

        let radians = normalizedDegrees * .pi / 180
        let originalSize = image.size
        let rotatedSize: CGSize = (Int(normalizedDegrees) % 180 == 0)
            ? originalSize
            : CGSize(width: originalSize.height, height: originalSize.width)

        let renderer = UIGraphicsImageRenderer(size: rotatedSize)
        return renderer.image { ctx in
            let context = ctx.cgContext
            context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.rotate(by: radians)
            image.draw(in: CGRect(
                x: -originalSize.width / 2,
                y: -originalSize.height / 2,
                width: originalSize.width,
                height: originalSize.height
            ))
        }
    }

    private func aspectFitRect(for imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }
        let scale = min(containerSize.width / imageSize.width,
                        containerSize.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(
            x: (containerSize.width - width) / 2,
            y: (containerSize.height - height) / 2,
            width: width,
            height: height
        )
    }

    // MARK: - Control bar

    private var controlBar: some View {
        HStack {
            Button(action: onCancel) {
                Text("Cancel")
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
            }

            Spacer()

            Button {
                rotationAngle = (rotationAngle + 90).truncatingRemainder(dividingBy: 360)
            } label: {
                Image(systemName: "rotate.right")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
            }

            Spacer()

            Button(action: confirm) {
                Text("Confirm")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
    }
}

// MARK: - Handle

private enum Handle: CaseIterable {
    case topLeft, top, topRight
    case left, right
    case bottomLeft, bottom, bottomRight

    func position(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft:     return CGPoint(x: rect.minX, y: rect.minY)
        case .top:         return CGPoint(x: rect.midX, y: rect.minY)
        case .topRight:    return CGPoint(x: rect.maxX, y: rect.minY)
        case .left:        return CGPoint(x: rect.minX, y: rect.midY)
        case .right:       return CGPoint(x: rect.maxX, y: rect.midY)
        case .bottomLeft:  return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottom:      return CGPoint(x: rect.midX, y: rect.maxY)
        case .bottomRight: return CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }

    func applied(to rect: CGRect, dx: CGFloat, dy: CGFloat, minSize: CGFloat) -> CGRect {
        var minX = rect.minX
        var minY = rect.minY
        var maxX = rect.maxX
        var maxY = rect.maxY

        switch self {
        case .topLeft:
            minX += dx
            minY += dy
        case .top:
            minY += dy
        case .topRight:
            maxX += dx
            minY += dy
        case .left:
            minX += dx
        case .right:
            maxX += dx
        case .bottomLeft:
            minX += dx
            maxY += dy
        case .bottom:
            maxY += dy
        case .bottomRight:
            maxX += dx
            maxY += dy
        }

        minX = max(0, min(minX, maxX - minSize))
        minY = max(0, min(minY, maxY - minSize))
        maxX = min(1, max(maxX, minX + minSize))
        maxY = min(1, max(maxY, minY + minSize))

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
