import SwiftUI

// MARK: - Shared V2 controls
//
// The pieces every surface past the trip flow reaches for — login, home, profile, trip end. Same rule
// as V2Style: call sites pass content, never metrics.

/// A full-width button. Figma `<Button>`: r4; 48 tall in a sheet / footer (`xlarge`), 40 inside a
/// card (`large`, frame 07's Clock in) — the 40 still sits in a 48 touch target.
struct V2Button: View {
    enum Role { case primary, danger, text, success }
    enum Size { case regular, compact }

    let label: String
    var role: Role = .primary
    var size: Size = .regular
    var enabled: Bool = true
    var leadingIcon: String? = nil
    var trailingIcon: String? = nil
    /// Hug the label instead of filling the width (frame 30's `Mark scanned`).
    var hug: Bool = false
    var action: () -> Void = {}

    private var fill: Color {
        guard enabled else { return role == .text ? .clear : HFColor.disabledBg }
        switch role {
        case .primary: return HFColor.primary
        case .danger:  return Color.encore("Error/Main")
        case .success: return HFColor.success
        case .text:    return .clear
        }
    }

    private var ink: Color {
        guard enabled else { return HFColor.textDisabled }
        return role == .text ? V2Token.actionActive : HFColor.onPrimary
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                if let leadingIcon {
                    EncoreIcon(iconName: leadingIcon, size: V2Icon.footerGlyph)
                }
                Text(label)
                    .v2Label(V2Font.buttonLarge)
                    .padding(.horizontal, size == .regular ? Spacing.spacing8 : 6)
                if let trailingIcon {
                    EncoreIcon(iconName: trailingIcon, size: V2Icon.footerGlyph)
                }
            }
            .foregroundColor(ink)
            .padding(.horizontal, size == .regular ? Spacing.spacing16 : Spacing.spacing12)
            .frame(maxWidth: hug ? nil : .infinity)
            .frame(height: size == .regular ? V2Metrics.footerButton : 40)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: V2Metrics.footerRadius))
            .frame(height: V2Metrics.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // not .disabled: a disabled .plain Button is dimmed again by the system, on top of the
        // token colours it already draws (#E0E0E0 / #C2C2C2 read as ~#EFEFEF / #D8D8D8).
        .allowsHitTesting(enabled)
    }
}

/// Outlined text field — Figma `<TextField>` Size=Medium (frames 02–05).
///
/// Not `LTextField`: there the label recolours with state and success draws a green border plus a
/// clear button. Figma keeps the label `Text/Primary` in every state, keeps the 2pt focus border
/// while validating / valid, and shows the state as a trailing 24pt adornment instead.
struct V2TextField: View {
    enum Adornment { case none, validating, valid }

    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var secure: Bool = false
    var adornment: Adornment = .none

    @FocusState private var focused: Bool

    private static let enabledBorder = Color.encore("Input/OutlinedEnabledBorder")

    private var active: Bool { focused || adornment != .none }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing4) {
            Text(label)
                .v2Label(V2Font.inputLabel)
                .foregroundColor(HFColor.textPrimary)
            HStack(spacing: Spacing.spacing8) {
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .v2Label(V2Font.inputValue)
                            .foregroundColor(HFColor.textDisabled)
                    }
                    Group {
                        if secure { SecureField("", text: $text) } else { TextField("", text: $text) }
                    }
                    .font(V2Font.inputValue.font)
                    .foregroundColor(HFColor.textPrimary)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($focused)
                }
                .frame(maxWidth: .infinity)
                adornmentView
                    .frame(width: adornment == .none ? 0 : V2Metrics.touchTarget,
                           height: V2Metrics.touchTarget)
            }
            .padding(.leading, Spacing.spacing16)
            .frame(height: V2Metrics.touchTarget)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(active ? HFColor.primary : Self.enabledBorder, lineWidth: active ? 2 : 1)
            )
            .contentShape(Rectangle())
            .onTapGesture { focused = true }
        }
    }

    @ViewBuilder private var adornmentView: some View {
        switch adornment {
        case .none:       EmptyView()
        case .validating: V2Ring(progress: nil, size: 24, stroke: 2.5)
        case .valid:
            EncoreIcon(iconName: "LCheckCircleFilled", size: 24)
                .foregroundColor(HFColor.success)
        }
    }
}

