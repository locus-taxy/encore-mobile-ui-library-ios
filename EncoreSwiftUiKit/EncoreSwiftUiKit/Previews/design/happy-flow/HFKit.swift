import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// Happy Flow — shared kit. Design-system-linked: colours via Color.encore(…), type via Typography,
// spacing via Spacing, icons via EncoreIcon. Screens compose these; HFRouter maps a number → screen.
// Patterns per ui-patterns.md / ui-decisions.md (full-page details, swipe-to-confirm, affordance,
// alert placement, 48pt targets, chip shapes).

enum HFColor {
    static let primary = Color.encore("Primary/Main")
    static let onPrimary = Color.encore("Primary/ContrastText")
    static let textPrimary = Color.encore("Text/Primary")
    static let textSecondary = Color.encore("Text/Secondary")
    static let textDisabled = Color.encore("Text/Disabled")
    static let surface = Color.encore("Background/Default")
    static let screen = Color.encore("Background/ColumnHeading")
    static let divider = Color.encore("Divider")
    static let success = Color.encore("Success/Main")
    static let successDark = Color.encore("Success/Dark")
    static let toast = Color.encore("Action/Active")
    static let infoText = Color.encore("Info/Dark")
    static let infoBg = Color.encore("Info/Main").opacity(0.08)
    static let purpleText = Color.encore("Secondary/Dark")
    static let purpleBg = Color.encore("Secondary/Main").opacity(0.08)
    static let disabledBg = Color.encore("Action/DisabledBackground")
    /// Light-blue hairline used as the primary-tint pill / focus border (Figma primary/_states/focusVisible).
    static let pillBorder = Color(.sRGB, red: 200/255, green: 220/255, blue: 255/255, opacity: 1) // #C8DCFF
    /// Offline status strip (Figma warning/main).
    static let warning = Color(.sRGB, red: 230/255, green: 83/255, blue: 1/255, opacity: 1) // #E65301
}

// MARK: - Layout rules shared by every surface

enum HFLayout {
    /// The device's home-indicator inset. Bottom bars (tab bar, sticky footer) are drawn full-bleed,
    /// so they add this themselves: Figma's bottom padding, but never less than this inset.
    static var bottomInset: CGFloat {
        #if canImport(UIKit)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .safeAreaInsets.bottom ?? 0
        #else
        return 0
        #endif
    }

    /// Bottom padding for a bar whose Figma padding is `figma`.
    static func barBottom(_ figma: CGFloat) -> CGFloat { max(figma, bottomInset) }
}

/// The 1px seam between a bar and the content under it, and between stacked white sections. It is
/// the grey page background showing through (`background/columnHeading`), not a drawn #C2C2C2 rule.
struct HFSeam: View {
    var body: some View {
        Rectangle().fill(HFColor.screen).frame(height: 1)
    }
}

// MARK: - Local type styles (Figma-exact; library tokens differ)

enum HFType {
    /// `chip/labelSmall` — identifier / task-type pills. Inter Medium 12 / tracking 0.16.
    /// The library `Typography.Chip.labelSmall` is 13px, so this pins the Figma-exact 12px.
    static let chip12 = TypographyStyle(font: Font.custom("Inter18pt-Medium", size: 12), tracking: 0.16)
    /// `badge/label` — STATUS chips only. Inter Medium 12 / tracking **0.14** — a different token from
    /// `chip/labelSmall`'s 0.16 (and the library `Typography.Status.label`, which is 0.4).
    static let badge12 = TypographyStyle(font: Font.custom("Inter18pt-Medium", size: 12), tracking: 0.14)
}

// MARK: - Chips

