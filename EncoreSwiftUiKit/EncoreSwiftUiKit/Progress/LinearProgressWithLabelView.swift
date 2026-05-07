import SwiftUI

/// Linear progress indicator with a label row above the track.
/// Determinate when `value` is non-nil (0.0–1.0); indeterminate when `value` is nil.
public struct LinearProgressWithLabelView: View {
    private let label: String
    private let value: Double?

    public init(label: String, value: Double? = nil) {
        self.label = label
        self.value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing4) {
            HStack(spacing: Spacing.spacing8) {
                Text(label)
                    .typography(Typography.body2)
                    .foregroundColor(Color.encore("Text/Primary"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let value = value {
                    Text("\(Int(max(0, min(1, value)) * 100))%")
                        .typography(Typography.body2)
                        .foregroundColor(Color.encore("Text/Primary"))
                        .fixedSize()
                }
            }

            LinearProgressView(value: value)
        }
        .frame(minWidth: 180)
        .frame(maxWidth: .infinity)
    }
}
