import SwiftUI

public struct EncoreImage: View {
    var iconName: String
    var size: CGFloat

    public init(iconName: String, size: CGFloat) {
        self.iconName = iconName
        self.size = size
    }

    public var body: some View {
        #if SWIFT_PACKAGE
            let bundle = Bundle.module
        #else
            let bundle = Bundle.main
        #endif
        return Image(iconName, bundle: bundle)
            .frame(width: size, height: size)
    }
}