/// Status chip = small-radius rounded rectangle: filled colour + label. Pinned to the Figma
/// `badge/label` token — r4, padding h4/v2, which renders the ~50×20 chip the component set measures.
struct HFStatusChip: View {
    let text: String
    var fill: Color = HFColor.primary
    /// Label colour. Defaults to white; amber fills (stop/task `Partial`) pass a dark label because
    /// `Yellow/400` cannot carry white text.
    var label: Color = HFColor.onPrimary
    var body: some View {
        Text(text)
            .typography(HFType.badge12)
            .foregroundColor(label)
            // Figma: 2 on the chip + 4 on the label box = 6 either side; pinned 20 tall, min 48 wide.
            .padding(.horizontal, 6)
            .frame(minWidth: 48)
            .frame(height: 20)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

/// Pickup vs Delivery share ONE base glyph (Material `ArrowDropDownCircle`): deliver points
/// down (as-is), pickup is the same glyph rotated 180° (up). `.none` keeps the legacy flat dot.
enum HFChipGlyph { case none, deliver, pickup, handback }

/// Identifier / count chip = pill with an 8%-tint bg + dark text (per ui-patterns tint recipe).
struct HFPillChip: View {
    let text: String
    var bg: Color = HFColor.purpleBg
    var fg: Color = HFColor.purpleText
    var dot: Bool = true
    var glyph: HFChipGlyph = .none
    /// True when the chip carries a leading glyph/dot — Figma insets those chips 4 on the left
    /// (the glyph frame supplies the visual gap); glyph-less chips keep a symmetric 8.
    private var hasLeadingGlyph: Bool { glyph != .none || dot }
    var body: some View {
        HStack(spacing: Spacing.spacing4) {
            switch glyph {
            case .none:
                if dot {
                    Circle().fill(fg).frame(width: 14, height: 14)
                }
            case .deliver:
                EncoreIcon(iconName: "LArrowDropDownCircle", size: 14)
                    .foregroundColor(fg)
            case .pickup:
                EncoreIcon(iconName: "LArrowDropDownCircle", size: 14)
                    .foregroundColor(fg)
                    .rotationEffect(.degrees(180))
            case .handback:
                // Figma Task Identifier → Handback (frame 94): the Material "Amend" glyph.
                EncoreIcon(iconName: "LHandback", size: 14)
                    .foregroundColor(fg)
            }
            Text(text)
                .typography(HFType.chip12)
                .foregroundColor(fg)
        }
        .padding(.leading, hasLeadingGlyph ? Spacing.spacing4 : Spacing.spacing8)
        .padding(.trailing, Spacing.spacing8)
        .frame(height: 20)                              // 3 + 14 glyph + 3 (frames 11, 17)
        .background(bg)
        .clipShape(Capsule())
    }
}

/// Entity-type chip (e.g. "Customer") — info-blue tint per Figma (info/dark text + icon,
/// info bg). Distinct from the primary-tint action pills; scales across entity types.
struct HFCustomerChip: View {
    var label: String = "Customer"
    var icon: String = "LPerson"
    var body: some View {
        HStack(spacing: Spacing.spacing4) {
            EncoreIcon(iconName: icon, size: 14)
                .foregroundColor(HFColor.infoText)
            Text(label)
                .typography(HFType.chip12)
                .foregroundColor(HFColor.infoText)
        }
        // Same geometry as the task-type pill: 4 before the glyph, 8 after the label, 20 tall.
        .padding(.leading, Spacing.spacing4)
        .padding(.trailing, Spacing.spacing8)
        .frame(height: 20)
        .background(HFColor.infoBg)
        .clipShape(Capsule())
    }
}

/// Sample entity IDs copied by page-header eyebrows (stub values for the prototype).
enum HFEntityID {
    static let trip = "7f3a9c1b4e82d65f0a1c3e9b5d7f2a4c"
    static let stop = "a1c3e9b5d7f2a4c07f3a9c1b4e82d65f"
    static let order = "3e9b5d7f2a4c07f3a9c1b4e82d65f0a1"
}

/// Primary-tint action pill (Map / View details / …) — hugs its content (not edge-to-edge).
struct HFTintButton: View {
    let label: String
    var icon: String? = nil
    /// Figma `Sheet Header ▸ Action Wrapper` (11394:723379): 34pt pill in a 48pt touch target, 12pt
    /// horizontal padding, 4pt icon gap. Default stays 40 for the v1 screens.
    var height: CGFloat = 40
    var iconSize: CGFloat = 18
    var tint: Color = HFColor.primary
    /// Figma outlines these pills with a very subtle hairline; v1 passes nil.
    var border: Color? = nil
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.spacing4) {
                if let icon {
                    EncoreIcon(iconName: icon, size: iconSize)
                        .foregroundColor(tint)
                }
                Text(label)
                    .typography(Typography.Button.small)
                    .foregroundColor(tint)
            }
            .padding(.horizontal, Spacing.spacing12)
            .frame(height: height)
            .background(tint.opacity(0.08))
            .clipShape(Capsule())
            .overlay {
                if let border {
                    Capsule().stroke(border, lineWidth: 1)
                }
            }
            // 34pt pill centred in a 48pt target, per the node.
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }
}

/// Circular icon action (e.g. Navigate on a stop card): 48pt, grey fill per Figma
/// (Background/ColumnHeading #F5F5F5), primary-blue glyph.
struct HFCircleAction: View {
    let icon: String
    var body: some View {
        EncoreIcon(iconName: icon, size: 24)
            .foregroundColor(HFColor.primary)
            .frame(width: 48, height: 48)
            .background(HFColor.screen)
            .clipShape(Circle())
    }
}

// MARK: - Entity eyebrows (card = plain · page header = copyable)

/// Plain small-caps entity eyebrow for cards / list items — no underline, not tappable.
/// Tenet: a card's entity eyebrow references *another* entity, so it isn't copyable.
struct HFEntityEyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .typography(Typography.overline2)
            .foregroundColor(HFColor.textSecondary)
    }
}

/// Page-header entity eyebrow — dotted underline + tap to copy the entity ID (shows a toast).
/// Tenet: the eyebrow of the entity a page is ABOUT is copyable. `entity` is the human label
/// ("Trip"/"Stop"/"Task"/"Order"); `id` is the value copied to the clipboard.
struct HFCopyableEyebrow: View {
    let text: String
    let entity: String
    let id: String
    @Environment(\.hfCopyEntity) private var copy
    var body: some View {
        Button { copy(entity, id) } label: {
            Text(text.uppercased())
                .typography(Typography.overline2)
                .foregroundColor(HFColor.textSecondary)
                .overlay(alignment: .bottom) {
                    GeometryReader { g in
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: 0.5))
                            p.addLine(to: CGPoint(x: g.size.width, y: 0.5))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [1, 2]))
                        .foregroundColor(HFColor.textDisabled)
                    }
                    .frame(height: 1)
                    .offset(y: 3)
                }
        }
        .buttonStyle(.plain)
    }
}

