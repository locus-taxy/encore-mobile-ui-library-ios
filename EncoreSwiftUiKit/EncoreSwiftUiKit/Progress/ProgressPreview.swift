import SwiftUI

#Preview("LinearProgress-Determinate") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.spacing16) {
            LinearProgressView(value: 0.0)
            LinearProgressView(value: 0.5)
            LinearProgressView(value: 1.0)
        }
        .padding(Spacing.spacing16)
    }
    .preferredColorScheme(.light)
}

#Preview("LinearProgress-Indeterminate") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.spacing16) {
            LinearProgressView(value: nil)
        }
        .padding(Spacing.spacing16)
    }
    .preferredColorScheme(.light)
}

#Preview("LinearProgressWithLabel-Determinate") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.spacing16) {
            LinearProgressWithLabelView(label: "Loading", value: 0.0)
            LinearProgressWithLabelView(label: "Loading", value: 0.5)
            LinearProgressWithLabelView(label: "Loading", value: 1.0)
        }
        .padding(Spacing.spacing16)
    }
    .preferredColorScheme(.light)
}

#Preview("LinearProgressWithLabel-Indeterminate") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.spacing16) {
            LinearProgressWithLabelView(label: "Processing...", value: nil)
        }
        .padding(Spacing.spacing16)
    }
    .preferredColorScheme(.light)
}

#Preview("CircularProgress-Indeterminate") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.spacing16) {
            CircularProgressView(size: .small, value: nil)
            CircularProgressView(size: .medium, value: nil)
            CircularProgressView(size: .large, value: nil)
            CircularProgressView(size: .xlarge, value: nil)
        }
        .padding(Spacing.spacing16)
    }
    .preferredColorScheme(.light)
}

#Preview("CircularProgress-Determinate") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.spacing16) {
            CircularProgressView(size: .small, value: 0.5)
            CircularProgressView(size: .medium, value: 0.5)
            CircularProgressView(size: .large, value: 0.5)
            CircularProgressView(size: .xlarge, value: 0.5)
        }
        .padding(Spacing.spacing16)
    }
    .preferredColorScheme(.light)
}
