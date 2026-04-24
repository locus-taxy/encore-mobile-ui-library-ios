import SwiftUI

public struct EncoreIcon: View {
    var iconName: String
    var size: CGFloat

    public init(iconName: String, size: CGFloat) {
        self.iconName = iconName
        self.size = size
    }

    public var body: some View {
        Image.withName(iconName)
            .renderingMode(.template)
            .resizable()
            .frame(width: size, height: size)
    }
}

#Preview {
    EncoreIcon(iconName: "Schedule", size: 26)
}
