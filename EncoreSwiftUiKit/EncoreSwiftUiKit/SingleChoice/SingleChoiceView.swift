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
        VStack(alignment: .leading, spacing: 1) {
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
        HStack(spacing: 0) {
            // 48×48 touch target containing the 20×20 radio glyph centered within it
            ZStack {
                if isSelected {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.encore("Primary/Main"), lineWidth: 1.67)
                        Circle()
                            .fill(Color.encore("Primary/Main"))
                            .frame(width: 10, height: 10)
                    }
                    .frame(width: 20, height: 20)
                } else {
                    Circle()
                        .strokeBorder(Color.encore("Text/Secondary"), lineWidth: 1.67)
                        .frame(width: 20, height: 20)
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
            onCheckedChange(!isSelected)
        }
    }
}
