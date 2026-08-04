import SwiftUI

/// Sliding button (slide-to-confirm) component matching Figma design specifications.
/// Mirrors Android's `SlidingButton` composable.
public struct SlidingButtonView: View {
    @Environment(\.isEnabled) private var isEnabled

    private let label: String
    private let isLoading: Bool
    private let onSlideComplete: () -> Void

    @State private var thumbOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    public init(
        label: String,
        isLoading: Bool = false,
        onSlideComplete: @escaping () -> Void
    ) {
        self.label = label
        self.isLoading = isLoading
        self.onSlideComplete = onSlideComplete
    }

    public var body: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width
            let trackWidth = max(0, containerWidth - Spacing.spacing4 * 2 - Spacing.spacing40)
            let progress: CGFloat = trackWidth > 0 ? min(max(thumbOffset / trackWidth, 0), 1) : 0

            ZStack(alignment: .leading) {
                if isLoading {
                    HStack(spacing: Spacing.spacing8) {
                        ProgressView()
                            .tint(Color.encore("Text/Disabled"))
                            .frame(width: Spacing.spacing16, height: Spacing.spacing16)
                        Text("Loading...")
                            .typography(Typography.Button.large)
                            .foregroundColor(Color.encore("Text/Disabled"))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text(label)
                        .typography(Typography.Button.large)
                        .foregroundColor(labelColor)
                        .opacity(isDragging ? max(0.2, 1.0 - progress) : 1.0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    thumb(progress: progress)
                        .offset(x: Spacing.spacing4 + thumbOffset)
                        .frame(maxHeight: .infinity, alignment: .leading)
                        .gesture(isEnabled ? dragGesture(trackWidth: trackWidth) : nil)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Spacing.spacing48)
        .padding(Spacing.spacing4)
        .background(backgroundColor)
        .cornerRadius(Spacing.spacing8)
    }

    private func thumb(progress: CGFloat) -> some View {
        let iconName = progress >= 0.8 ? "LCheck" : "LKeyboardDoubleArrowRight"
        return ZStack {
            EncoreIcon(iconName: iconName, size: Spacing.spacing20)
                .foregroundColor(isEnabled ? Color.encore("Primary/Main") : Color.encore("Text/Disabled"))
        }
        .frame(width: Spacing.spacing40, height: Spacing.spacing40)
        .background(Color.encore("Background/Default"))
        .cornerRadius(Spacing.spacing4)
    }

    private func dragGesture(trackWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true
                thumbOffset = min(max(value.translation.width, 0), trackWidth)
            }
            .onEnded { _ in
                isDragging = false
                if trackWidth > 0 && thumbOffset >= trackWidth {
                    onSlideComplete()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        thumbOffset = 0
                    }
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        thumbOffset = 0
                    }
                }
            }
    }

    private var backgroundColor: Color {
        if isLoading || !isEnabled {
            return Color.encore("Action/DisabledBackground")
        }
        return Color.encore("Primary/Main")
    }

    private var labelColor: Color {
        if !isEnabled {
            return Color.encore("Text/Disabled")
        }
        return Color.encore("Primary/ContrastText")
    }
}

#Preview("SlidingButtonView") {
    VStack(spacing: Spacing.spacing24) {
        SlidingButtonView(label: "Slide to confirm", onSlideComplete: {})
        SlidingButtonView(label: "Slide to confirm", isLoading: true, onSlideComplete: {})
        SlidingButtonView(label: "Slide to confirm", onSlideComplete: {})
            .disabled(true)
    }
    .padding(Spacing.spacing24)
}
