import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - P0.11 Type ramp and spacing rhythm
//
// Why this file exists: feedback kept landing on one screen at a time. That happened because surfaces
// were reaching for raw `Typography.*` and passing metrics at each call site, so a correction only ever
// applied where it was typed. Everything measurable now lives here, and surfaces spend these values —
// they never invent them.
//
// Line heights matter as much as sizes. Figma pins an explicit line height per style; SwiftUI otherwise
// uses the font's own leading, which is what made copy read cramped/loose even at the right point size.

struct V2TextStyle {
    let fontName: String
    let size: CGFloat
    /// Figma line height for this style.
    let lineHeight: CGFloat
    let tracking: CGFloat

    var font: Font { Font.custom(fontName, size: size) }

    /// Extra leading needed to reach the Figma line height from the font's natural one.
    var lineSpacing: CGFloat {
        #if canImport(UIKit)
        let natural = UIFont(name: fontName, size: size)?.lineHeight ?? size * 1.21
        return max(0, lineHeight - natural)
        #else
        return max(0, lineHeight - size * 1.21)
        #endif
    }
}

/// Every text style in the V2 surfaces, with the line height each Figma node actually specifies.
enum V2Font {
    /// The bundled Inter faces register lazily on first use of a library `Typography` style. Touch one
    /// so `Font.custom(_:)` here can resolve them by PostScript name.
    static let ensureRegistered: Void = { _ = Typography.body2 }()

    private static let medium = "Inter18pt-Medium"
    private static let semibold = "Inter18pt-SemiBold"
    private static let regular = "Inter18pt-Regular"

    // Named after the Figma text styles, so a call site says which ROLE it draws — the ramp is the
    // same across every surface in the V2 board. 16 is reserved for titles and names; everything
    // at card level is 14 or below; every chip tier sets its text at 12.

    /// `typography/label0` — navbar / sheet title. Medium 16/24 (lighter than a header name).
    static let navTitle = V2TextStyle(fontName: medium, size: 16, lineHeight: 24, tracking: 0)
    /// `typography/h6` — entity-header name (trip window, stop name, task contact). SemiBold 16/24.
    static let sheetHeadline = V2TextStyle(fontName: semibold, size: 16, lineHeight: 24, tracking: 0)
    /// `typography/h5` — hero value (scanned HU ID). SemiBold 20/28.
    static let h5 = V2TextStyle(fontName: semibold, size: 20, lineHeight: 28, tracking: 0)
    /// `typography/label1` — card headline, list-row title, sheet section heading. Medium 14/20.
    static let label1 = V2TextStyle(fontName: medium, size: 14, lineHeight: 20, tracking: 0)
    /// `typography/label2` — pair value, contact name, navbar subtitle, footer caption. Medium 12/18.
    static let label2 = V2TextStyle(fontName: medium, size: 12, lineHeight: 18, tracking: 0)
    /// `typography/body1` — list-row subtitle, banner copy, toast. Regular 14/20.
    static let body1 = V2TextStyle(fontName: regular, size: 14, lineHeight: 20, tracking: 0)
    /// `typography/body2` — every secondary line: subtext, address, time, captions, pair labels.
    /// Regular 12/18.
    static let body2 = V2TextStyle(fontName: regular, size: 12, lineHeight: 18, tracking: 0)
    /// `typography/overline2` — card/header eyebrow and list section header. SemiBold 12/18,
    /// tracking 0 (uppercase comes from the copy, not the style).
    static let overline2 = V2TextStyle(fontName: semibold, size: 12, lineHeight: 18, tracking: 0)
    static let eyebrow = overline2
    static let section = overline2
    /// `badge/label` — status / SLA chip. Medium 12/20, tracking 0.14.
    static let badge = V2TextStyle(fontName: medium, size: 12, lineHeight: 20, tracking: 0.14)
    /// `chip/labelSmall` — identifier pill, tag. Medium 12/12, tracking 0.16.
    static let chip = V2TextStyle(fontName: medium, size: 12, lineHeight: 12, tracking: 0.16)
    /// `button/small` — action pill label (Map, Navigate, Call…). SemiBold 12/22.
    static let buttonSmall = V2TextStyle(fontName: semibold, size: 12, lineHeight: 22, tracking: 0)
    /// `button/medium` — tabs, FAB. SemiBold 14/24.
    static let buttonMedium = V2TextStyle(fontName: semibold, size: 14, lineHeight: 24, tracking: 0)
    /// `button/large` — footer button / swipe label. SemiBold 16/24.
    static let buttonLarge = V2TextStyle(fontName: semibold, size: 16, lineHeight: 24, tracking: 0)

