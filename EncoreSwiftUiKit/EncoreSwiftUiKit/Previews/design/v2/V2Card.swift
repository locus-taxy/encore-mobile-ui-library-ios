import SwiftUI

// MARK: - The card framework
//
// Every card-shaped surface in V2 — trip row, stop row, task row, page header, sheet header — is the
// SAME Figma component with different slots switched on. The board draws the variants by hiding
// layers, not by drawing new components, so the code models it the same way: one view, one geometry
// table, and a value that says which slots are filled.
//
// This is the fix for corrections landing on a single screen. Nothing below composes its own stack;
// surfaces build a `V2CardModel` and hand it over.
//
// Nodes this file is pinned to:
//   .card      3989:27391  — 328 wide inside a 360 frame; 16/16/16/12 insets; actions under a divider
//   .clickable 1791:54552  — 328×130; 12 inset; trailing icon buttons; tight details block
//   .item      1791:51860  — 328×66;  12 inset; details only
//   grid       2835:228314 (2 col) / 4088:177736 (3 col) — 304×88, pair 36, gaps 16
//   progress   2835:228299 — Default / Completed / Ongoing / Started

// MARK: Slots

/// A rendered chip. Chips already exist as components (`V2StopStatusChip`, `HFPillChip`, …) and stay
/// the single source of truth for their own look — the card only needs to know where to put them.
struct V2ChipSlot: Identifiable {
    let id: String
    let view: AnyView
    init<V: View>(_ id: String, @ViewBuilder view: () -> V) {
        self.id = id
        self.view = AnyView(view())
    }
}

/// Address block — node 3989:27399. Two-line headline, 2pt gap, two-line subtext, inline verify tick.
struct V2Address {
    var headline: String
    var subtext: String
    var verified: Bool = false
    /// Reserve the node's block height so the header measures the same whatever the copy is. The
    /// sheet header reserves two headline lines (48) and two address lines (36).
    var headlineBlock: CGFloat? = nil
    var subtextBlock: CGFloat? = nil
}

/// Trip Progress — node 2835:228299. The four Figma variants are just combinations of these three
/// fields, so there is no `variant` enum to keep in sync:
///   Default   fraction nil, icon false   → "20 stops"
///   Completed fraction nil, icon true    → "✓ 20 stops completed"
///   Ongoing   fraction .9,  icon true    → bar + "✓ 18/20 stops completed"
///   Started   fraction .05, icon true
struct V2ProgressSlot {
    var fraction: CGFloat? = nil
    var icon: Bool = true
    var caption: String
    /// Right-aligned counter (node 2835:228221, hidden by default).
    var trailing: String? = nil
}

/// Label / Value / optional Caption — node 2835:228335.
struct V2Pair: Identifiable {
    let id: String
    var label: String
    var value: String
    var caption: String? = nil
}

/// Key-value grid — nodes 2835:228314 (2 col) and 4088:177736 (3 col).
struct V2GridSlot {
    var columns: Int = 2
    var pairs: [V2Pair]
}

/// Pill action in the card's action row (node 3989:27406).
struct V2CardAction: Identifiable {
    let id: String
    var label: String
    var icon: String? = nil
    var role: V2Chip.Role = .primary
    var enabled: Bool = true
    /// Survives a terminal entity. "Terminal ⇒ no affordances" is about affordances that DRIVE
    /// execution; one that only reads back what happened still belongs there — a completed trip
    /// keeps `View details` and loses `Map` (frames 110/111).
    var isReadOnly: Bool = false
    var action: () -> Void = {}
}

extension Array where Element == V2CardAction {
    /// Apply the terminal rule once, here, rather than at each projection.
    func surviving(terminal: Bool) -> [V2CardAction] {
        terminal ? filter(\.isReadOnly) : self
    }
}

/// Circular icon action in the trailing gutter (node 3355:43419).
struct V2CardIconAction: Identifiable {
    let id: String
    var icon: String
    var enabled: Bool = true
    var action: () -> Void = {}
}

