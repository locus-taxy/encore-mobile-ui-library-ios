import SwiftUI

/// URL checklist item with clickable link matching Figma design specifications.
/// Composes ChecklistHeader + UrlView.
/// Mirrors Android's `UrlCheckListItem` composable.
public struct UrlCheckListItem: View {
    let title: String
    var helperText: String? = nil
    var itemIndex: Int? = nil
    var totalItems: Int? = nil
    var isCompleted: Bool = false
    let url: String
    var onUrlClick: (() -> Void)?
    let isRequired: Bool

    public init(
        title: String,
        helperText: String? = nil,
        itemIndex: Int? = nil,
        totalItems: Int? = nil,
        isCompleted: Bool = false,
        url: String,
        onUrlClick: (() -> Void)? = nil,
        isRequired: Bool
    ) {
        self.title = title
        self.helperText = helperText
        self.itemIndex = itemIndex
        self.totalItems = totalItems
        self.isCompleted = isCompleted
        self.url = url
        self.onUrlClick = onUrlClick
        self.isRequired = isRequired
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired && url.isEmpty,
                helperText: helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: isCompleted
            )

            UrlView(
                url: url,
                onUrlClick: onUrlClick
            )
            .padding(.top, ChecklistItemConstants.innerTopPadding)
        }
        .padding(ChecklistItemConstants.itemPadding)
    }
}
