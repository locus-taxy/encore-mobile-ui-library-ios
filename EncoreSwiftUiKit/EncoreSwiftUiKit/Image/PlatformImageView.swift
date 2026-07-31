//
//  PlatformImageView.swift
//  EncoreSwiftUiKit
//
//  Created by Kanj on 09/02/26.
//
import UIKit

/// A UIView that displays an image using the same logic as Image.withName
/// This is used by DivKit to render icons
public final class PlatformImageView: UIView {

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        return imageView
    }()

    /// - Parameter tintColor: when set, the image renders as a template in
    ///   this colour (asset icons ship un-templated, so tinting must force
    ///   template rendering); when nil, the image keeps its own colours.
    public init(imageName: String, tintColor: UIColor? = nil) {
        super.init(frame: .zero)
        setupView()
        loadImage(named: imageName)
        if let tintColor {
            imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = tintColor
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func loadImage(named name: String) {
        // Check if name maps to an SF Symbol
        if let systemIconName = imageNameMap[name] {
            imageView.image = UIImage(systemName: systemIconName)
            return
        }

        // Try to load from asset catalog
        if let image = UIImage(named: name, in: BundleToken.bundle, with: nil) {
            imageView.image = image
            return
        }

        // Fallback to placeholder
        imageView.image = UIImage(systemName: "rectangle.dashed")
    }

    override public var intrinsicContentSize: CGSize {
        imageView.intrinsicContentSize
    }

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        imageView.sizeThatFits(size)
    }
}