    /// `chip/label` — "Select all" (frame 30). Medium 14/20, tracking 0.16.
    static let chipLabel = V2TextStyle(fontName: medium, size: 14, lineHeight: 20, tracking: 0.16)
    /// `typography/h4` — login title ("Hi there, / Log in to your workspace"). Medium 24/34.
    static let h4 = V2TextStyle(fontName: medium, size: 24, lineHeight: 34, tracking: 0)
    /// `typography/subtitle1` — toast copy. Regular 14/20, tracking 0.15.
    static let subtitle1 = V2TextStyle(fontName: regular, size: 14, lineHeight: 20, tracking: 0.15)
    /// `menu/itemDefault` — popover menu item. Regular 14/24, tracking 0.15.
    static let menuItem = V2TextStyle(fontName: regular, size: 14, lineHeight: 24, tracking: 0.15)
    /// `input/label` — text-field label. Regular 12/12, tracking 0.15.
    static let inputLabel = V2TextStyle(fontName: regular, size: 12, lineHeight: 12, tracking: 0.15)
    /// `input/value` — text-field value and placeholder. Regular 16/24, tracking 0.15.
    static let inputValue = V2TextStyle(fontName: regular, size: 16, lineHeight: 24, tracking: 0.15)
    /// `bottomNavigation/activeLabel` — the selected tab's label. Regular 14/20, tracking 0.4.
    static let navActive = V2TextStyle(fontName: regular, size: 14, lineHeight: 20, tracking: 0.4)
    /// `typography/caption` — app-version footer. Regular 10/16, tracking 0.4.
    static let caption = V2TextStyle(fontName: regular, size: 10, lineHeight: 16, tracking: 0.4)

    // Checklist + P0 harness only. The checklist bodies are still placeholders in Figma (§8b), so
    // these are not part of the V2 board ramp — don't reach for them on a board surface.
    static let cardTitle = V2TextStyle(fontName: semibold, size: 14, lineHeight: 20, tracking: 0)
    static let body = V2TextStyle(fontName: regular, size: 14, lineHeight: 18, tracking: 0)
    static let button = V2TextStyle(fontName: semibold, size: 14, lineHeight: 22, tracking: 0)
    static let helper = body1
}

