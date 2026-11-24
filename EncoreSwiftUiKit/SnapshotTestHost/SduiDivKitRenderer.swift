import DivKit
import EncoreSwiftUiKit
import LayoutKit
import SwiftUI
import UIKit

@MainActor
enum SduiDivKitRenderer {
    static let components = DivKitComponents(divCustomBlockFactory: SduiPreviewBlockFactory())

    static func install() {
        SduiPreviewRendering.renderer = { json, cardId in
            AnyView(SduiDivView(json: json, cardId: cardId))
        }
    }
}

struct SduiDivView: UIViewRepresentable {
    let json: String
    let cardId: String

    func makeUIView(context _: Context) -> SduiDivHostView {
        let host = SduiDivHostView(components: SduiDivKitRenderer.components)
        host.show(json: json, cardId: cardId)
        return host
    }

    func updateUIView(_ host: SduiDivHostView, context _: Context) {
        host.show(json: json, cardId: cardId)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: SduiDivHostView, context _: Context) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width
        return uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }
}

final class SduiDivHostView: UIView {
    private let components: DivKitComponents
    private let divView: DivView
    private var shown: String?
    private var sizeObserver: Any?

    init(components: DivKitComponents) {
        self.components = components
        divView = DivView(divKitComponents: components)
        super.init(frame: .zero)
        addSubview(divView)
        sizeObserver = divView.addObserver { [weak self] _ in
            self?.invalidateIntrinsicContentSize()
            self?.setNeedsLayout()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(json: String, cardId: String) {
        guard json != shown, let data = json.data(using: .utf8) else { return }
        let reload = shown != nil
        shown = json
        let id = DivCardID(rawValue: cardId)
        Task { @MainActor in
            if reload {
                components.reset(cardId: id)
            }
            await divView.setSource(DivViewSource(kind: .data(data), cardId: id))
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        divView.intrinsicContentSize
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        divView.sizeThatFits(size)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        divView.frame = bounds
        divView.onVisibleBoundsChanged(to: bounds)
    }
}

final class SduiPreviewBlockFactory: DivCustomBlockFactory {
    func makeBlock(data: DivCustomData, context _: DivBlockModelingContext) -> any Block {
        switch data.name {
        case "platform_image":
            let imageName = data.data["image_name"] as? String ?? ""
            let tint = Self.color(data.data["icon_color"] as? String)
            let imageView = PlatformImageView(imageName: imageName, tintColor: tint)
            if let size = (data.data["icon_size"] as? NSNumber).map({ CGFloat(truncating: $0) }) {
                return GenericViewBlock(content: .view(imageView), width: .fixed(size), height: .fixed(size))
            }
            return GenericViewBlock.makeIntrinsicSized(for: imageView)
        case "dotted_line":
            let color = Self.color(data.data["color"] as? String) ?? .secondaryLabel
            return GenericViewBlock(content: .view(SduiDottedLine(color: color)), width: .resizable, height: .fixed(2))
        default:
            return EmptyBlock()
        }
    }

    private static func color(_ hex: String?) -> UIColor? {
        guard let cleaned = hex?.trimmingCharacters(in: CharacterSet.alphanumerics.inverted),
              cleaned.count == 6
        else { return nil }
        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else { return nil }
        return UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}

final class SduiDottedLine: UIView {
    private let color: UIColor

    init(color: UIColor) {
        self.color = color
        super.init(frame: .zero)
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(rect.height)
        context.setLineDash(phase: 0, lengths: [rect.height, rect.height * 2])
        context.move(to: CGPoint(x: 0, y: rect.midY))
        context.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        context.strokePath()
    }
}
