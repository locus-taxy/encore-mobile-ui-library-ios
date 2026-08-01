import SwiftUI

/// Reusable multi choice checkbox list view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `MultiChoiceView` composable.
public struct MultiChoiceView: View {
    let options: [String]
    let selectedIndices: Set<Int>
    var onCheckedChange: (Int, Bool) -> Void

    public init(
        options: [String],
        selectedIndices: Set<Int>,
        onCheckedChange: @escaping (Int, Bool) -> Void = { _, _ in }
    ) {
        self.options = options
        self.selectedIndices = selectedIndices
        self.onCheckedChange = onCheckedChange
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                MultiChoiceOptionRow(
                    option: option,
                    isChecked: selectedIndices.contains(index),
                    onCheckedChange: { checked in
                        onCheckedChange(index, checked)
                    }
                )
            }
        }
    }
}

/// A single row within the MultiChoiceView containing a checkbox and label.
struct MultiChoiceOptionRow: View {
    let option: String
    let isChecked: Bool
    let onCheckedChange: (Bool) -> Void

    var body: some View {
        HStack(spacing: 0) {
            // 48×48 touch target containing the 18×18 checkbox glyph centered within it
            ZStack {
                if isChecked {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.encore("Primary/Main"))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Color.encore("Text/Secondary"), lineWidth: 1.67)
                        .frame(width: 18, height: 18)
                }
            }
            .frame(width: 48, height: 48)

            Text(option)
                .typography(Typography.body1)
                .foregroundColor(Color.encore("Text/Primary"))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, -8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
        .background(Color.encore("Background/Default"))
        .contentShape(Rectangle())
        .onTapGesture {
            onCheckedChange(!isChecked)
        }
    }
}
