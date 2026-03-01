import SwiftUI

/// Reusable URL display view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `UrlView` composable.
public struct UrlView: View {
    let url: String
    var onUrlClick: (() -> Void)?

    public init(url: String, onUrlClick: (() -> Void)? = nil) {
        self.url = url
        self.onUrlClick = onUrlClick
    }

    public var body: some View {
        if !url.isEmpty {
            Button {
                if let onUrlClick = onUrlClick {
                    onUrlClick()
                } else if let linkURL = URL(string: url) {
                    UIApplication.shared.open(linkURL)
                }
            } label: {
                Text(url)
                    .font(.system(size: ChecklistItemConstants.urlTextFontSize))
                    .foregroundColor(.accentColor)
                    .underline()
                    .lineSpacing(ChecklistItemConstants.urlTextLineHeight - ChecklistItemConstants.urlTextFontSize)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }
}

