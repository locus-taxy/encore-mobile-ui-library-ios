import SwiftUI

/// Boolean checklist item with checkbox matching Figma design specifications.
/// Composes ChecklistHeader + BooleanView.
/// Mirrors Android's `BooleanCheckListItem` composable.
public struct BooleanCheckListItem: View {
    let title: String
    var helperText: String? = nil
    var itemIndex: Int? = nil
    var totalItems: Int? = nil
    var isCompleted: Bool = false
    let initialChecked: Bool
    let onCheckedChange: (Bool) -> Void
    let isRequired: Bool

    @State private var checked: Bool

    public init(
        title: String,
        helperText: String? = nil,
        itemIndex: Int? = nil,
        totalItems: Int? = nil,
        isCompleted: Bool = false,
        initialChecked: Bool,
        onCheckedChange: @escaping (Bool) -> Void,
        isRequired: Bool
    ) {
        self.title = title
        self.helperText = helperText
        self.itemIndex = itemIndex
        self.totalItems = totalItems
        self.isCompleted = isCompleted
        self.initialChecked = initialChecked
        self.onCheckedChange = onCheckedChange
        self.isRequired = isRequired
        self._checked = State(initialValue: initialChecked)
    }

    public var body: some View {
        HStack(alignment: .center) {
            BooleanView(
                checked: checked,
                onCheckedChange: { newChecked in
                    checked = newChecked
                    onCheckedChange(newChecked)
                }
            )

            ChecklistHeader(
                title: title,
                isRequired: isRequired,
                helperText: helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: isCompleted
            )
        }
        .padding(EdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 15))
        .onChange(of: initialChecked) { newValue in
            checked = newValue
        }
    }
}