/// Progress ring. Determinate shows the percentage inside (frames 06 / 36: 64pt, ~4pt primary arc,
/// no track); indeterminate spins (the validating field, frame 04).
struct V2Ring: View {
    /// 0…1, or nil to spin.
    let progress: CGFloat?
    var size: CGFloat = 64
    var stroke: CGFloat = 4
    var showsPercent: Bool = false

    @State private var spin = false

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: progress ?? 0.28)
                .stroke(HFColor.primary, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(progress == nil ? (spin ? 270 : -90) : -90))
                .animation(progress == nil
                           ? .linear(duration: 0.9).repeatForever(autoreverses: false)
                           : .easeOut(duration: 0.2),
                           value: progress == nil ? (spin ? 1 : 0) : progress ?? 0)
            if showsPercent, let progress {
                Text("\(Int((progress * 100).rounded()))%")
                    .v2Label(V2Font.body2)
                    .foregroundColor(HFColor.textSecondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear { if progress == nil { spin = true } }
    }
}

/// Full-screen progress interstitial — "Loading the app…" (06) and "Loading the trip…" (36, 54, 72,
/// 89, 103). Grey page, no chrome, the ring counting up, then `onDone`.
struct V2LoadingPage: View {
    let copy: String
    var duration: Double = 1.2
    var onDone: () -> Void = {}

    @State private var progress: CGFloat = 0

    var body: some View {
        VStack(spacing: Spacing.spacing16) {
            V2Ring(progress: progress, showsPercent: true)
                .padding(Spacing.spacing16)
            Text(copy)
                .v2Label(V2Font.navTitle)
                .foregroundColor(.black)                  // Figma: raw #000, not text/primary
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HFColor.screen.ignoresSafeArea())
        .onAppear(perform: run)
    }

    private func run() {
        let steps = 20
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration * Double(i) / Double(steps)) {
                progress = CGFloat(i) / CGFloat(steps)
                if i == steps {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { onDone() }
                }
            }
        }
    }
}

// MARK: - Summary sheet
//
// View details (13), Trip summary (109) and Clock-out summary (114) are ONE anatomy: a title bar,
// then white sections stacked on the grey sheet with 1px seams, each an optional heading over a grid,
// and an optional pinned footer.

struct V2SummarySection: Identifiable {
    let id: String
    var heading: String? = nil
    /// The lead section of a summary is headed in h6 (109, 114); later ones in label1.
    var leadHeading: Bool = false
    /// A status chip above the lead heading (109's `Completed`).
    var chip: V2ChipSlot? = nil
    var columns: Int
    var pairs: [V2Pair]
}

struct V2SummarySheet<Footer: View>: View {
    let title: String
    let sections: [V2SummarySection]
    var onClose: () -> Void = {}
    /// The tallest the sheet may grow (109: top 42 below the status bar). The sheet hugs its content
    /// and only scrolls, between the pinned title and footer, once the content would pass this. A
    /// fixed height padded short content with dead grey under the last section. Nil: always hug.
    var height: CGFloat? = nil
    @ViewBuilder var footer: Footer

