import SwiftUI

struct EncoreImage: View {
    var iconName: String
    var size: CGFloat

    var body: some View {
        #if SWIFT_PACKAGE
            let bundle = Bundle.module
        #else
            let bundle = Bundle.main
        #endif
        return Image(iconName, bundle: bundle)
            .frame(width: size, height: size)
    }
}
