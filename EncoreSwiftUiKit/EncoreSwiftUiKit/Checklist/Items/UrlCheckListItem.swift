import SwiftUI

/// URL checklist item with clickable link matching Figma design specifications.
/// Composes ChecklistHeader + UrlView.
/// Mirrors Android's `UrlCheckListItem` composable.
public struct UrlCheckListItem: View {
    let title: String
    let url: String
    var onUrlClick: (() -> Void)?
    let isRequired: Bool

    public init(
        title: String,
        url: String,
        onUrlClick: (() -> Void)? = nil,
        isRequired: Bool
    ) {
        self.title = title
        self.url = url
        self.onUrlClick = onUrlClick
        self.isRequired = isRequired
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired && url.isEmpty
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

