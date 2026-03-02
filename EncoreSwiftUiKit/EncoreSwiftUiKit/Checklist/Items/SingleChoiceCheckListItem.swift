import SwiftUI

/// Single choice checklist item with radio buttons matching Figma design specifications.
/// Composes ChecklistHeader + SingleChoiceView.
/// Mirrors Android's `SingleChoiceCheckListItem` composable.
public struct SingleChoiceCheckListItem: View {
    let title: String
    let options: [String]
    let initialSelectedIndex: Int
    let onSelectionChange: (Int, Bool) -> Void
    let isRequired: Bool

    @State private var selectedIndex: Int

    public init(
        title: String,
        options: [String],
        initialSelectedIndex: Int,
        onSelectionChange: @escaping (Int, Bool) -> Void,
        isRequired: Bool
    ) {
        self.title = title
        self.options = options
        self.initialSelectedIndex = initialSelectedIndex
        self.onSelectionChange = onSelectionChange
        self.isRequired = isRequired
        self._selectedIndex = State(initialValue: initialSelectedIndex)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired && selectedIndex == -1
            )

            SingleChoiceView(
                options: options,
                selectedIndex: selectedIndex,
                onCheckedChange: { index, checked in
                    if checked {
                        let previousIndex = selectedIndex
                        selectedIndex = index
                        if previousIndex != -1, previousIndex != index {
                            onSelectionChange(previousIndex, false)
                        }
                        onSelectionChange(index, true)
                    } else {
                        if selectedIndex == index {
                            selectedIndex = -1
                            onSelectionChange(index, false)
                        }
                    }
                }
            )
            .padding(.top, ChecklistItemConstants.innerTopPadding)
        }
        .padding(ChecklistItemConstants.itemPadding)
        .onChange(of: initialSelectedIndex) { newValue in
            selectedIndex = newValue
        }
    }
}