/// Entity title with a trailing green verified seal that flows INLINE with the (wrapping)
/// text — concatenated Text so the seal sits after the last word and wraps naturally,
/// scaling with the title font. (SF seal glyph; swap for the LVerified asset if exact match needed.)
struct HFVerifiedTitle: View {
    let title: String
    var verified: Bool = true
    var font: TypographyStyle = Typography.h6   // page headers h6/16; stop cards label1/14
    var body: some View {
        titleText
            .typography(font)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var titleText: Text {
        let base = Text(title).foregroundColor(HFColor.textPrimary)
        guard verified else { return base }
        let seal: Text = HFVerifiedTitle.sealImage.map { Text($0) }
            ?? Text(Image(systemName: "checkmark.seal.fill"))
        // Negative baselineOffset lowers the 16px seal so it centers with the label's cap height (iOS 16+).
        return base + Text("\u{00A0}") + seal.foregroundColor(HFColor.success).baselineOffset(-2)
    }

    /// The LVerified asset rasterised to an exact 16×16 template so it flows inline in Text
    /// at the Figma size (Text(Image:) can't resize a raw asset). Cached once.
    static let sealImage: Image? = {
        #if canImport(UIKit)
        guard let base = UIImage(named: "LVerified", in: Bundle(for: HFToastCenter.self), compatibleWith: nil)
        else { return nil }
        let side: CGFloat = 16
        let rendered = UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
            base.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        return Image(uiImage: rendered.withRenderingMode(.alwaysTemplate))
        #else
        return nil
        #endif
    }()
}

// MARK: - Copy-entity-ID toast (page-header eyebrows)

/// Single feedback-toast channel for the flow: any transient message (status + copy) shows
/// through here so it rises from behind the sticky footer and sinks back under it.
final class HFToastCenter: ObservableObject {
    struct Msg: Equatable { let title: String; let subtitle: String?; let token: Int }
    @Published var current: Msg? = nil
    private var counter = 0

    /// Show a status toast (title, optional detail line).
    func show(_ title: String, subtitle: String? = nil) { present(title, subtitle) }

    /// Copy an entity ID to the clipboard and confirm with a toast.
    func copy(label: String, id: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = id
        #endif
        present("Copied \(label) ID", id)
    }

    func dismiss() { withAnimation(.easeInOut(duration: 0.25)) { current = nil } }

    /// Feedback lands AFTER the control that caused it has finished changing — the swipe settles
    /// and the footer swaps to its next state first, then the toast rises. Arriving together, the
    /// two motions compete and the toast reads as part of the button change.
    static let entryDelay: TimeInterval = 0.45

    private func present(_ title: String, _ subtitle: String?) {
        counter += 1
        let token = counter
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.entryDelay) { [weak self] in
            guard let self, self.counter == token else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                self.current = Msg(title: title, subtitle: subtitle, token: token)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                guard let self, self.current?.token == token else { return }
                withAnimation(.easeIn(duration: 0.25)) { self.current = nil }
            }
        }
    }
}

private struct HFCopyActionKey: EnvironmentKey {
    static let defaultValue: (String, String) -> Void = { _, _ in }
}
private struct HFToastKey: EnvironmentKey {
    static let defaultValue: HFToastCenter? = nil
}
// Flow actions injected by HFFlowV2 so leaf controls (View-details button, Navigate pill, stop
// kebab) can trigger flow-level presentations without threading callbacks through every screen.
private struct HFViewDetailsKey: EnvironmentKey { static let defaultValue: () -> Void = {} }
private struct HFNavigateKey: EnvironmentKey { static let defaultValue: () -> Void = {} }
private struct HFStopMenuKey: EnvironmentKey { static let defaultValue: () -> Void = {} }
extension EnvironmentValues {
    /// Injected by the flow root; called with (entityLabel, id) when a copyable eyebrow is tapped.
    var hfCopyEntity: (String, String) -> Void {
        get { self[HFCopyActionKey.self] }
        set { self[HFCopyActionKey.self] = newValue }
    }
    /// The shared toast center; footers read it to host the rise-from-behind toast.
    var hfToast: HFToastCenter? {
        get { self[HFToastKey.self] }
        set { self[HFToastKey.self] = newValue }
    }
    /// Trip "View details" → present the details sheet (screen 03).
    var hfViewDetails: () -> Void {
        get { self[HFViewDetailsKey.self] }
        set { self[HFViewDetailsKey.self] = newValue }
    }
    /// Stop "Navigate" → present the Google-Maps hand-off (screen 08/10).
    var hfNavigate: () -> Void {
        get { self[HFNavigateKey.self] }
        set { self[HFNavigateKey.self] = newValue }
    }
    /// Arrived-stop kebab (⋮) → present the undo-arrival menu (screen 13).
    var hfStopMenu: () -> Void {
        get { self[HFStopMenuKey.self] }
        set { self[HFStopMenuKey.self] = newValue }
    }
}

extension AnyTransition {
    /// A toast rises from behind the footer: it starts one full toast-slot down (56 + 16), i.e.
    /// hidden under the footer, and slides up to rest 16 above it.
    static var hfRiseFromFooter: AnyTransition {
        .modifier(active: HFYOffset(y: 56 + Spacing.spacing16), identity: HFYOffset(y: 0))
    }
}

