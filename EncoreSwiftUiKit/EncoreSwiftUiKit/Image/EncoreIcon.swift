import SwiftUI

public struct EncoreIcon: View {
    var iconName: String
    var size: CGFloat

    public init(iconName: String, size: CGFloat) {
        self.iconName = iconName
        self.size = size
    }

    public var body: some View {
        return Image.withName(iconName)
            .frame(width: size, height: size)
    }
}
