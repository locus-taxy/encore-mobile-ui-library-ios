import SwiftUI

#Preview("SlidingButton-Enabled") {
    ScrollView {
        VStack(spacing: Spacing.spacing16) {
            SlidingButtonView(label: "Slide to confirm", onSlideComplete: {})
        }
        .padding(Spacing.spacing24)
    }
    .preferredColorScheme(.light)
}

#Preview("SlidingButton-Disabled") {
    ScrollView {
        VStack(spacing: Spacing.spacing16) {
            SlidingButtonView(label: "Slide to confirm", onSlideComplete: {})
                .disabled(true)
        }
        .padding(Spacing.spacing24)
    }
    .preferredColorScheme(.light)
}

#Preview("SlidingButton-Loading") {
    ScrollView {
        VStack(spacing: Spacing.spacing16) {
            SlidingButtonView(label: "Slide to confirm", isLoading: true, onSlideComplete: {})
        }
        .padding(Spacing.spacing24)
    }
    .preferredColorScheme(.light)
}
