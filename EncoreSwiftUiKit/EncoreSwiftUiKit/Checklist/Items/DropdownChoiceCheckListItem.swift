import SwiftUI

/// Choice checklist item rendered as an anchored dropdown instead of inline
/// radios/checkboxes — used when an option list is long (> 5). Composes
/// ChecklistHeader + EncoreDropdownField + `.encoreDropdown`, and owns the
/// open + selection state. Works for both single- and multi-choice via `mode`.
public struct DropdownChoiceCheckListItem: View {
    let title: String
    var helperText: String? = nil
    var itemIndex: Int? = nil
    var totalItems: Int? = nil
    var isCompleted: Bool = false
    let options: [String]
    let mode: EncoreDropdownMode
    let placeholder: String
    let onCommit: (Set<Int>) -> Void
    let isRequired: Bool

    @State private var selection: Set<Int>
    @State private var isOpen = false

    public init(
        title: String,
        helperText: String? = nil,
        itemIndex: Int? = nil,
        totalItems: Int? = nil,
        isCompleted: Bool = false,
        options: [String],
        mode: EncoreDropdownMode,
        initialSelection: Set<Int>,
        placeholder: String = "Select",
        onCommit: @escaping (Set<Int>) -> Void,
        isRequired: Bool
    ) {
        self.title = title
        self.helperText = helperText
        self.itemIndex = itemIndex
        self.totalItems = totalItems
        self.isCompleted = isCompleted
        self.options = options
        self.mode = mode
        self.placeholder = placeholder
        self.onCommit = onCommit
        self.isRequired = isRequired
        self._selection = State(initialValue: initialSelection)
    }

    /// Field summary: the option label for a single pick, else "N selected".
    private var summary: String? {
        let picked = selection.sorted().filter { options.indices.contains($0) }
        switch picked.count {
        case 0: return nil
        case 1: return options[picked[0]]
        default: return "\(picked.count) selected"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired,
                helperText: helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: isCompleted
            )

            EncoreDropdownField(summary: summary, placeholder: placeholder, isOpen: isOpen)
                .onTapGesture { isOpen = true }
                .encoreDropdown(
                    isPresented: $isOpen,
                    options: options,
                    mode: mode,
                    selectedIndices: selection,
                    onCommit: { newSelection in
                        selection = newSelection
                        onCommit(newSelection)
                    }
                )
        }
        .padding(ChecklistItemConstants.itemPadding)
    }
}