// MARK: Shape

enum V2CardShape {
    /// Node 3989:27391 — the big card. Also the page/sheet header, which is this node with `.plain`
    /// chrome: the board draws them as the same component.
    case card
    /// Node 1791:54552 — clickable list card with a trailing icon gutter.
    case clickable
    /// Node 1791:51860 — plain list item, details only.
    case item
}

/// Everything the three nodes measure differently. Read once, spent everywhere.
struct V2CardGeometry {
    var insetTop: CGFloat
    var insetSides: CGFloat
    var insetBottom: CGFloat
    /// Gap under the eyebrow row.
    var eyebrowGap: CGFloat
    /// Gap between headline / address / subtext / progress.
    ///
    /// `.card` lays its content out at a uniform 8 (subtext at y60 under a headline ending at 52);
    /// `.clickable` and `.item` bind the headline and its subtext into one 4pt "Details" block.
    var detailGap: CGFloat
    /// Line box for the headline.
    var headlineStyle: V2TextStyle
    var headlineLine: CGFloat
    var avatar: CGFloat

    init(_ shape: V2CardShape) {
        switch shape {
        case .card:
            insetTop = V2Space.headerInset
            insetSides = V2Space.headerInset
            insetBottom = V2Space.headerInsetBottom
            eyebrowGap = V2Space.eyebrowToHeadline
            detailGap = V2Space.eyebrowToHeadline
            headlineStyle = V2Font.sheetHeadline
            headlineLine = V2Metrics.headlineLine
            avatar = V2Metrics.avatarLarge
        case .clickable:
            insetTop = V2Space.cardInset
            insetSides = V2Space.cardInset
            insetBottom = V2Space.cardInset
            eyebrowGap = V2Space.eyebrowToHeadline
            detailGap = V2Space.headlineToSub
            headlineStyle = V2Font.label1
            headlineLine = V2Metrics.listHeadlineLine
            avatar = V2Metrics.avatarSmall
        case .item:
            insetTop = V2Space.cardInset
            insetSides = V2Space.cardInset
            insetBottom = V2Space.cardInset
            eyebrowGap = V2Space.eyebrowToHeadline
            detailGap = V2Space.headlineToSub
            headlineStyle = V2Font.label1
            headlineLine = V2Metrics.listHeadlineLine
            avatar = V2Metrics.avatarLarge
        }
    }
}

/// How the card paints itself. A header is the same node with the background taken away.
enum V2CardChrome {
    /// White, 12 radius, hairline stroke — a card in a list.
    case surface
    /// No background — the card IS the page/sheet header, which paints its own.
    case plain
    /// Tinted container (nested task cards).
    case tinted(Color)
}

// MARK: Model

struct V2ReasonSlot {
    /// One static label for every status and entity (cancelled / failed task, skipped / failed stop);
    /// only the value changes (decided 2026-10-26). The value is the entity's reason code as display
    /// text — who resolves code → text (BFA / reason registry / card) is open with the dev team.
    static let label = "Reason"
    let label: String
    let value: String
}

struct V2OrderSummaryRow: Identifiable {
    let status: V2TaskStatus
    let text: String
    var id: String { text + (status.label ?? "") }
}

struct V2CardModel {
    var shape: V2CardShape = .card
    var chrome: V2CardChrome = .surface

    var avatar: String? = nil
    var eyebrow: String? = nil
    /// Header eyebrows reference THIS entity, so they are copyable; a card eyebrow references another
    /// entity and is not (ui-decisions §10/§11). Set both to make it copyable: the human label and
    /// the value that lands on the clipboard.
    var eyebrowEntity: String? = nil
    var eyebrowValue: String? = nil
    /// Overrides the shape's eyebrow → headline gap (task rows use 4, frames 17 / 40).
    var eyebrowGap: CGFloat? = nil
    /// Status / SLA chips, in the eyebrow row.
    var chips: [V2ChipSlot] = []

