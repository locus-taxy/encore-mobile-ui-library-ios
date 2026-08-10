import SwiftUI

/// Selection semantics for `EncoreDropdown` / `.encoreDropdown`.
public enum EncoreDropdownMode {
    /// One option selectable; tapping a row commits and closes the menu.
    case single
    /// Many options selectable; a "Select all" row + a live "N selected" footer
    /// are shown, and the selection commits when the menu is dismissed.
    case multi
}

// MARK: - Trigger field

/// The closed dropdown field — a bordered box showing the current selection
/// summary (or a placeholder) and a trailing chevron. Use it as the trigger you
/// attach `.encoreDropdown(...)` to, or wire the modifier to any view of your own.
public struct EncoreDropdownField: View {
    let summary: String?
    let placeholder: String
    var isOpen: Bool

    public init(summary: String?, placeholder: String, isOpen: Bool = false) {
        self.summary = summary
        self.placeholder = placeholder
        self.isOpen = isOpen
    }

    private var hasValue: Bool { !(summary ?? "").isEmpty }

    public var body: some View {
        HStack(spacing: 8) {
            Text(hasValue ? summary! : placeholder)
                .typography(Typography.body1)
                .foregroundColor(hasValue ? Color.encore("Text/Primary") : Color.encore("Text/Secondary"))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            EncoreIcon(iconName: "LArrowChevronDown", size: 20)
                .foregroundColor(Color.encore("Text/Secondary"))
                .rotationEffect(.degrees(isOpen ? 180 : 0))
                .animation(.easeInOut(duration: 0.15), value: isOpen)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.encore("Input/OutlinedEnabledBorder"), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Modifier

/// Presents an anchored, scrollable selection menu (the Figma `Device=Mobile`
/// `Menu`) over any view when `isPresented` becomes true.
///
/// The menu is a custom card floated in a transparent `fullScreenCover` so it
/// escapes any enclosing scroll/clip and draws above sibling content. It anchors
/// to the trigger's captured global frame and **flips above the field when there
/// isn't enough room below** (`spaceBelow < menuHeight`). Prefer the
/// `View.encoreDropdown(...)` convenience over instantiating directly.
public struct EncoreDropdownModifier: ViewModifier {
    @Binding var isPresented: Bool
    let options: [String]
    let mode: EncoreDropdownMode
    let selectedIndices: Set<Int>
    let onCommit: (Set<Int>) -> Void

    @State private var anchorFrame: CGRect = .zero
    @State private var draft: Set<Int> = []
    @State private var internalPresented = false
    @State private var visible = false

    private let rowHeight: CGFloat = 48
    private let footerHeight: CGFloat = 36
    private let maxCardHeight: CGFloat = 360
    private let gap: CGFloat = 4
    private let margin: CGFloat = 8

    public func body(content: Content) -> some View {
        content
            .background(anchorReader)
            .fullScreenCover(isPresented: $internalPresented) {
                overlay
                    .modifier(DropdownClearPresentationBackground())
                    .onAppear {
                        draft = selectedIndices
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { visible = true }
                    }
            }
            .onChange(of: isPresented) { open in
                if open {
                    // Suppress the system slide-up cover transition — the card gets
                    // its own fade/scale instead.
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) { internalPresented = true }
                } else {
                    closeAndCommit()
                }
            }
    }

    // MARK: Anchor capture

    private var anchorReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { anchorFrame = proxy.frame(in: .global) }
                .onChange(of: proxy.frame(in: .global)) { anchorFrame = $0 }
        }
    }

    // MARK: Overlay