private struct HFYOffset: ViewModifier {
    let y: CGFloat
    func body(content: Content) -> some View { content.offset(y: y) }
}

/// The single feedback/alert banner (ui-decisions §9: "one banner, repositioned + recoloured
/// for its role"). Figma `<Alert> | Banner`.
///   • `.toast`   — feedback: grey action/active #666 pill near the thumb, left icon + text +
///                  optional close, r8, E1 shadow.
///   • `.network` — connectivity: full-bleed band covering the status bar, centred icon + white
///                  16px, recoloured by state (offline warning/main, reconnected success/main).
enum HFBannerRole { case toast, network }

struct HFBanner: View {
    var role: HFBannerRole = .toast
    let title: String
    var subtitle: String? = nil
    var icon: String
    var fill: Color = HFColor.toast
    var onClose: (() -> Void)? = nil

    var body: some View {
        switch role {
        case .toast:   pill
        case .network: band
        }
    }

    private var pill: some View {
        HStack(spacing: 0) {
            EncoreIcon(iconName: icon, size: 20)
                .foregroundColor(HFColor.onPrimary)
                .padding(.trailing, Spacing.spacing12)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .typography(Typography.subtitle1)
                    .foregroundColor(HFColor.onPrimary)
                if let subtitle {
                    Text(subtitle)
                        .typography(Typography.body2)
                        .foregroundColor(HFColor.onPrimary.opacity(0.7))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: Spacing.spacing16)
            if let onClose {
                Button(action: onClose) {
                    EncoreIcon(iconName: "LCross", size: 24)
                        .foregroundColor(HFColor.onPrimary)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, Spacing.spacing12)
        .padding(.vertical, Spacing.spacing4)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color(.sRGB, red: 17/255, green: 19/255, blue: 24/255, opacity: 0.16), radius: 4)
    }

    private var band: some View {
        HStack(spacing: Spacing.spacing8) {
            EncoreIcon(iconName: icon, size: 16)
                .foregroundColor(HFColor.onPrimary)
            Text(title)
                .typography(Typography.label0)
                .foregroundColor(HFColor.onPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.spacing8)
        .background(fill)
    }
}

/// Feedback toast — the `.toast` role of `HFBanner`. Named alias kept for the toast animation system.
struct HFToastPill: View {
    let title: String
    var subtitle: String? = nil
    var icon: String = "LCheckCircle"
    var onClose: (() -> Void)? = nil
    var body: some View {
        HFBanner(role: .toast, title: title, subtitle: subtitle, icon: icon, onClose: onClose)
    }
}

/// The toast host for a surface WITHOUT a footer (terminal pages, the arrived stop sheet). Every
/// surface needs one: the toast host used to live only inside `HFSheetFooter`, so on a footer-less
/// surface feedback silently never showed (frames 19, 37, 73). This is an empty footer the height of
/// the home-indicator inset, so the toast rests 16 above the bottom edge of the usable screen.
struct HFToastAnchor: View {
    /// Space the anchor occupies. Defaults to the home-indicator inset; a surface whose own bottom
    /// bar already clears it (a tab bar) passes 0.
    var height: CGFloat = HFLayout.bottomInset
    var body: some View {
        HFToastFooter {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: height)
        }
    }
}

/// Wraps a sticky footer so a toast rises up from BEHIND the footer, rests just above it,
/// then sinks back under it (bread-toast behaviour). No-op if no toast center is in scope.
struct HFToastFooter<Footer: View>: View {
    @Environment(\.hfToast) private var toastCenter
    private let footer: () -> Footer
    init(@ViewBuilder footer: @escaping () -> Footer) { self.footer = footer }
    var body: some View {
        if let tc = toastCenter {
            HFToastFooterBody(toast: tc, footer: footer)
        } else {
            footer()
        }
    }
}

private struct HFToastFooterBody<Footer: View>: View {
    @ObservedObject var toast: HFToastCenter
    let footer: () -> Footer
    /// Live downward drag on the pill. Dragging down pushes the toast back under the footer.
    @State private var drag: CGFloat = 0
    var body: some View {
        // The toast is anchored to the footer's TOP edge by alignment — its bottom sits 16 above the
        // footer whatever the footer's height (a caption makes it taller). The old version offset by a
        // measured height that defaulted to 88 and went stale, so on a captioned footer the toast
        // landed half behind it.
        //
        // It lives in an OVERLAY band that ends exactly at the footer's top edge and clips: the toast
        // starts one slot low (inside the band's clipped-off bottom, i.e. "behind" the footer) and
        // rises into view. A background would be the natural way to go behind the footer, but a
        // background is also drawn beneath the scroll list above it, so the toast never showed.
        footer()
            .overlay(alignment: .top) {
                ZStack(alignment: .bottom) {
                    if let m = toast.current {
                        HFToastPill(title: m.title, subtitle: m.subtitle, onClose: { dismiss() })
                            .padding(.horizontal, Spacing.spacing20)      // 320 wide on a 360 frame
                            .padding(.bottom, Spacing.spacing16)          // rests 16 above the footer
                            .offset(y: drag)
                            .transition(.hfRiseFromFooter)
                            .gesture(dragDown)
                            .id(m.token)
                    }
                }
                // Full width even when empty: an empty ZStack is 0 wide, and animating it open read
                // as the toast being unmasked from the centre outwards.
                .frame(maxWidth: .infinity)
                .frame(height: Self.band, alignment: .bottom)
                .clipped()
                .alignmentGuide(.top) { $0[.bottom] }                     // band ends at footer top
            }
    }

