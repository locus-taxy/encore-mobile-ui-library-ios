import SwiftUI

/// Multi choice checklist item with checkboxes matching Figma design specifications.
/// Composes ChecklistHeader + MultiChoiceView.
/// Mirrors Android's `MultiChoiceCheckListItem` composable.
public struct MultiChoiceCheckListItem: View {
    let title: String
    let options: [String]
    let initialSelectedIndices: Set<Int>
    let onSelectionChanged: (Set<Int>) -> Void
    let isRequired: Bool

    @State private var selectedIndices: Set<Int>

    public init(
        title: String,
        options: [String],
        initialSelectedIndices: Set<Int>,
        onSelectionChanged: @escaping (Set<Int>) -> Void,
        isRequired: Bool
    ) {
        self.title = title
        self.options = options
        self.initialSelectedIndices = initialSelectedIndices
        self.onSelectionChanged = onSelectionChanged
        self.isRequired = isRequired
        self._selectedIndices = State(initialValue: initialSelectedIndices)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired && selectedIndices.isEmpty
            )

            MultiChoiceView(
                options: options,
                selectedIndices: selectedIndices,
                onCheckedChange: { index, checked in
                    if checked {
                        selectedIndices.insert(index)
                    } else {
                        selectedIndices.remove(index)
                    }
                    onSelectionChanged(selectedIndices)
                }
            )
            .padding(.top, ChecklistItemConstants.innerTopPadding)
        }
        .padding(ChecklistItemConstants.itemPadding)
        .onChange(of: initialSelectedIndices) { newValue in
            selectedIndices = newValue
        }
    }
}