    var headline: String = ""
    var headlineVerified: Bool = false
    /// Reserve a fixed number of headline lines so the block — and therefore the header — does not
    /// move when the copy changes length.
    var headlineLines: Int? = nil

    var address: V2Address? = nil
    var subtext: String? = nil
    var progress: V2ProgressSlot? = nil

    /// A labelled fact under the headline — "Cancellation Reason / Location could not be reached".
    var reason: V2ReasonSlot? = nil

    var tags: [V2ChipSlot] = []
    var grid: V2GridSlot? = nil
    /// Clubbed card: the club's orders grouped by status, under a hairline after the tags.
    var orderSummary: [V2OrderSummaryRow] = []

    var divider: Bool = false
    var actions: [V2CardAction] = []
    var iconActions: [V2CardIconAction] = []
    /// Keep the 48pt trailing gutter even when no icon action is showing, so copy wraps at the same
    /// width whether or not the navigate disc is there (trip and stop cards, frames 11 / 12 / 15).
    var reservesGutter: Bool = false

    /// Pin the whole card to the node height (headers do this; list cards flow).
    var height: CGFloat? = nil
    var onTap: (() -> Void)? = nil
}

// MARK: Rendering

struct V2CardView: View {
    let model: V2CardModel

    private var g: V2CardGeometry { V2CardGeometry(model.shape) }

    var body: some View {
        let card = VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: V2Space.avatarGap) {
                if let avatar = model.avatar {
                    EncoreIcon(iconName: avatar, size: g.avatar * 0.5)
                        .foregroundColor(HFColor.textSecondary)
                        .frame(width: g.avatar, height: g.avatar)
                        .background(HFColor.screen)
                        .clipShape(Circle())
                }

                column

                if model.iconActions.isEmpty {
                    if model.reservesGutter {
                        Color.clear.frame(width: V2Metrics.touchTarget, height: 1)
                    }
                } else {
                    HStack(spacing: V2Space.iconActionGap) {
                        ForEach(model.iconActions) { a in
                            Button(action: a.action) {
                                EncoreIcon(iconName: a.icon, size: V2Icon.action)
                                    .foregroundColor(HFColor.primary.opacity(a.enabled ? 1 : 0.4))
                                    .frame(width: V2Metrics.touchTarget, height: V2Metrics.touchTarget)
                                    .background(HFColor.screen)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .allowsHitTesting(a.enabled)
                        }
                    }
                }
            }

            if !model.actions.isEmpty {
                if model.divider {
                    Rectangle()
                        .fill(HFColor.divider)
                        .frame(height: V2Space.hairline)
                        .padding(.top, V2Space.contentToActions)
                }
                HStack(spacing: V2Space.chipGap) {
                    ForEach(model.actions) { a in
                        V2Chip(label: a.label, icon: a.icon, role: a.role,
                               enabled: a.enabled, action: a.action)
                    }
                }
                .frame(height: V2Metrics.touchTarget)
                .padding(.top, model.divider ? 0 : V2Space.contentToActions)
            }
        }
        .padding(.horizontal, g.insetSides)
        .padding(.top, g.insetTop)
        .padding(.bottom, g.insetBottom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: model.height, alignment: .top)