    private var overlay: some View {
        GeometryReader { screen in
            let m = layout(in: screen.size)
            ZStack(alignment: .topLeading) {
                // Transparent tap-catcher (imperceptible fill so it hit-tests).
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }

                menuCard
                    .frame(width: m.width, height: m.height, alignment: .top)
                    .offset(x: m.x, y: m.y)
                    .opacity(visible ? 1 : 0)
                    .scaleEffect(visible ? 1 : 0.98, anchor: m.flip ? .bottom : .top)
                    .animation(.easeOut(duration: 0.15), value: visible)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: Positioning

    private struct Metrics {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        let flip: Bool
    }

    /// Estimated intrinsic height so the card hugs its content up to the cap.
    private func estimatedHeight() -> CGFloat {
        let rows = CGFloat(options.count) * rowHeight
        let chrome = (mode == .multi) ? (rowHeight + footerHeight + 2) : 0
        return min(maxCardHeight, rows + chrome)
    }

    private func layout(in size: CGSize) -> Metrics {
        let width = anchorFrame.width > 1 ? anchorFrame.width : 280
        let want = estimatedHeight()
        let spaceBelow = size.height - anchorFrame.maxY - gap - margin
        let spaceAbove = anchorFrame.minY - gap - margin
        // Flip above the field when there isn't enough room below and there's
        // more room above.
        let flip = spaceBelow < want && spaceAbove > spaceBelow
        let available = max(flip ? spaceAbove : spaceBelow, rowHeight)
        let height = min(want, available)
        let y = flip ? (anchorFrame.minY - gap - height) : (anchorFrame.maxY + gap)
        let x = min(max(anchorFrame.minX, margin), size.width - width - margin)
        return Metrics(x: x, y: y, width: width, height: height, flip: flip)
    }

    // MARK: Card

    private var menuCard: some View {
        VStack(spacing: 0) {
            if mode == .multi {
                selectAllRow
                divider
            }
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(options.indices, id: \.self) { optionRow($0) }
                }
            }
            if mode == .multi {
                divider
                footer
            }
        }
        .background(Color.encore("Background/Default"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.encore("Divider"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 2)
    }

    private var divider: some View {
        Rectangle().fill(Color.encore("Divider")).frame(height: 1)
    }

    private func optionRow(_ i: Int) -> some View {
        let selected = draft.contains(i)
        return HStack(spacing: 12) {
            if mode == .multi { checkbox(isChecked: selected) }
            Text(options[i])
                .typography(Typography.Menu.itemDefault)
                .foregroundColor(Color.encore("Text/Primary"))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            if mode == .single, selected {
                EncoreIcon(iconName: "LCheck", size: 20)
                    .foregroundColor(Color.encore("Primary/Main"))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: rowHeight)
        // Selected single-choice row: faint primary tint (Figma selected state,
        // node 24720-31315) + the blue tick above.
        .background((mode == .single && selected) ? Color.encore("Primary/Selected") : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { toggle(i) }
    }

    private var selectAllRow: some View {
        HStack(spacing: 12) {
            checkbox(isChecked: allSelected)
            Text("Select all")
                .typography(Typography.Menu.itemDefault)
                .foregroundColor(Color.encore("Text/Primary"))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(height: rowHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            if allSelected { draft.removeAll() } else { draft = Set(options.indices) }
        }
    }

    private var footer: some View {
        HStack {
            Spacer(minLength: 0)
            Text("\(draft.count) of \(options.count) selected")
                .typography(Typography.caption)
                .foregroundColor(Color.encore("Text/Secondary"))
        }
        .padding(.horizontal, 16)
        .frame(height: footerHeight)
    }

    private func checkbox(isChecked: Bool) -> some View {
        ZStack {
            if isChecked {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.encore("Primary/Main"))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    )
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(Color.encore("Text/Secondary"), lineWidth: 1.67)
                    .frame(width: 18, height: 18)
            }
        }
        .frame(width: 24, height: 24)
    }

    // MARK: Selection

    private var allSelected: Bool { !options.isEmpty && draft.count == options.count }

    private func toggle(_ i: Int) {
        if mode == .single {
            draft = [i]
            isPresented = false // dismiss → commit
        } else if draft.contains(i) {
            draft.remove(i)
        } else {
            draft.insert(i)
        }
    }

    // MARK: Dismiss

    private func closeAndCommit() {
        visible = false
        onCommit(draft)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { internalPresented = false }
    }
}

// MARK: - Transparent presentation background

/// Makes the `fullScreenCover` platter transparent so only the anchored card and
/// its (clear) tap-catcher are visible.
private struct DropdownClearPresentationBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationBackground(.clear)
        } else {
            content.background(DropdownTransparentBackground())
        }
    }
}

/// Pre-16.4 fallback: clears the presented container's background.
private struct DropdownTransparentBackground: UIViewRepresentable {
    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async { view.superview?.superview?.backgroundColor = .clear }
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}
}

// MARK: - Convenience

public extension View {
    /// Presents an anchored selection menu over this view when `isPresented`
    /// becomes true — the ">5 options" dropdown for single- and multi-choice.
    ///
    /// - Parameters:
    ///   - isPresented: Drives presentation. Set true (e.g. on the field's tap) to open.
    ///   - options: The option labels, in order. Indices are stable and are what
    ///     `selectedIndices` / `onCommit` speak in — the caller maps them to codes.
    ///   - mode: `.single` (tap-to-commit-and-close) or `.multi` (Select all + footer,
    ///     commits on dismiss).
    ///   - selectedIndices: The currently-selected option indices, used to seed the
    ///     menu when it opens.
    ///   - onCommit: Called with the final selected indices when the menu closes.
    func encoreDropdown(
        isPresented: Binding<Bool>,
        options: [String],
        mode: EncoreDropdownMode,
        selectedIndices: Set<Int>,
        onCommit: @escaping (Set<Int>) -> Void
    ) -> some View {
        modifier(EncoreDropdownModifier(
            isPresented: isPresented,
            options: options,
            mode: mode,
            selectedIndices: selectedIndices,
            onCommit: onCommit
        ))
    }
}