    @State private var contentHeight: CGFloat = 0
    @State private var chromeHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            HFSheetTitle(title: title, onClose: onClose)
                .background(HFColor.surface)
                .background(measure(into: \.title))
            if let height {
                ScrollView {
                    body(sections)
                        .background(GeometryReader { g in
                            Color.clear.preference(key: V2SheetContentHeight.self, value: g.size.height)
                        })
                }
                .frame(height: min(contentHeight, max(0, height - chromeHeight)))
                .onPreferenceChange(V2SheetContentHeight.self) { contentHeight = $0 }
            } else {
                body(sections)
            }
            footer
                .background(measure(into: \.footer))
        }
        .onPreferenceChange(V2SheetChromeHeight.self) { chromeHeight = $0.title + $0.footer }
        .background(HFColor.screen)
    }

    private func measure(into part: WritableKeyPath<V2SheetChrome, CGFloat>) -> some View {
        GeometryReader { g in
            Color.clear.preference(key: V2SheetChromeHeight.self,
                                   value: { var c = V2SheetChrome(); c[keyPath: part] = g.size.height; return c }())
        }
    }

    private func body(_ sections: [V2SummarySection]) -> some View {
        VStack(spacing: V2Space.sectionSeam) {
            ForEach(sections) { section($0) }
        }
        .padding(.top, V2Space.sectionSeam)              // the 1px seam under the title (109, 114)
        .background(HFColor.screen)
    }

    private func section(_ s: V2SummarySection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let chip = s.chip {
                chip.view
                    .frame(height: V2Metrics.chip)
                    .padding(.bottom, Spacing.spacing12)      // frame 109: gap 12 to the heading
            }
            if let heading = s.heading {
                Text(heading)
                    .v2Text(s.leadHeading ? V2Font.sheetHeadline : V2Font.label1)
                    .foregroundColor(HFColor.textPrimary)
                    .padding(.bottom, V2Space.headingToGrid)
            }
            V2GridView(slot: V2GridSlot(columns: s.columns, pairs: s.pairs))
        }
        .padding(.horizontal, V2Space.headerInset)
        .padding(.top, V2Space.detailsSectionTop)
        .padding(.bottom, V2Space.detailsSectionBottom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.surface)
    }
}

private struct V2SheetContentHeight: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct V2SheetChrome: Equatable { var title: CGFloat = 0; var footer: CGFloat = 0 }

private struct V2SheetChromeHeight: PreferenceKey {
    static var defaultValue = V2SheetChrome()
    static func reduce(value: inout V2SheetChrome, nextValue: () -> V2SheetChrome) {
        let n = nextValue()
        value.title = max(value.title, n.title)
        value.footer = max(value.footer, n.footer)
    }
}

extension V2SummarySheet where Footer == HFSheetBottomInset {
    /// No footer: the sheet pads for the home indicator itself.
    init(title: String, sections: [V2SummarySection], onClose: @escaping () -> Void = {}) {
        self.init(title: title, sections: sections, onClose: onClose) { HFSheetBottomInset() }
    }
}

// MARK: - Popover menu (frame 21)

/// A menu card hanging off a bar control: 160 wide, r12, white, E1, 4 inside top/bottom; items
/// 16 × 12 with an optional caption line. No scrim — tapping anywhere else closes it.
struct V2MenuItem: Identifiable {
    let id: String
    var title: String
    var caption: String? = nil
    var captionTint: Color = HFColor.textSecondary
    var action: () -> Void
}

struct V2PopoverMenu: View {
    let items: [V2MenuItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                Button(action: item.action) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.title)
                            .v2Label(V2Font.menuItem)
                            .foregroundColor(HFColor.textPrimary)
                        if let caption = item.caption {
                            Text(caption)
                                .v2Label(V2Font.body2)
                                .foregroundColor(item.captionTint)
                        }
                    }
                    .padding(.horizontal, Spacing.spacing16)
                    .padding(.vertical, Spacing.spacing12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Spacing.spacing4)
        .frame(width: 160)
        .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
        .shadow(color: Color(.sRGB, red: 17/255, green: 19/255, blue: 24/255, opacity: 0.16), radius: 2)
    }
}

// MARK: - Compact list header + row (Profile, frame 116)