    /// Tall enough for a two-line toast plus its 16pt rest gap.
    private static var band: CGFloat { 120 }

    /// Drag-down dismisses, mirroring the sheet gesture — the toast sinks back the way it rose.
    private var dragDown: some Gesture {
        DragGesture()
            .onChanged { v in if v.translation.height > 0 { drag = v.translation.height } }
            .onEnded { v in
                if v.translation.height > 24 {
                    dismiss()
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) { drag = 0 }
                }
            }
    }

    private func dismiss() {
        drag = 0
        toast.dismiss()
    }
}

// MARK: - Avatar

struct HFAvatar: View {
    var initials: String = "A"
    var size: CGFloat = 40
    var body: some View {
        Text(initials)
            .typography(Typography.Avatar.initialsLg)
            .foregroundColor(HFColor.onPrimary)
            .frame(width: size, height: size)
            // Figma avatar fill is neutral grey (#A3A3A3); the DS avatar/fill token doesn't resolve here.
            .background(Color(red: 0.639, green: 0.639, blue: 0.639))
            .clipShape(Circle())
    }
}

// MARK: - Section header (grey area)

struct HFSectionHeader: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .typography(Typography.overline2)
            .foregroundColor(HFColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.spacing16)
            .padding(.top, Spacing.spacing16)
            .padding(.bottom, Spacing.spacing8)
    }
}

// MARK: - Tabs (hug-width, tap-to-select, active underline)

/// Reusable tab strip. Tabs hug their label width and sit left-aligned (not edge-to-edge);
/// the active underline hugs the active label. Drives a `selection` binding and fires
/// `onSelect` on tap so callers can react (e.g. scroll a section into focus).
struct HFTabs: View {
    let tabs: [String]
    @Binding var selection: Int
    var onSelect: (Int) -> Void = { _ in }

    init(tabs: [String], selection: Binding<Int>, onSelect: @escaping (Int) -> Void = { _ in }) {
        self.tabs = tabs
        self._selection = selection
        self.onSelect = onSelect
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { i, t in
                Button {
                    selection = i
                    onSelect(i)
                } label: {
                    // Underline drawn as a bottom overlay so it hugs the label width
                    // (a plain Rectangle is width-flexible and would stretch the tab).
                    // 12px internal L/R padding widens the underline + tap target.
                    Text(t)
                        .typography(Typography.label1)
                        .foregroundColor(i == selection ? HFColor.primary : HFColor.textSecondary)
                        .padding(.horizontal, Spacing.spacing12)
                        .padding(.top, Spacing.spacing12)
                        .padding(.bottom, Spacing.spacing8)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(i == selection ? HFColor.primary : Color.clear)
                                .frame(height: 2)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)         // left-aligned, not edge-to-edge
        .padding(.horizontal, Spacing.spacing4)                  // first label lands on the 16px grid
        .background(alignment: .bottom) {                        // full-width hairline under the strip
            Rectangle()
                .fill(HFColor.textSecondary.opacity(0.15))
                .frame(height: 1)
        }
        .background(HFColor.surface)
        .animation(.easeInOut(duration: 0.2), value: selection)
    }
}

// MARK: - Scroll-driven section tracking (keeps the tab in sync with scroll position)

struct HFSectionOffsetKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    /// Reports this view's top offset (in the named scroll coordinate space) under `index`,
    /// so a tab strip can highlight whichever section currently sits at the top while scrolling.
    func hfTrackSection(_ index: Int, in space: String) -> some View {
        background(
            GeometryReader { g in
                Color.clear.preference(
                    key: HFSectionOffsetKey.self,
                    value: [index: g.frame(in: .named(space)).minY]
                )
            }
        )
    }
}

// MARK: - Bottom navigation (3 tabs)

struct HFBottomNav: View {
    var activeIndex: Int = 2 // Delivery
    // Selected tab shows the filled icon, others show the stroked/outlined variant.
    private let items: [(filled: String, outlined: String, label: String)] = [
        ("LHomeFilled", "LHomeOutlined", "Home"),
        ("LWarehouseFilled", "LWarehouseOutlined", "Hub ops"),
        ("LLocalShipping", "LLocalShipping", "Delivery"), // outlined shipping variant pending
    ]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                VStack(spacing: Spacing.spacing4) {
                    EncoreIcon(iconName: i == activeIndex ? item.filled : item.outlined, size: 24)
                        .foregroundColor(i == activeIndex ? HFColor.primary : HFColor.textSecondary)
                    Text(item.label)
                        .typography(Typography.label2)
                        .foregroundColor(i == activeIndex ? HFColor.primary : HFColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
        }
        .padding(.top, Spacing.spacing4)
        .padding(.bottom, HFLayout.barBottom(Spacing.spacing4))   // clear the home indicator
        .background(HFColor.surface)
    }
}

