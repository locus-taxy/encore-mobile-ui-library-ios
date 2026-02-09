import SwiftUI

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
