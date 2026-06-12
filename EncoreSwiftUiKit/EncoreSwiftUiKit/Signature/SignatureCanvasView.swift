import SwiftUI
import UIKit

/// Reusable signature capture view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `SignatureView` composable.
public struct SignatureCanvasView: View {
    let signatureURL: URL?
    let onSignatureSelected: (URL?) -> Void
    var onRemoveSignature: (() -> Void)?
    var addSignatureText: String
    var onGetCaptionText: (() -> String?)?

    @State private var showSignatureCanvas = false

    public init(
        signatureURL: URL?,
        onSignatureSelected: @escaping (URL?) -> Void,
        onRemoveSignature: (() -> Void)? = nil,
        addSignatureText: String = "Add Signature",
        onGetCaptionText: (() -> String?)? = nil
    ) {
        self.signatureURL = signatureURL
        self.onSignatureSelected = onSignatureSelected
        self.onRemoveSignature = onRemoveSignature
        self.addSignatureText = addSignatureText
        self.onGetCaptionText = onGetCaptionText
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let signatureURL = signatureURL {
                // Display existing signature
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: signatureURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.1))
                            .overlay(ProgressView())
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .onTapGesture {
                        showSignatureCanvas = true
                    }

                    Button {
                        onSignatureSelected(nil)
                        onRemoveSignature?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .offset(x: 4, y: -4)
                }
            } else {
                // Placeholder button
                Button {
                    showSignatureCanvas = true
                } label: {
                    HStack {
                        Image(systemName: "pencil.tip")
                            .font(.system(size: 20))
                        Text(addSignatureText)
                    }
                    .foregroundColor(.accentColor)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .fullScreenCover(isPresented: $showSignatureCanvas) {
            SignatureDrawingCanvas(
                existingSignatureURL: signatureURL,
                onSignatureSaved: { url in
                    onSignatureSelected(url)
                    showSignatureCanvas = false
                },
                onDismiss: {
                    showSignatureCanvas = false
                },
                onGetCaptionText: onGetCaptionText
            )
        }
    }
}

// MARK: - Signature Drawing Canvas

struct SignatureDrawingCanvas: View {
    let existingSignatureURL: URL?
    let onSignatureSaved: (URL) -> Void
    let onDismiss: () -> Void
    var onGetCaptionText: (() -> String?)?

    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Sign Here")
                    .font(.headline)
                    .padding(.top, 16)

                // Drawing area
                GeometryReader { geo in
                    Canvas { context, _ in
                        for line in lines {
                            var path = Path()
                            guard let firstPoint = line.first else { continue }
                            path.move(to: firstPoint)
                            for point in line.dropFirst() {
                                path.addLine(to: point)
                            }
                            context.stroke(path, with: .color(.primary), lineWidth: 2)
                        }

                        if !currentLine.isEmpty {
                            var path = Path()
                            path.move(to: currentLine[0])
                            for point in currentLine.dropFirst() {
                                path.addLine(to: point)
                            }
                            context.stroke(path, with: .color(.primary), lineWidth: 2)
                        }
                    }
                    .background(Color.white)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                currentLine.append(value.location)
                            }
                            .onEnded { _ in
                                lines.append(currentLine)
                                currentLine = []
                            }
                    )
                    .onAppear { canvasSize = geo.size }
                    .onChange(of: geo.size) { canvasSize = $0 }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .padding()

                HStack(spacing: 16) {
                    Button("Clear") {
                        lines = []
                        currentLine = []
                    }
                    .foregroundColor(.red)

                    Spacer()

                    Button("Cancel") {
                        onDismiss()
                    }

                    Button("Save") {
                        saveSignature()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(lines.isEmpty)
                }
                .padding()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func saveSignature() {
        let renderSize = canvasSize == .zero
            ? CGSize(width: 390, height: 300)
            : canvasSize
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)
        let uiImage = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: renderSize))

            UIColor.black.setStroke()
            for line in lines {
                guard let firstPoint = line.first else { continue }
                let bezier = UIBezierPath()
                bezier.lineWidth = 2
                bezier.move(to: firstPoint)
                for point in line.dropFirst() {
                    bezier.addLine(to: point)
                }
                bezier.stroke()
            }
        }

        if let data = uiImage.pngData() {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("png")
            do {
                try data.write(to: tempURL)
                onSignatureSaved(tempURL)
            } catch {
                // Write failed
            }
        }
    }
}