// MARK: - App bar (Home): title + shift subtitle + avatar

struct HFHomeAppBar: View {
    var title: String = "Delivery"
    var subtitle: String = "ON SHIFT · SINCE 08:02"
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .typography(Typography.label0)
                        .foregroundColor(HFColor.textPrimary)
                    Text(subtitle)
                        .typography(Typography.label2)
                        .foregroundColor(HFColor.successDark)
                }
                Spacer()
                HFAvatar()
            }
            .padding(.horizontal, Spacing.spacing16)
            .padding(.vertical, Spacing.spacing8)
            HFSeam()
        }
        .background(HFColor.surface)
    }
}

// MARK: - Stop card (trip page stops list)

/// Reusable stop card. Figma: white r12 card, 0.5 divider border, 12 padding; content column
/// (STOP eyebrow +optional status → 14pt verified title → subtext → Customer chip) with an
/// optional grey circular navigate action. Tap handling stays with the caller.
struct HFStopCard: View {
    var eyebrow: String = "STOP 1"
    var title: String = "Locus - Logistics Optimization & Decision-making Platform"
    var subtext: String = "08:30 - 10:00 · 2 tasks"
    var statusText: String? = nil
    var statusFill: Color = HFColor.success
    var showNavigate: Bool = false
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.spacing12) {
            VStack(alignment: .leading, spacing: Spacing.spacing16) {   // content ↔ chip = 16
                VStack(alignment: .leading, spacing: Spacing.spacing8) { // eyebrow ↔ details = 8
                    HStack(spacing: Spacing.spacing8) {
                        HFEntityEyebrow(text: eyebrow)
                        if let statusText {
                            HFStatusChip(text: statusText, fill: statusFill)
                        }
                    }
                    VStack(alignment: .leading, spacing: Spacing.spacing4) {  // title ↔ subtext = 4
                        HFVerifiedTitle(title: title, font: Typography.label1)
                        Text(subtext)
                            .typography(Typography.body2)
                            .foregroundColor(HFColor.textSecondary)
                    }
                }
                HFCustomerChip()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if showNavigate {
                HFCircleAction(icon: "LNavigationOutlined")
            }
        }
        .padding(Spacing.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(HFColor.divider, lineWidth: 0.5))
    }
}

// MARK: - Trip status + model (home cards)

/// Trip lifecycle status shown as a chip on the home trip card / trip page.
public enum HFTripStatus {
    case inTransit, completed, pendingDispatch
    var text: String {
        switch self {
        case .inTransit: return "In transit"
        case .completed: return "Completed"
        case .pendingDispatch: return "Pending dispatch"
        }
    }
    var fill: Color {
        switch self {
        case .inTransit: return HFColor.primary        // blue
        case .completed: return HFColor.success        // green
        case .pendingDispatch: return HFColor.toast     // dark grey (Action/Active)
        }
    }
}

/// One trip on the home list.
public struct HFTrip {
    let eyebrow: String
    let time: String
    let sub: String
    var chips: [(String, Bool)]                        // (label, isPickup)
    var status: HFTripStatus? = nil
    var progress: Double? = nil                         // 0…1 → shows the progress bar
    public init(eyebrow: String, time: String, sub: String, chips: [(String, Bool)],
                status: HFTripStatus? = nil, progress: Double? = nil) {
        self.eyebrow = eyebrow; self.time = time; self.sub = sub; self.chips = chips
        self.status = status; self.progress = progress
    }
}

/// Thin primary progress bar used on in-transit trip cards.
struct HFTripProgressBar: View {
    let fraction: CGFloat
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(HFColor.primary.opacity(0.15))
                Capsule().fill(HFColor.primary)
                    .frame(width: max(0, geo.size.width * fraction))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Trip card (clickable card on Home)

struct HFTripCard: View {
    let eyebrow: String
    let title: String
    let sub: String
    let chips: [(String, Bool)] // (label, isPickup) — pickup vs delivery both purple here
    var status: HFTripStatus? = nil
    var progress: Double? = nil
    init(eyebrow: String, title: String, sub: String, chips: [(String, Bool)],
         status: HFTripStatus? = nil, progress: Double? = nil) {
        self.eyebrow = eyebrow; self.title = title; self.sub = sub; self.chips = chips
        self.status = status; self.progress = progress
    }
    init(_ trip: HFTrip) {
        self.init(eyebrow: trip.eyebrow, title: trip.time, sub: trip.sub, chips: trip.chips,
                  status: trip.status, progress: trip.progress)
    }
    private var showCheck: Bool { status == .inTransit || status == .completed }
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            HStack(spacing: Spacing.spacing8) {
                Text(eyebrow.uppercased())
                    .typography(Typography.overline2)
                    .foregroundColor(HFColor.textSecondary)
                if let status {
                    HFStatusChip(text: status.text, fill: status.fill)
                }
            }
            Text(title)
                .typography(Typography.h6)
                .foregroundColor(HFColor.textPrimary)
            if let progress {
                HFTripProgressBar(fraction: progress)
            }
            if showCheck {
                HStack(spacing: Spacing.spacing8) {
                    EncoreIcon(iconName: "LCheckCircle", size: 16)
                        .foregroundColor(HFColor.success)
                    Text(sub)
                        .typography(Typography.body2)
                        .foregroundColor(HFColor.textSecondary)
                }
            } else {
                Text(sub)
                    .typography(Typography.body2)
                    .foregroundColor(HFColor.textSecondary)
            }
            HStack(spacing: Spacing.spacing8) {
                ForEach(chips, id: \.0) { c in
                    HFPillChip(text: c.0, glyph: c.1 ? .pickup : .deliver)
                }
            }
            .padding(.top, Spacing.spacing4)
        }
        .padding(Spacing.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(HFColor.divider, lineWidth: 0.5))
    }
}

