import SwiftUI

public enum EmptyStateContent {
    case loading(title: String)
    case empty(title: String, subtitle: String?, actionLabel: String?, action: (() -> Void)?)
}

public struct EmptyStateView: View {
    public let content: EmptyStateContent

    public init(content: EmptyStateContent) {
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .center, spacing: Spacing.spacing16) {
            switch content {
            case let .loading(title):
                loadingBody(title: title)
            case let .empty(title, subtitle, actionLabel, action):
                emptyBody(title: title, subtitle: subtitle, actionLabel: actionLabel, action: action)
            }
        }
        .padding(Spacing.spacing40)
        .frame(maxWidth: .infinity)
        .frame(height: 435)
        .background(Color.encore("Background/Default"))
    }

    @ViewBuilder
    private func loadingBody(title: String) -> some View {
        CircularProgressView(size: .xlarge)
            .padding(Spacing.spacing16)
        Text(title)
            .typography(Typography.h5)
            .foregroundColor(Color.encore("Text/Primary"))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func emptyBody(
        title: String,
        subtitle: String?,
        actionLabel: String?,
        action: (() -> Void)?
    ) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.encore("Action/Hover"))
            .frame(width: Spacing.spacing96, height: Spacing.spacing96)

        VStack(alignment: .center, spacing: Spacing.spacing12) {
            VStack(alignment: .center, spacing: Spacing.spacing4) {
                Text(title)
                    .typography(Typography.h5)
                    .foregroundColor(Color.encore("Text/Primary"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                if let subtitle {
                    Text(subtitle)
                        .typography(Typography.body0)
                        .foregroundColor(Color.encore("Text/Secondary"))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            if let actionLabel, let action {
                EncoreButton(label: actionLabel, variant: .outlined, action: action)
            }
        }
        .frame(maxWidth: 400)
    }
}
