import SwiftUI

#Preview("EmptyStateViewPreview") {
    HStack {
        EmptyStateView(content: .loading(title: "Loading..."))
        EmptyStateView(content: .empty(title: "Single line heading",
                                       subtitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                                       actionLabel: "Action",
                                       action: {}))
    }
    .preferredColorScheme(.light)
}
