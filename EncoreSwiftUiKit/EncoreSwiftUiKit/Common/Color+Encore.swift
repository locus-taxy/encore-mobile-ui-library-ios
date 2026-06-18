import SwiftUI

public extension Color {
    static func encore(_ name: String) -> Color {
        Color(name, bundle: BundleToken.bundle)
    }
}
