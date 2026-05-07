import SwiftUI

#Preview("CircularProgress-Indeterminate") {
    ScrollView {
        VStack(spacing: Spacing.spacing16) {
            CircularProgressView(size: .small, value: nil)
            CircularProgressView(size: .medium, value: nil)
            CircularProgressView(size: .large, value: nil)
            CircularProgressView(size: .xlarge, value: nil)
        }
        .padding(Spacing.spacing24)
    }
    .preferredColorScheme(.light)
}

#Preview("CircularProgress-Determinate") {
    ScrollView {
        VStack(spacing: Spacing.spacing16) {
            CircularProgressView(size: .small, value: 0.25)
            CircularProgressView(size: .medium, value: 0.5)
            CircularProgressView(size: .large, value: 0.75)
            CircularProgressView(size: .xlarge, value: 1.0)
        }
        .padding(Spacing.spacing24)
    }
    .preferredColorScheme(.light)
}
