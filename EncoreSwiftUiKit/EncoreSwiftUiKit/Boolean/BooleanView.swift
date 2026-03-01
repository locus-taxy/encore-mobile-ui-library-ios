import SwiftUI

/// Reusable boolean checkbox view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `BooleanView` composable.
public struct BooleanView: View {
    let checked: Bool
    let onCheckedChange: (Bool) -> Void
    var title: String?

    public init(
        checked: Bool,
        onCheckedChange: @escaping (Bool) -> Void,
        title: String? = nil
    ) {
        self.checked = checked
        self.onCheckedChange = onCheckedChange
        self.title = title
    }

    public var body: some View {
        Toggle(isOn: Binding(
            get: { checked },
            set: { onCheckedChange($0) }
        )) {
            if let title = title {
                Text(title)
                    .font(.system(size: ChecklistItemConstants.titleFontSize, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .toggleStyle(ChecklistToggleStyle())
    }
}

