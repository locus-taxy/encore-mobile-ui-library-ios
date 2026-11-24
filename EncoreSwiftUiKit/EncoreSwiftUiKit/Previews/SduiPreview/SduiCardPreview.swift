import SwiftUI

public struct SduiCardPreview: View {
    private let path: URL
    private let cardId: String
    private let placeholderHeight: CGFloat
    @State private var json: String?

    public init(
        _ relativePath: String,
        placeholderHeight: CGFloat = 120,
        sourceFile: StaticString = #filePath
    ) {
        let folder = URL(fileURLWithPath: "\(sourceFile)").deletingLastPathComponent()
        let path = folder.appendingPathComponent(relativePath)
        self.path = path
        cardId = path.deletingPathExtension().lastPathComponent
        self.placeholderHeight = placeholderHeight
        _json = State(initialValue: Self.read(path))
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .task(id: path) { await follow() }
    }

    @ViewBuilder
    private var content: some View {
        if let json {
            SduiDivView(json: json, cardId: cardId)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.secondary, lineWidth: 1))
                .overlay(Text("SDUI card · \(cardId)").font(.footnote).foregroundColor(.secondary))
                .frame(height: placeholderHeight)
        }
    }

    private func follow() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            let next = Self.read(path)
            if next != json {
                json = next
            }
        }
    }

    private static func read(_ path: URL) -> String? {
        if let text = try? String(contentsOf: path, encoding: .utf8) {
            return text
        }
        let name = path.deletingPathExtension().lastPathComponent
        guard let bundled = Bundle(for: SduiPreviewBundle.self).url(forResource: name, withExtension: "json") else {
            return nil
        }
        return try? String(contentsOf: bundled, encoding: .utf8)
    }
}

private final class SduiPreviewBundle {}
