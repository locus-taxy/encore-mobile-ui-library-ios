import SwiftUI

/// Reusable single choice radio button view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `SingleChoiceView` composable.
public struct SingleChoiceView: View {
    let options: [String]
    let selectedIndex: Int
    var onCheckedChange: (Int, Bool) -> Void

    public init(
        options: [String],
        selectedIndex: Int,
        onCheckedChange: @escaping (Int, Bool) -> Void = { _, _ in }
    ) {
        self.options = options
        self.selectedIndex = selectedIndex
        self.onCheckedChange = onCheckedChange
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                SingleChoiceOptionRow(
                    option: option,
                    isSelected: selectedIndex == index,
                    onCheckedChange: { checked in
                        onCheckedChange(index, checked)
                    }
                )
            }
        }
    }
}

/// A single row within the SingleChoiceView containing a radio button and label.
struct SingleChoiceOptionRow: View {
    let option: String
    let isSelected: Bool
    let onCheckedChange: (Bool) -> Void

    var body: some View {
        Button {
            onCheckedChange(!isSelected)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
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

