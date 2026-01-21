import SwiftUI

public struct EncoreImage: View {
    public var iconName: String
    public var size: CGFloat

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
