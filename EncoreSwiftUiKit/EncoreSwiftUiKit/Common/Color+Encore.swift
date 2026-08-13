import SwiftUI
import UIKit

public extension Color {
    static func encore(_ name: String) -> Color {
        Color(name, bundle: BundleToken.bundle)
    }

    /// True when `name` resolves to a real colour asset in the kit catalogue.
    /// Callers rendering BE-declared colour tokens use this to detect a
    /// malformed / unknown token before `encore(_:)` silently renders it as the
    /// system default.
    static func encoreExists(_ name: String) -> Bool {
        UIColor(named: name, in: BundleToken.bundle, compatibleWith: nil) != nil
    }
}
