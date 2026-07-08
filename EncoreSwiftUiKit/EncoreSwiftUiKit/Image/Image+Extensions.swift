import SwiftUI
import UIKit

public extension Image {

    static func withName(_ name: String?) -> Image {
        guard let name = name else { return Image(systemName: "rectangle.dashed") }
        if let systemIconName = imageNameMap[name] {
            return Image(systemName: systemIconName)
        }

        guard let uIImage = UIImage(named: name, in: BundleToken.bundle, with: nil) else {
            return Image(systemName: "rectangle.dashed")
        }
        return Image(uiImage: uIImage)
    }
}

public extension UIImage {

    /// Resolves a bundled icon by name from this module's own asset catalog — the same
    /// `BundleToken.bundle` lookup `Image.withName` uses — for callers that need a raw
    /// `UIImage?` with a real `nil` on miss (no SF Symbol fallback), e.g. DivKit's
    /// `divkit-asset://` URL resolution, which needs to distinguish "found" from "not found"
    /// to decide whether to fall through to another resolver.
    static func encoreAsset(named name: String) -> UIImage? {
        UIImage(named: name, in: BundleToken.bundle, with: nil)
    }
}
