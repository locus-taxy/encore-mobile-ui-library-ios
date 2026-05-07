import SwiftUI

public enum EncoreSwitchSize {
    case medium, small
}

public struct EncoreSwitchStyle: ToggleStyle {
    let size: EncoreSwitchSize
    let isDisabled: Bool

    private var pillWidth: CGFloat {
        size == .medium ? 34 : 26
    }

    private var pillHeight: CGFloat {
        size == .medium ? 14 : 10
    }

    private var slidePadding: CGFloat {
        size == .medium ? Spacing.spacing12 : CGFloat(7)
    }

    private var knobOffset: CGFloat {
        size == .medium ? Spacing.spacing20 : Spacing.spacing16
    }

    public func makeBody(configuration: Configuration) -> some View {
        let knobDiameter = pillHeight
        return Button {
            guard !isDisabled else { return }
            withAnimation(.spring()) { configuration.isOn.toggle() }
        } label: {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: pillHeight / 2)
                    .fill(slideColor(isOn: configuration.isOn))
                    .opacity(slideOpacity(isOn: configuration.isOn))
                    .frame(width: pillWidth, height: pillHeight)
                Circle()
                    .fill(Color.encore("Switch/KnobFillEnabled"))
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .frame(width: knobDiameter, height: knobDiameter)
                    .offset(x: configuration.isOn ? knobOffset : 0)
            }
            .padding(slidePadding)
        }
        .buttonStyle(.plain)
        .frame(minWidth: Spacing.spacing48, minHeight: Spacing.spacing48)
    }

    private func slideColor(isOn: Bool) -> Color {
        if isDisabled { return Color.encore("Action/DisabledBackground") }
        return isOn ? Color.encore("Primary/Main") : Color.encore("Switch/SlideFill")
    }

    private func slideOpacity(isOn: Bool) -> Double {
        if isDisabled { return 1.0 }
        return isOn ? 0.5 : 0.38
    }
}

public struct EncoreSwitch: View {
    public let isOn: Bool
    public let onToggle: (Bool) -> Void
    public let size: EncoreSwitchSize
    public let isDisabled: Bool

    public init(
        isOn: Bool,
        onToggle: @escaping (Bool) -> Void,
        size: EncoreSwitchSize = .medium,
        isDisabled: Bool = false
    ) {
        self.isOn = isOn
        self.onToggle = onToggle
        self.size = size
        self.isDisabled = isDisabled
    }

    public var body: some View {
        Toggle(isOn: Binding(get: { isOn }, set: { onToggle($0) })) { EmptyView() }
            .labelsHidden()
            .toggleStyle(EncoreSwitchStyle(size: size, isDisabled: isDisabled))
    }
}