/// 34-tall section label — the compact sibling of `V2SectionHeader` (44) used on settings-style lists.
struct V2CompactSectionHeader: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .v2Label(V2Font.overline2)
            .foregroundColor(HFColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, V2Space.pageMargin)
            .padding(.vertical, Spacing.spacing8)
    }
}

/// 64-tall navigation row: label1 title, trailing chevron in a 64 × 48 button.
struct V2NavRow: View {
    let title: String
    var tint: Color = HFColor.textPrimary
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.spacing16) {
                Text(title)
                    .v2Label(V2Font.label1)
                    .foregroundColor(tint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                EncoreIcon(iconName: "LChevronRight", size: V2Icon.chevron)
                    .foregroundColor(V2Token.actionActive)
                    .frame(width: 64, height: V2Metrics.touchTarget)
            }
            .padding(.leading, V2Space.pageMargin)
            .padding(.trailing, Spacing.spacing4)
            .frame(height: 64)
            .background(HFColor.surface)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab bar (frames 07, 112)

enum V2AppTab: Int { case home, hubOps, delivery }

/// Bottom navigation. Active = filled icon + Primary/Main + `navActive` 14/20; inactive = outlined
/// icon + #666 + body2 12/18. 64 tall (py4 + 56), E1 above, home-indicator inset below.
struct V2TabBar: View {
    let active: V2AppTab
    var onSelect: (V2AppTab) -> Void = { _ in }

    private let items: [(tab: V2AppTab, filled: String, outlined: String, label: String)] = [
        (.home, "LHomeFilled", "LHomeOutlined", "Home"),
        (.hubOps, "LWarehouseFilled", "LWarehouseOutlined", "Hub ops"),
        (.delivery, "LLocalShippingFilled", "LLocalShipping", "Delivery"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.label) { item in
                let on = item.tab == active
                Button { onSelect(item.tab) } label: {
                    VStack(spacing: 0) {
                        EncoreIcon(iconName: on ? item.filled : item.outlined, size: 24)
                            .foregroundColor(on ? HFColor.primary : V2Token.actionActive)
                        Text(item.label)
                            .v2Label(on ? V2Font.navActive : V2Font.body2)
                            .foregroundColor(on ? HFColor.primary : HFColor.textSecondary)
                            .frame(height: 16)                // Figma label wrapper (frame 07)
                    }
                    // Icon 7 below the action's top, label wrapper directly under it — 6 + 24 + 20 + 8
                    // overflowed the 56 row and pushed the icon up.
                    .padding(.top, 7)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56, alignment: .top)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, Spacing.spacing4)
        .padding(.bottom, HFLayout.barBottom(Spacing.spacing4))
        .background(
            Rectangle()
                .fill(HFColor.surface)
                .shadow(color: Color(.sRGB, red: 17/255, green: 19/255, blue: 24/255, opacity: 0.16), radius: 2)
        )
    }
}

/// Home / Delivery app bar: title, optional shift subtitle (Delivery only, frame 112), avatar.
struct V2AppBar: View {
    let title: String
    var subtitle: String? = nil
    /// Trailing inset: 16 on Home (07), 12 on Delivery (112) — the two app bars differ in Figma.
    var trailingInset: CGFloat = Spacing.spacing12
    var onAvatar: () -> Void = {}
    @Environment(\.v2InboxEntry) private var inbox

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.spacing4) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .v2Label(V2Font.navTitle)
                        .foregroundColor(HFColor.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .v2Label(V2Font.label2)
                            .foregroundColor(HFColor.successDark)
                    }
                }
                Spacer()
                if let inbox {
                    V2BellButton(unread: inbox.unread, action: inbox.open)
                }
                Button(action: onAvatar) { HFAvatar() }
                    .buttonStyle(.plain)
            }
            .padding(.leading, V2Space.pageMargin)
            .padding(.trailing, trailingInset)
            .frame(height: V2Metrics.touchTarget)
            .padding(.vertical, Spacing.spacing8)
            HFSeam()
            V2BannerSlot()
        }
        .background(HFColor.surface)
    }
}
