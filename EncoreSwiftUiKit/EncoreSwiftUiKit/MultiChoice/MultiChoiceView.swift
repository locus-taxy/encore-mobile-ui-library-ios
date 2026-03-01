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
        VStack(alignment: .leading, spacing: 4) {
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
        Button {
            onCheckedChange(!isChecked)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .accentColor : .secondary)
                    .font(.system(size: 20))

                Text(option)
                    .font(.system(size: ChecklistItemConstants.optionFontSize))
                    .foregroundColor(.primary)
                    .lineSpacing(ChecklistItemConstants.optionLineHeight - ChecklistItemConstants.optionFontSize)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