// MARK: - Home empty / zero states

/// Loads a full-colour illustration from the asset catalog (original rendering mode).
func hfIllustration(_ name: String) -> Image {
    if let ui = UIImage(named: name, in: Bundle(for: HFToastCenter.self), compatibleWith: nil) {
        return Image(uiImage: ui)
    }
    return Image(systemName: "shippingbox")
}

/// Centered illustration + title + subtitle — home "nothing scheduled" empty state.
struct HFEmptyState: View {
    var illustration: String
    var title: String
    var subtitle: String
    var body: some View {
        VStack(spacing: Spacing.spacing16) {
            hfIllustration(illustration)
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 220)
            VStack(spacing: Spacing.spacing8) {
                Text(title)
                    .typography(Typography.h6)
                    .foregroundColor(HFColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .typography(Typography.body1)
                    .foregroundColor(HFColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.spacing24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HFColor.screen)
    }
}

/// Info banner used inside a section (e.g. "Nothing for today") — subtle grey card
/// (black @4% over the screen) with a small trailing illustration.
struct HFInfoBanner: View {
    var title: String
    var subtitle: String
    var illustration: String? = nil
    var body: some View {
        HStack(alignment: .center, spacing: Spacing.spacing12) {
            VStack(alignment: .leading, spacing: Spacing.spacing2) {
                Text(title)
                    .typography(Typography.label1)
                    .foregroundColor(HFColor.textPrimary)
                Text(subtitle)
                    .typography(Typography.body2)
                    .foregroundColor(HFColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let illustration {
                hfIllustration(illustration)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 72)
            }
        }
        .padding(Spacing.spacing12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.04)))
    }
}

/// Offline connectivity band — the `.network` role of `HFBanner`, recoloured warning/main.
struct HFOfflineBanner: View {
    var lastSynced: String
    var body: some View {
        HFBanner(role: .network,
                 title: "Offline · Last synced \(lastSynced)",
                 icon: "LAlertTri",
                 fill: HFColor.warning)
    }
}

// MARK: - Shared title bar (back/none · title · kebab/close)

/// One title bar for stop / task / trip screens, so the app-bar layout stops drifting per screen.
/// Encodes the **16→4 rule**: side padding is 16, but drops to 4 on a side that holds a padded
/// 48pt icon button (the button's own hit area supplies the visual gap). Back = chevron
/// (`LChevronLeft`); close = plain X (`LCross`); optional kebab (`LOverflowVertical`).
struct HFTitleBar: View {
    enum Leading { case none, back }
    enum Trailing { case none, close, menuClose }

    let title: String
    var leading: Leading = .none
    var trailing: Trailing = .none
    var onBack: () -> Void = {}
    var onClose: () -> Void = {}
    @Environment(\.hfStopMenu) private var stopMenu   // kebab → flow presents undo-arrival menu

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.spacing8) {
                if leading == .back {
                    Button(action: onBack) {
                        // Our LChevronLeft glyph is chunkier than Figma's MUI ChevronLeft,
                        // so 18 matches the Figma glyph size; 48 keeps the touch target.
                        EncoreIcon(iconName: "LChevronLeft", size: 18)
                            .foregroundColor(HFColor.textSecondary)   // navbar back = action/active #666
                            .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.plain)
                }
                Text(title)
                    .typography(Typography.label0)
                    .foregroundColor(HFColor.textPrimary)
                Spacer()
                if trailing == .menuClose {
                    Button(action: stopMenu) {
                        EncoreIcon(iconName: "LOverflowVertical", size: 24)
                            .foregroundColor(HFColor.textPrimary)
                            .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.plain)
                }
                if trailing == .close || trailing == .menuClose {
                    Button(action: onClose) {
                        EncoreIcon(iconName: "LCross", size: 24)
                            .foregroundColor(HFColor.textPrimary)
                            .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 48)                          // icon-button row
            .padding(.leading, leading == .back ? Spacing.spacing4 : Spacing.spacing16)
            .padding(.trailing, trailing == .none ? Spacing.spacing16 : Spacing.spacing4)
            .padding(.vertical, Spacing.spacing8)       // → 64pt app bar per Figma
            HFSeam()
        }
        .background(HFColor.surface)
    }
}

// MARK: - Shared pinned CTA footer

