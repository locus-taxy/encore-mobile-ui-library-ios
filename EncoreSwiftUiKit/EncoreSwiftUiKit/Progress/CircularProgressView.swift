import SwiftUI

public enum CircularProgressSize {
    case small, medium, large, xlarge

    var pt: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 32
        case .large: return 40
        case .xlarge: return 64
        }
    }

    var strokeWidth: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 4
        case .large: return 5
        case .xlarge: return 8
        }
    }
}

/// Circular progress indicator matching Figma design specifications.
/// Mirrors Android's `CircularProgress` composable.
///
/// - Pass `value: nil` for an indeterminate spinner.
/// - Pass `value` in 0.0...1.0 for a determinate arc starting at 12 o'clock.
public struct CircularProgressView: View {
    public let size: CircularProgressSize
    public let value: Double?

    public init(size: CircularProgressSize = .medium, value: Double? = nil) {
        self.size = size
        self.value = value
    }

    public var body: some View {
        if let value {
            determinate(value: value)
        } else {
            indeterminate
        }
    }

    private var indeterminate: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(Color.encore("Primary/Main"))
            .frame(width: size.pt, height: size.pt)
    }

    private func determinate(value: Double) -> some View {
        let clamped = min(max(value, 0), 1)
        return ZStack {
            Circle()
                .stroke(
                    Color.encore("Primary/Main").opacity(0.38),
                    lineWidth: size.strokeWidth
                )
            Circle()
                .trim(from: 0, to: CGFloat(clamped))
                .stroke(
                    Color.encore("Primary/Main"),
                    style: StrokeStyle(lineWidth: size.strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            if size != .small {
                Text("\(Int(clamped * 100))%")
                    .typography(Typography.body2)
                    .foregroundColor(Color.encore("Text/Secondary"))
            }
        }
        .frame(width: size.pt, height: size.pt)
    }
}
