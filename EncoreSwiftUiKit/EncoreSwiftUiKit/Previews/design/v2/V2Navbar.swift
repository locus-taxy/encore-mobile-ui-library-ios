import SwiftUI

// MARK: - Navbar — node 11075:762666
//
// One bar for every surface. The three bars this replaces each typed their own icon size, colour and
// padding, which is why the chrome drifted between the trip page, the stop sheet and the workflow
// cover. Everything measurable is here; surfaces only say WHICH actions they carry.
//
// Read straight off the node:
//   container   64 tall — 8 top/bottom around a 48pt button row; bg `background/default`
//   side inset  4 where a button sits on that side, 16 where none does (a button's own 12pt
//               padding supplies the rest of the optical inset — that is why it is not 16 both sides)
//   gap         8 between the back button and the title; 4 between trailing buttons
//   button      48 × 48, fully rounded, 12pt padding around a 24pt icon
//   icon        24, `action/active` #666666 — including ✕, which is not darker than its siblings
//   title       `typography/label0` — Inter **Medium** 16/24, `text/primary` #141414

struct V2NavAction: Identifiable {
    let id: String
    var icon: String
    /// Held "pressed" while the thing it opened is showing — the ⋮ behind its menu (frame 21).
    var selected: Bool = false
    var action: () -> Void = {}
}

struct V2Navbar: View {
    /// Present ⇒ a leading back chevron, and the leading inset drops to 4.
    var back: (() -> Void)? = nil
    /// The leading control's glyph — ✕ in multi-select (frame 30) instead of the back chevron.
    var backIcon: String = "LChevronLeft"
    var title: String
    /// The workflow cover names the entity it is working on under the title.
    var subtitle: String? = nil
    var actions: [V2NavAction] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: V2Space.chipGap) {
                if let back {
                    button(icon: backIcon, action: back)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .v2Label(V2Font.navTitle)
                        .foregroundColor(HFColor.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .v2Label(V2Font.label2)
                            .foregroundColor(HFColor.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !actions.isEmpty {
                    HStack(spacing: V2Space.tagGap) {
                        ForEach(actions) { a in
                            button(icon: a.icon, selected: a.selected, action: a.action)
                        }
                    }
                }
            }
            .frame(height: V2Metrics.touchTarget)
            .padding(.leading, back == nil ? V2Space.headerInset : V2Space.navbarInset)
            .padding(.trailing, actions.isEmpty ? V2Space.headerInset : V2Space.navbarInset)
            .padding(.vertical, V2Space.chipGap)

            HFSeam()      // the grey page background, not a #C2C2C2 rule (frames 12, 17)
        }
        .background(HFColor.surface)
    }

    private func button(icon: String, selected: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            EncoreIcon(iconName: icon, size: V2Icon.bar)
                .foregroundColor(V2Token.actionActive)
                .frame(width: V2Metrics.touchTarget, height: V2Metrics.touchTarget)
                .background(Circle().fill(selected ? HFColor.screen : .clear))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Per-surface policies
//
// These are NOT alternative bars — they all render `V2Navbar`. What each one owns is the rule about
// which actions that surface carries, written once so the rule can't be forgotten per screen.

/// List page. Filter + search appear only past the P0.10 threshold (dev note 9166:350818).
struct V2ListBar: View {
    let title: String
    var itemCount: Int = 0
    var onBack: (() -> Void)? = nil
    var onFilter: () -> Void = {}
    var onSearch: () -> Void = {}

    var body: some View {
        V2Navbar(back: onBack,
                 title: title,
                 actions: V2ListAffordance.showsSearchAndFilter(rowCount: itemCount)
                    ? [V2NavAction(id: "filter", icon: "LFilterAlt", action: onFilter),
                       V2NavAction(id: "search", icon: "LSearch", action: onSearch)]
                    : [])
    }
}

/// Stop / task sheet. Back appears only on the task surface (frame 120); the stop surface has ✕ only
/// (frame 119). The kebab is the undo-arrival menu and shows only where the engine allows the undo.
struct V2SheetBar: View {
    let title: String
    var showBack: Bool = false
    var showKebab: Bool = false
    var kebabSelected: Bool = false
    var showSearch: Bool = false
    var onBack: () -> Void = {}
    var onKebab: () -> Void = {}
    var onClose: () -> Void = {}

    var body: some View {
        var actions: [V2NavAction] = []
        if showSearch { actions.append(V2NavAction(id: "search", icon: "LSearch")) }
        if showKebab  { actions.append(V2NavAction(id: "kebab", icon: "LOverflowVertical",
                                                    selected: kebabSelected, action: onKebab)) }
        actions.append(V2NavAction(id: "close", icon: "LCross", action: onClose))

        return V2Navbar(back: showBack ? onBack : nil, title: title, actions: actions)
            .modifier(V2SheetGrab())
    }
}

/// The sheet's bar is its grab region: a downward drag here moves the sheet, and past the threshold
/// dismisses it. Only the bar — a drag anywhere else belongs to the list inside and must scroll it.
/// The layer hands its drag handlers down through the environment; outside a sheet this is a no-op.
private struct V2SheetGrab: ViewModifier {
    @Environment(\.v2SheetDrag) private var drag
    func body(content: Content) -> some View {
        if let drag {
            content
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 8, coordinateSpace: .global)
                        .onChanged { drag.changed($0.translation.height) }
                        .onEnded { drag.ended($0.translation.height) }
                )
        } else {
            content
        }
    }
}

struct V2SheetDragHandlers {
    var changed: (CGFloat) -> Void
    var ended: (CGFloat) -> Void
}

private struct V2SheetDragKey: EnvironmentKey {
    static let defaultValue: V2SheetDragHandlers? = nil
}

extension EnvironmentValues {
    var v2SheetDrag: V2SheetDragHandlers? {
        get { self[V2SheetDragKey.self] }
        set { self[V2SheetDragKey.self] = newValue }
    }
}