extension View {
    /// Single-line labels (chips, badges, eyebrows, buttons).
    ///
    /// These must NOT use `lineSpacing`: it appends leading below a single line, which inflates the
    /// label's height and pushes it off-centre inside a fixed-height pill. Framing to the Figma line
    /// height instead gives the exact box the node measures — e.g. a 22pt label inside a 34pt pill,
    /// itself centred in a 48pt target (7pt either side).
    @ViewBuilder func v2Label(_ style: V2TextStyle) -> some View {
        let _ = V2Font.ensureRegistered
        if #available(iOS 16.0, *) {
            self.font(style.font)
                .tracking(style.tracking)
                .lineLimit(1)
                .frame(height: style.lineHeight)
        } else {
            self.font(style.font)
                .lineLimit(1)
                .frame(height: style.lineHeight)
        }
    }

    /// Flowing text that can wrap. `lineSpacing` only adds leading BETWEEN lines, so on its own a
    /// single line stays at the font's natural height (12/18 renders ~14.5) — which only went unnoticed
    /// while header blocks were pinned. Half the extra leading above and below the block makes every
    /// line land on the Figma line height: n lines = n × lineHeight.
    @ViewBuilder func v2Text(_ style: V2TextStyle) -> some View {
        let _ = V2Font.ensureRegistered
        if #available(iOS 16.0, *) {
            self.font(style.font)
                .tracking(style.tracking)
                .lineSpacing(style.lineSpacing)
                .padding(.vertical, style.lineSpacing / 2)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            self.font(style.font)
                .lineSpacing(style.lineSpacing)
                .padding(.vertical, style.lineSpacing / 2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The spacing rhythm, read off the Figma nodes. Deliberately NOT uniform — the gaps encode content
/// hierarchy, which is exactly what a single default value destroys.
enum V2Space {
    /// Inset inside a list card (trip / stop card wrapper). Node 5617:263145.
    static let cardInset: CGFloat = 12
    /// Inset inside a page or sheet header. Node 11394:723379.
    static let headerInset: CGFloat = 16
    /// Horizontal page margin for content in a scroll list.
    static let pageMargin: CGFloat = 16

    /// eyebrow row → headline.
    static let eyebrowToHeadline: CGFloat = 8
    /// eyebrow row → headline on a task row, tighter than the 8 on trip / stop cards (frames 17, 40).
    static let taskEyebrowToHeadline: CGFloat = 4
    /// headline → its immediate subtext (tight: they are one unit).
    static let headlineToSub: CGFloat = 4
    /// sheet headline → address (tighter still — node measures 2).
    static let sheetHeadlineToAddress: CGFloat = 2
    /// subtext → the next distinct subtext.
    static let subToSub: CGFloat = 8
    /// content block → the tags/identifier row (a real break).
    static let contentToTags: CGFloat = 16
    /// content block → the action row.
    static let contentToActions: CGFloat = 12
    /// gap between chips in a row.
    static let chipGap: CGFloat = 8
    /// gap between identifier pills on a card (node measures 4).
    static let tagGap: CGFloat = 4
    /// gap between cards in a list. Node 10956:665625 stacks 130-tall List cards at a 138 pitch,
    /// so the gap is 8 — NOT the 12 used inside a card.
    static let cardGap: CGFloat = 8
    /// section header → first card. The header is 44 including its own insets, and Figma starts the
    /// card group 1 below it (`gap-px`, frames 12 / 17 / 26) — not the 12 a VStack default gave.
    static let sectionToCard: CGFloat = 1
    /// gap between recipient groups in a stop's task list (frame 73).
    static let groupGap: CGFloat = 8
    /// progress bar → its caption line (node 10956:673547: the block measures 30 = 6 bar + 6 + 18 text).
    static let barToCaption: CGFloat = 6
    /// bottom inset of a page/sheet header — 12, not the 16 used on the other three sides.
    static let headerInsetBottom: CGFloat = 12

    /// Navbar side inset where a button sits on that side (node 11075:762666). The button's own
    /// 12pt padding supplies the rest of the optical inset, so this is 4 and not 16.
    static let navbarInset: CGFloat = 4
    /// Leading avatar → content (nodes 1791:54553 / 1791:51831).
    static let avatarGap: CGFloat = 12
    /// Gap between circular icon actions in the trailing gutter (node 3355:43419: 52 pitch on 48).
    static let iconActionGap: CGFloat = 4
    /// Progress check glyph → its caption (node 2835:228219 → 2835:228220: x16 on a 12pt glyph).
    static let progressIconGap: CGFloat = 4
    /// Key-value grid, both axes (nodes 2835:228314 / 4088:177736).
    static let gridGap: CGFloat = 16
    /// Label/value pair → its caption (node 2835:228335: value ends 36, caption at 38).
    static let pairCaptionGap: CGFloat = 0
    /// `View details` section insets — 12 above the heading, 16 below the grid (node 10956:665730).
    static let detailsSectionTop: CGFloat = 12
    static let detailsSectionBottom: CGFloat = 16
    /// Heading → its grid.
    static let headingToGrid: CGFloat = 12

    /// The 1px seam between stacked white sections on a grey sheet — the grey showing through,
    /// not a drawn rule (node 10956:665726 uses `gap-px` over `background/columnHeading`).
    static let sectionSeam: CGFloat = 1

    /// Every hairline in the V2 surfaces — chip outlines, card strokes, SLA borders. Figma draws these
    /// at 0.5, not 1.
    static let hairline: CGFloat = 0.5
}

/// Block heights Figma pins explicitly. SwiftUI otherwise sizes each block from its font metrics, and
/// those small differences accumulate down a stack — which is why a header composed of "roughly right"
/// pieces lands a few points short of the node. Pin what the node pins; let only genuinely dynamic
/// content flow.
enum V2Metrics {
    /// Eyebrow + status/SLA chip row (all three header nodes measure 20).
    static let eyebrowRow: CGFloat = 20
    /// One line of the header headline (node: 24 per line).
    static let headlineLine: CGFloat = 24
    /// Progress bar + its caption, as one block (node 10956:673547: 30).
    static let progressBlock: CGFloat = 30
    /// Status / SLA chip.
    static let chip: CGFloat = 20
    /// Action pill, and the touch target it is centred in.
    static let pill: CGFloat = 34
    static let pillMinWidth: CGFloat = 64
    /// Call disc on a contact strip (frames 17, 40).
    static let callDisc: CGFloat = 32
    /// Status / SLA chip minimum width.
    static let chipMinWidth: CGFloat = 48
    /// Every footer button and swipe track.
    static let footerButton: CGFloat = 48
    /// Corner radius of every button and swipe track. Figma draws r4; at 48 tall next to r12 cards
    /// and capsule pills that read as square, so buttons are softened to 8 (design call, 2026-10-06).
    /// A control inset 4 inside one (the swipe thumb) takes 8 − 4 = 4 to stay concentric.
    static let footerRadius: CGFloat = 8
    static let touchTarget: CGFloat = 48

    /// A single subtext line (the window/time row).
    static let subtextLine: CGFloat = 18
    /// One line of a LIST headline — 20, tighter than the 24 a header headline uses.
    static let listHeadlineLine: CGFloat = 20
    /// Leading avatar: 32 on a clickable card, 40 on a plain item.
    static let avatarSmall: CGFloat = 32
    static let avatarLarge: CGFloat = 40
    /// Trip Progress (node 2835:228216): a 4pt track centred in a 12pt band. The band — not a
    /// padding value — is what sets the gap down to the caption.
    static let progressBar: CGFloat = 4
    /// Minimum fill of a running progress bar (frames 15, 49, 81 draw ~20 at 0 done).
    static let progressStub: CGFloat = 20
    static let progressBand: CGFloat = 12
    /// The check glyph beside a progress caption (node 2835:228219) is 12, not the 16 used inline
    /// elsewhere.
    static let progressIcon: CGFloat = 12
    /// Grid label/value pair (node 2835:228335).
    static let gridPair: CGFloat = 36
    /// Section / list header above a card list — node 10956:665626 measures 44 including its insets.
    static let listHeader: CGFloat = 44

    // Scan workflow — section 5362:33948 of the Scan template.
    /// Tab strip under the bar (frame 05: `<Tabs>` 360 × 48).
    static let tabBar: CGFloat = 48
    static let tabUnderline: CGFloat = 2
    /// One handling-unit row (node 4564:154228) — edge-to-edge, 64 tall, hairline-separated.
    static let huRow: CGFloat = 64
    /// FAB (node 4458:253196): a 40pt pill inside a 48pt target.
    static let fabPill: CGFloat = 40
    /// `<DialogActions>` footer (node 5326:216138) and the fixed-width action inside it.
    static let dialogActions: CGFloat = 80
    static let footerAction: CGFloat = 160
    /// The scanner's result sheet keeps one height across all four states, so reading a unit does
    /// not resize the camera area above it.
    static let scanSheet: CGFloat = 148

    // Checklist — section 2751:168775 of the Checklist template.
    /// Item header block (node 2751:169257): counter 20 + 4 + title 24 + 4 + help 40.
    static let checklistHeader: CGFloat = 92
    /// The help line reserves two 20pt lines, so an item's height doesn't move with its copy.
    static let checklistHelp: CGFloat = 40
    /// One OTP digit box. Node 2751:169286 measures 328 × 56 for four boxes and three 8pt gaps,
    /// so the box is (328 - 24) / 4.
    static let otpBox: CGFloat = 76
    /// One star (node 2751:169334 is 200 × 40 for five).
    static let ratingStar: CGFloat = 40

    // `View details` sheet — node 10956:665726.
    /// A section's heading line, and the gap from it down to the grid.
    static let detailsHeading: CGFloat = 20

    // No whole-header heights. Trip / stop / task headers hug their slots (frames 12, 15, 17, 40,
    // 57, 73, 110): pinning one state's height pads every other state with dead space.
}

/// Icon sizes by role, so a size is never typed at a call site.
enum V2Icon {
    /// Every nav-bar icon — back chevron, filter, search, kebab, close. Node 11075:762666 draws a
    /// 24pt icon inside a 48pt button for all of them; they are not sized individually.
    static let bar: CGFloat = 24
    /// Leading glyph inside an action pill, identifier pill or tag — every chip tier uses 14.
    static let chip: CGFloat = 14
    /// Standalone circular action (navigate disc on a stop card — 20 inside the 48 disc).
    static let action: CGFloat = 20
    /// Call glyph inside the 32pt contact-strip disc.
    static let call: CGFloat = 14
    /// Row chevron / trailing affordance in a sheet list row.
    static let chevron: CGFloat = 24
    /// Checklist field glyphs (placeholder surface — not on the V2 board).
    static let field: CGFloat = 24
    /// Info glyph in an instruction banner (frame 45).
    static let banner: CGFloat = 20
    /// Trailing glyph on a footer button ("Scan HUs →", frame 27).
    static let footerGlyph: CGFloat = 24
    /// Scan result seal (frame 50).
    static let seal: CGFloat = 48
    /// Inline status glyph next to copy.
    static let inline: CGFloat = 16
    /// Close (✕) in a sheet's `<DialogTitle>`. Figma's Close asset draws 14pt of ink inside a 24pt
    /// box; ours draws ~15.3 at the same nominal size because the two SVGs carry different internal
    /// padding. Matching what the eye sees means matching the INK, so the nominal value is the one
    /// that renders 14 — not the 24 the node labels its icon frame.
    static let sheetClose: CGFloat = 23
}

// MARK: - Components with the right defaults baked in
//
// Call sites pass content, never metrics. This is the part that makes a correction land everywhere at
// once instead of only where someone remembered to type it.

/// Action pill (Navigate / Call / Map / View details / Mark failed).
/// Figma: 34pt pill centred in a 48pt touch target, 12pt horizontal padding, 4pt icon gap, hairline.
struct V2Chip: View {
    enum Role { case primary, danger }

    let label: String
    var icon: String? = nil
    var role: Role = .primary
    var enabled: Bool = true
    var action: () -> Void = {}

    private var tint: Color {
        switch role {
        case .primary: return HFColor.primary
        case .danger:  return Color.encore("Error/Main")
        }
    }

    private var border: Color {
        switch role {
        case .primary: return HFColor.pillBorder
        case .danger:  return Color.encore("Error/Main").opacity(0.08)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.spacing4) {
                if let icon {
                    EncoreIcon(iconName: icon, size: V2Icon.chip)
                        .foregroundColor(tint)
                }
                Text(label)
                    .v2Label(V2Font.buttonSmall)
                    .foregroundColor(tint)
            }
            // Figma pads the pill 12 and the label's own box 4 either side — so 12 before the icon
            // and 16 after the label.
            // 12 before an icon; an icon-less pill gets the label's own 4 on top (16), so the text is
            // centred (View details, Facing issues?).
            .padding(.leading, icon == nil ? Spacing.spacing16 : Spacing.spacing12)
            .padding(.trailing, Spacing.spacing16)
            .frame(minWidth: V2Metrics.pillMinWidth)
            .frame(height: V2Metrics.pill)
            .opacity(enabled ? 1 : 0.5)          // disabled dims the content only; the fill stays
            .background(tint.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(border, lineWidth: V2Space.hairline))
            .frame(height: V2Metrics.touchTarget)   // the pill, centred in its touch target
        }
        .buttonStyle(.plain)
        .allowsHitTesting(enabled)          // see V2Button: .disabled would dim the label twice
    }
}

/// Section header above a list. Owns the gap to the first card, so lists don't add their own on top —
/// the double-counting was what made this padding look wrong.
struct V2SectionHeader: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .v2Label(V2Font.section)
            .foregroundColor(HFColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, V2Space.pageMargin)
            .frame(height: V2Metrics.listHeader)            // 44, text centred (frames 12, 17)
    }
}

/// Eyebrow + chips row, pinned to the node's 20pt so it can't drift per surface.
struct V2EyebrowRow<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        HStack(spacing: V2Space.chipGap) {
            content
        }
        .frame(height: V2Metrics.eyebrowRow)
    }
}

/// Progress bar + caption. Kept as a name surfaces already use, but it now renders the Figma
/// component (`V2ProgressRow`, node 2835:228299) so there is exactly one progress drawing in V2.
struct V2ProgressBlock: View {
    let fraction: CGFloat
    let caption: String
    /// Some surfaces show the caption without a bar (terminal states).
    var showBar: Bool = true

    var body: some View {
        V2ProgressRow(slot: V2ProgressSlot(fraction: showBar ? fraction : nil, caption: caption))
    }
}

/// Plain card eyebrow — a card references ANOTHER entity, so it is never copyable.
struct V2Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .v2Label(V2Font.eyebrow)
            .foregroundColor(HFColor.textSecondary)
    }
}