        Group {
            switch model.chrome {
            case .surface:
                card
                    .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(HFColor.divider, lineWidth: V2Space.hairline))
            case .plain:
                card
            case .tinted(let c):
                card
                    .background(RoundedRectangle(cornerRadius: 12).fill(c))
            }
        }
        // Only claim the tap when there IS a handler. An unconditional `onTapGesture` swallows
        // taps for any card placed inside an enclosing Button — the gesture wins, the closure is
        // nil, and the row goes silently dead. Attaching it conditionally means a card without a
        // handler stays transparent to whatever wraps it.
        .modifier(V2Tappable(onTap: model.onTap))
    }

    // The one content column. Gaps hang off each block's `.top` padding so a hidden slot collapses
    // cleanly — a `VStack(spacing:)` would leave the gap behind.
    @ViewBuilder private var column: some View {
        VStack(alignment: .leading, spacing: 0) {
            if model.eyebrow != nil || !model.chips.isEmpty {
                V2EyebrowRow {
                    if let eyebrow = model.eyebrow {
                        if let entity = model.eyebrowEntity, let value = model.eyebrowValue {
                            HFCopyableEyebrow(text: eyebrow, entity: entity, id: value)
                        } else {
                            V2Eyebrow(text: eyebrow)
                        }
                    }
                    ForEach(model.chips) { $0.view }
                }
                .padding(.bottom, model.eyebrowGap ?? g.eyebrowGap)
            }

            if !model.headline.isEmpty {
                headlineView(model.headline, verified: model.headlineVerified,
                             style: g.headlineStyle, lines: model.headlineLines)
            }

            if let address = model.address {
                VStack(alignment: .leading, spacing: V2Space.sheetHeadlineToAddress) {
                    headlineView(address.headline, verified: address.verified,
                                 style: g.headlineStyle, lines: nil)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .frame(height: address.headlineBlock, alignment: .topLeading)
                    Text(address.subtext)
                        .v2Text(V2Font.body2)
                        .foregroundColor(HFColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .frame(height: address.subtextBlock, alignment: .topLeading)
                }
                .padding(.top, model.headline.isEmpty ? 0 : g.detailGap)
            }

            if let subtext = model.subtext {
                Text(subtext)
                    .v2Text(V2Font.body2)
                    .foregroundColor(HFColor.textSecondary)
                    .padding(.top, g.detailGap)
            }

            if let progress = model.progress {
                V2ProgressRow(slot: progress)
                    .padding(.top, g.detailGap)
            }

            if let reason = model.reason {
                VStack(alignment: .leading, spacing: 0) {
                    Text(reason.label)
                        .v2Text(V2Font.body2)
                        .foregroundColor(HFColor.textSecondary)
                    Text(reason.value)
                        .v2Label(V2Font.label2)
                        .foregroundColor(HFColor.textPrimary)
                }
                .padding(.top, V2Space.contentToTags)
            }

            if !model.tags.isEmpty {
                HStack(spacing: V2Space.tagGap) {
                    ForEach(model.tags) { $0.view }
                }
                .frame(height: V2Metrics.chip)
                .padding(.top, V2Space.contentToTags)
            }

            if let grid = model.grid {
                V2GridView(slot: grid)
                    .padding(.top, V2Space.contentToTags)
            }

            if !model.orderSummary.isEmpty {
                Rectangle().fill(HFColor.divider).frame(height: V2Space.hairline)
                    .padding(.top, V2Space.contentToTags)
                VStack(alignment: .leading, spacing: Spacing.spacing4) {
                    Text("Order summary")
                        .v2Label(V2Font.label2)
                        .foregroundColor(HFColor.textPrimary)
                    VStack(spacing: Spacing.spacing8) {
                        ForEach(model.orderSummary) { row in
                            HStack(spacing: Spacing.spacing8) {
                                Text(row.text)
                                    .v2Label(V2Font.label2)
                                    .foregroundColor(HFColor.textPrimary)
                                Spacer(minLength: 0)
                                V2TaskStatusChip(status: row.status)
                            }
                            .padding(Spacing.spacing8)
                            .frame(height: 36)
                            .background(RoundedRectangle(cornerRadius: 8).fill(HFColor.screen))
                        }
                    }
                }
                .padding(.top, V2Space.contentToTags)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func headlineView(_ text: String, verified: Bool,
                              style: V2TextStyle, lines: Int?) -> some View {
        // The seal is part of the TEXT, not a sibling: it flows after the last word of a wrapped
        // name ("…Platform ✓", frames 12, 40) and never narrows the column the name wraps in.
        let label = titleText(text, verified: verified)
            .v2Text(style)
        if let lines {
            label.frame(height: style.lineHeight * CGFloat(lines), alignment: .top)
        } else {
            label
        }
    }
}

extension V2CardView {
    func titleText(_ text: String, verified: Bool) -> Text {
        let base = Text(text).foregroundColor(HFColor.textPrimary)
        guard verified, let seal = HFVerifiedTitle.sealImage else { return base }
        return base + Text("\u{00A0}") + Text(seal).foregroundColor(HFColor.success).baselineOffset(-2)
    }
}

/// Applies the tap target only when the card actually handles taps.
private struct V2Tappable: ViewModifier {
    let onTap: (() -> Void)?

    func body(content: Content) -> some View {
        if let onTap {
            content
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
        } else {
            content
        }
    }
}

// MARK: Trip Progress — node 2835:228299

struct V2ProgressRow: View {
    let slot: V2ProgressSlot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let fraction = slot.fraction {
                // The node draws a 4pt track inside a 12pt band — the band is what sets the gap to
                // the caption, so it is modelled rather than replaced by a padding value.
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(HFColor.primary.opacity(0.16))
                        // Work under way shows a stub even at 0 done (frames 15, 81): the bar says
                        // "started", the caption says how far.
                        Capsule().fill(HFColor.primary)
                            .frame(width: max(V2Metrics.progressStub, min(1, fraction) * geo.size.width))
                    }
                    .frame(height: V2Metrics.progressBar)
                    .frame(maxHeight: .infinity)
                }
                .frame(height: V2Metrics.progressBand)
            }

            HStack(spacing: V2Space.progressIconGap) {
                if slot.icon {
                    EncoreIcon(iconName: "LCheckCircle", size: V2Metrics.progressIcon)
                        .foregroundColor(HFColor.success)
                }
                Text(slot.caption)
                    .v2Label(V2Font.body2)
                    .foregroundColor(HFColor.textSecondary)
                if let trailing = slot.trailing {
                    Spacer(minLength: V2Space.chipGap)
                    Text(trailing)
                        .v2Label(V2Font.body2)
                        .foregroundColor(HFColor.textSecondary)
                    EncoreIcon(iconName: "LCheckCircle", size: V2Metrics.progressIcon)
                        .foregroundColor(HFColor.success)
                }
            }
            .frame(height: V2Metrics.subtextLine)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: Grid — nodes 2835:228314 / 4088:177736

struct V2GridView: View {
    let slot: V2GridSlot

    // NOT a LazyVGrid. Lazy containers build their cells after the container is inserted, so the
    // cells skip its transition: in a sheet rising from the bottom, the labels and values appeared
    // at their final position first and the sheet slid in under them. Plain stacks move as one.
    var body: some View {
        let n = max(1, slot.columns)
        let rows = stride(from: 0, to: slot.pairs.count, by: n).map {
            Array(slot.pairs[$0..<min($0 + n, slot.pairs.count)])
        }
        VStack(alignment: .leading, spacing: V2Space.gridGap) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: V2Space.gridGap) {
                    ForEach(row) { V2PairView(pair: $0) }
                    ForEach(0..<(n - row.count), id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                    }
                }
            }
        }
    }
}

/// Label / Value / optional Caption — node 2835:228335. Label and value sit flush (no gap); the
/// caption hangs 2 below.
struct V2PairView: View {
    let pair: V2Pair
    /// Value in label1 14/20 instead of label2 12/18 — the scan footer counter and the scanner grid
    /// (frames 29, 50) carry the prominent value.
    var prominent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(pair.label)
                .v2Label(V2Font.body2)
                .foregroundColor(HFColor.textSecondary)
            Text(pair.value)
                .v2Label(prominent ? V2Font.label1 : V2Font.label2)
                .foregroundColor(HFColor.textPrimary)
            if let caption = pair.caption {
                Text(caption)
                    .v2Label(V2Font.body2)
                    .foregroundColor(HFColor.textSecondary)
                    .padding(.top, V2Space.pairCaptionGap)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