/// Pinned bottom-action container. Figma separates it from content with an **E1 drop-shadow**
/// (not a divider), and pads it h16 / top16 / **bottom20**.
struct HFSheetFooter<Content: View>: View {
    var caption: String? = nil
    var captionText: Text? = nil
    @ViewBuilder var content: Content
    var body: some View {
        HFToastFooter {
            VStack(spacing: Spacing.spacing8) {
                content
                if let captionText {
                    captionText
                        .typography(Typography.label2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                } else if let caption {
                    Text(caption)
                        .typography(Typography.label2)     // Figma: Medium 12 / text-secondary
                        .foregroundColor(HFColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, Spacing.spacing16)
            .padding(.top, Spacing.spacing16)
            // Figma's 16, but never less than the home-indicator inset, so the CTA clears it.
            .padding(.bottom, HFLayout.barBottom(Spacing.spacing16))
            .frame(maxWidth: .infinity)
            // Shadow is cast by the BAR only (not the content), so it reads as a top separator
            // above the sticky footer — never a halo around the button. (Figma <DialogActions>.)
            .background(
                Rectangle()
                    .fill(HFColor.surface)
                    .shadow(color: Color(.sRGB, red: 17/255, green: 19/255, blue: 24/255, opacity: 0.16),
                            radius: 2, x: 0, y: 0)                     // E1 — 0 0 4 @16%
            )
        }
    }
}

// MARK: - Modal bottom sheet (scrim over the real page + sliding sheet)

/// Reusable modal bottom sheet. Presented as an overlay over the CURRENT page: a 50% scrim
/// fades in and a bottom-anchored sheet slides up — the underlying page stays put (no duplicate).
/// Tap the scrim to dismiss. Drive `isPresented` inside `withAnimation` so both animate.
struct HFBottomSheet<SheetContent: View>: View {
    let isPresented: Bool
    var onDismiss: () -> Void = {}
    @ViewBuilder var sheet: () -> SheetContent
    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .contentShape(Rectangle())
                    .onTapGesture { onDismiss() }
                sheet()
                    .frame(maxWidth: .infinity)
                    .background(HFColor.surface)
                    .transition(.move(edge: .bottom))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        // The sheet runs to the screen's bottom edge. Its footer (HFSheetFooter) already pads for the
        // home indicator; stopping the sheet at the safe-area line as well left a dead white band
        // under every footer. Footer-less sheets pad themselves (`HFSheetBottomInset`).
        .ignoresSafeArea(.container, edges: .bottom)
        // Owned here rather than left to the caller's `withAnimation`: a sheet that snaps because
        // one call site forgot to wrap the state change is the same bug every time.
        .animation(.easeInOut(duration: 0.28), value: isPresented)
    }
}

/// Bottom spacing for a sheet with NO footer, so its last row clears the home indicator. A sheet with
/// a footer must not add this — the footer already does.
struct HFSheetBottomInset: View {
    /// White, so it reads as the bottom of the last section rather than a band of its own.
    var body: some View { HFColor.surface.frame(height: HFLayout.bottomInset) }
}

/// Reusable dialog title row for sheets: title (label0) + trailing close (✕). Figma <DialogTitle>.
struct HFSheetTitle: View {
    let title: String
    var onClose: () -> Void = {}
    var body: some View {
        HStack(spacing: Spacing.spacing8) {
            Text(title)
                .typography(Typography.label0)
                .foregroundColor(HFColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onClose) {
                // `action/active` (#666666), not text/primary — a bar control is not body copy.
                EncoreIcon(iconName: "LCross", size: V2Icon.sheetClose)
                    .foregroundColor(V2Token.actionActive)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, Spacing.spacing16)
        .padding(.trailing, Spacing.spacing4)
        .padding(.vertical, Spacing.spacing8)
        .background(HFColor.surface)
    }
}

/// Label / value pair (Figma: label body2 #666, value label2 #141414, optional sub-value body2).
struct HFLabelValue: View {
    let label: String
    let value: String
    var sub: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).typography(Typography.body2).foregroundColor(HFColor.textSecondary)
            Text(value).typography(Typography.label2).foregroundColor(HFColor.textPrimary)
            if let sub {
                Text(sub).typography(Typography.body2).foregroundColor(HFColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Trip "View details" sheet content (Figma 3989:121797): title + ✕, then a 2×3 label/value grid.
struct HFViewDetailsSheet: View {
    var onClose: () -> Void = {}
    private let rows: [[HFLabelValue]] = [
        [HFLabelValue(label: "Planned time", value: "12:00-12:45"),
         HFLabelValue(label: "Helper", value: "Suresh")],
        [HFLabelValue(label: "Vehicle", value: "KA-01-AB-1234", sub: "(LCV Tata Ace)"),
         HFLabelValue(label: "Total tasks", value: "12")],
        [HFLabelValue(label: "Planned distance", value: "80 kms"),
         HFLabelValue(label: "Planned time", value: "3 hrs 20 mins")],
    ]
    var body: some View {
        VStack(spacing: 0) {
            HFSheetTitle(title: "View details", onClose: onClose)
            HFSeam()                                   // 1px f5f5f5 gap under the title
            VStack(alignment: .leading, spacing: Spacing.spacing16) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(alignment: .top, spacing: Spacing.spacing16) {
                        row[0]
                        row[1]
                    }
                }
            }
            .padding(Spacing.spacing16)
        }
    }
}

// MARK: - Placeholder for not-yet-built screens

struct HFPlaceholder: View {
    let n: String
    var body: some View {
        ZStack {
            HFColor.screen.ignoresSafeArea()
            Text("Screen \(n)\n(not built yet)")
                .typography(Typography.h6)
                .foregroundColor(HFColor.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}
