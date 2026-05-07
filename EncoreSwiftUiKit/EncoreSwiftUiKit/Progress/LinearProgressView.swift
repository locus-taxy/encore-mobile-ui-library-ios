import SwiftUI

/// Linear progress indicator matching Figma design specifications.
/// Determinate when `value` is non-nil (0.0–1.0); indeterminate when `value` is nil.
public struct LinearProgressView: View {
    private let value: Double?

    public init(value: Double? = nil) {
        self.value = value
    }

    public var body: some View {
        if let value = value {
            HStack(spacing: Spacing.spacing8) {
                LinearProgressTrack(value: value)
                Text("\(Int(max(0, min(1, value)) * 100))%")
                    .typography(Typography.body2)
                    .foregroundColor(Color.encore("Text/Primary"))
            }
            .frame(minWidth: 200)
            .frame(maxWidth: .infinity)
        } else {
            LinearProgressTrack(value: nil)
                .frame(minWidth: 200)
                .frame(maxWidth: .infinity)
        }
    }
}

/// Track-only rendering shared by LinearProgressView and LinearProgressWithLabelView.
struct LinearProgressTrack: View {
    let value: Double?

    var body: some View {
        if let value = value {
            DeterminateTrack(value: max(0, min(1, value)))
        } else {
            IndeterminateTrack()
        }
    }
}

private struct DeterminateTrack: View {
    let value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.encore("Primary/Main").opacity(0.38))
                Rectangle()
                    .fill(Color.encore("Primary/Main"))
                    .frame(width: geometry.size.width * CGFloat(value))
            }
            .clipped()
        }
        .frame(height: Spacing.spacing4)
    }
}

private struct IndeterminateTrack: View {
    @State private var bar1Progress: CGFloat = 0
    @State private var bar2Progress: CGFloat = 0

    private let bar1Width: CGFloat = 0.30
    private let bar2Width: CGFloat = 0.70
    private let animationDuration: Double = 2.1

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.encore("Primary/Main").opacity(0.38))

                Rectangle()
                    .fill(Color.encore("Primary/Main"))
                    .frame(width: totalWidth * bar1Width)
                    .offset(x: -totalWidth * bar1Width + bar1Progress * (totalWidth + totalWidth * bar1Width))

                Rectangle()
                    .fill(Color.encore("Primary/Main"))
                    .frame(width: totalWidth * bar2Width)
                    .offset(x: -totalWidth * bar2Width + bar2Progress * (totalWidth + totalWidth * bar2Width))
            }
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
                    bar1Progress = 1
                }
                withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: false).delay(animationDuration / 2)) {
                    bar2Progress = 1
                }
            }
        }
        .frame(height: Spacing.spacing4)
    }
}
