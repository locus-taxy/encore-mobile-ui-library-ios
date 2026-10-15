import SwiftUI

// MARK: - P2 The scan workflow
//
// Canonical source: the `Scan ✅` page, section `Camera scan` (5362:33948) — the V2 board only draws
// a placeholder for it. Frames referenced below are that section's, not the V2 board's.
//
// Geometry read off frame 05 (4458:250973):
//   tabs         360 × 48 directly under the bar
//   HU rows      360 × 64, edge-to-edge, stacked at a 65 pitch — a hairline between them, NOT cards
//   FAB          90 × 48 at x254 / y640 — a 40pt pill inside a 48pt target, 16 from the right edge
//   footer       <DialogActions> 360 × 80 — a Label/Value pair at 16, a 160 × 48 action at 184
//
// The footer counter reuses the SAME Label Value Pair component as the grid (node 2835:228335), and
// the scanner's result sheet reuses the grid itself. Neither is re-drawn here.

// MARK: Tabs

struct V2Tab: Identifiable, Equatable {
    let id: String
    var label: String
    var count: Int
    var title: String { "\(label) (\(count))" }
}

/// Underline is drawn as an OVERLAY on the label, not as a sibling: a sibling `Rectangle` is
/// width-greedy and stretches the tab.
struct V2Tabs: View {
    let tabs: [V2Tab]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button { selection = tab.id } label: {
                    Text(tab.title)
                        .v2Label(V2Font.buttonMedium)
                        .foregroundColor(selection == tab.id ? HFColor.primary : HFColor.textSecondary)
                        .padding(.horizontal, Spacing.spacing12)
                        .frame(height: V2Metrics.tabBar)
                        .overlay(alignment: .bottom) {
                            if selection == tab.id {
                                Rectangle()
                                    .fill(HFColor.primary)
                                    .frame(height: V2Metrics.tabUnderline)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .frame(height: V2Metrics.tabBar)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.surface)
    }
}

// MARK: List section header — shared by every grouped list (scan orders, inbox days)

/// `ORDER_ID_… (n)` with its accordion glyph — 44 tall on the grey, pl12 (frame 29).
struct V2ListSectionHeader: View {
    let title: String
    let count: Int
    let expanded: Bool
    var onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.spacing4) {
                EncoreIcon(iconName: expanded ? "LExpandLess" : "LExpandMore", size: V2Icon.inline)
                    .foregroundColor(V2Token.actionActive)
                HStack(spacing: 2) {
                    Text(title).lineLimit(1).truncationMode(.middle)
                    Text("(\(count))")
                }
                .v2Label(V2Font.overline2)
                .foregroundColor(HFColor.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(.leading, Spacing.spacing12)
            .padding(.trailing, Spacing.spacing16)
            .frame(height: V2Metrics.listHeader)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: FAB — node 4458:253196

struct V2Fab: View {
    let label: String
    var icon: String = "LCameraAlt"
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: V2Space.chipGap) {
                EncoreIcon(iconName: icon, size: V2Icon.inline)
                    .foregroundColor(HFColor.primary)
                Text(label)
                    .v2Label(V2Font.buttonMedium)
                    .foregroundColor(HFColor.primary)
            }
            .padding(.horizontal, V2Space.headerInset)
            .frame(height: V2Metrics.fabPill)
            .background(HFColor.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(HFColor.primary, lineWidth: 1))
            // E2 — 0 4 8 @16% (frame 29).
            .shadow(color: Color(.sRGB, red: 17/255, green: 19/255, blue: 24/255, opacity: 0.16),
                    radius: 4, x: 0, y: 4)
            .frame(height: V2Metrics.touchTarget)
        }
        .buttonStyle(.plain)
    }
}

// MARK: The HU list page — frames 29–34 (clubbed), 48 / 51 / 52 (single task)

/// One order's units on the scan list. A clubbed stop shows one collapsible section per order; a
/// single task is one section with no header.
struct V2ScanSection: Identifiable {
    let id: Int
    var title: String?
    var units: [V2HU]
}

struct V2ScanPage: View {
    let task: V2Task
    var sections: [V2ScanSection] = []
    var subtitle: String = ""
    var onClose: () -> Void = {}
    var onScan: () -> Void = {}
    var onNext: () -> Void = {}
    /// Multi-select `Mark scanned` (frame 31) — marks the chosen units without the camera.
    var onMarkScanned: ([String]) -> Void = { _ in }

    @State private var tab = "todo"
    /// Sections the rider has opened. The first starts open (frame 29).
    @State private var expanded: Set<Int> = []
    @State private var selected: Set<String> = []

    /// Checkboxes and multi-select exist only where a page lists several orders (29 vs 48).
    private var selectable: Bool { sections.count > 1 }
    private var selecting: Bool { !selected.isEmpty }

    private var todo: [V2HU] { task.units.filter { !$0.scanned } }
    private var done: [V2HU] { task.units.filter(\.scanned) }

    private func visible(_ units: [V2HU]) -> [V2HU] {
        switch tab {
        case "todo": return units.filter { !$0.scanned }
        case "done": return units.filter(\.scanned)
        default:     return units
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if selecting {
                V2Navbar(back: { selected = [] }, backIcon: "LCross",
                         title: "\(selected.count) selected")
            } else {
                V2Navbar(title: "Scan HUs",
                         subtitle: subtitle,
                         actions: [V2NavAction(id: "kebab", icon: "LOverflowVertical"),
                                   V2NavAction(id: "close", icon: "LCross", action: onClose)])
            }

            if selecting {
                selectAllRow
            } else {
                V2Tabs(tabs: [V2Tab(id: "all", label: "All", count: task.units.count),
                              V2Tab(id: "todo", label: "To do", count: todo.count),
                              V2Tab(id: "done", label: "Done", count: done.count)],
                       selection: $tab)
            }
            HFSeam()

            ZStack(alignment: .bottomTrailing) {
                list
                if !selecting {
                    V2FabSlot {                   // rides up while a toast is showing (frame 32)
                        V2Fab(label: "Scan", action: onScan)
                    }
                    .padding(.trailing, V2Space.pageMargin)
                    .padding(.bottom, V2Space.contentToActions)
                }
            }

            footer
        }
        .background(HFColor.screen)
        .onAppear { if let first = sections.first { expanded = [first.id] } }
    }

    @ViewBuilder private var list: some View {
        if sections.allSatisfy({ visible($0.units).isEmpty }) {
            // The To-do tab empties as the last unit is scanned; that IS the "done" signal, so the
            // copy points at the next step rather than reporting an absence (32, 51).
            VStack(spacing: 0) {
                Image.withName("HFAllScannedArt")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 125, height: 120)
                Text("All HUs scanned successfully")
                    .v2Label(V2Font.sheetHeadline)
                    .foregroundColor(HFColor.textPrimary)
                    .padding(.top, Spacing.spacing16)
                Text("Move to next step")
                    .v2Label(V2Font.body2)
                    .foregroundColor(HFColor.textSecondary)
                    .padding(.top, Spacing.spacing4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: V2Space.sectionSeam) {   // not lazy: rows must ride the cover's rise
                    ForEach(sections) { section in
                        let units = visible(section.units)
                        if !units.isEmpty {
                            if let title = section.title {
                                header(section, title: title, count: section.units.count)
                            }
                            if section.title == nil || expanded.contains(section.id) {
                                ForEach(units) { hu in
                                    V2HURow(hu: hu,
                                            checkable: selectable && !hu.scanned,
                                            checked: selected.contains(hu.id),
                                            onToggle: { toggle(hu.id) })
                                }
                            }
                        }
                    }
                }
                Color.clear.frame(height: V2Layout.fabClearance)
            }
        }
    }

    private func header(_ section: V2ScanSection, title: String, count: Int) -> some View {
        V2ListSectionHeader(title: title, count: count, expanded: expanded.contains(section.id)) {
            withAnimation(V2Motion.standard) {
                if expanded.contains(section.id) { expanded.remove(section.id) } else { expanded.insert(section.id) }
            }
        }
    }

    /// Frame 30: replaces the tabs while selecting. Ticking it also opens every section.
    private var selectAllRow: some View {
        let candidates = task.units.filter { !$0.scanned }.map(\.id)
        let all = !candidates.isEmpty && Set(candidates).isSubset(of: selected)
        return Button {
            if all { selected = [] } else {
                selected = Set(candidates)
                expanded = Set(sections.map(\.id))
            }
        } label: {
            // Frame 30: checkbox target at x0, label at x40 (the checkbox's −8 trailing margin).
            HStack(spacing: -Spacing.spacing8) {
                V2Checkbox(checked: all)
                Text("Select all")
                    .v2Label(V2Font.chipLabel)
                    .foregroundColor(HFColor.textPrimary)
                Spacer(minLength: 0)
            }
            .frame(height: V2Metrics.tabBar)
            .background(HFColor.surface)
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ id: String) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    /// Split footer (node 5326:216138): the counter pair and a 160 × 48 Next — or, while selecting,
    /// a hug-right green `Mark scanned` (frame 30).
    private var footer: some View {
        HFToastFooter {
            HStack(alignment: .center, spacing: Spacing.spacing8) {
                if selecting {
                    Spacer(minLength: 0)
                    V2Button(label: "Mark scanned", role: .success, leadingIcon: "LCheck", hug: true) {
                        let ids = Array(selected)
                        selected = []
                        onMarkScanned(ids)
                    }
                } else {
                    V2PairView(pair: V2Pair(id: "scanned", label: "HUs scanned",
                                            value: "\(task.scannedUnits)/\(task.units.count)"),
                               prominent: true)
                    Spacer(minLength: 0)
                    V2Button(label: "Next", enabled: task.allScanned, action: onNext)
                        .frame(width: V2Metrics.footerAction)
                }
            }
            .padding(.horizontal, V2Space.headerInset)
            .frame(height: V2Metrics.dialogActions)
            .padding(.bottom, max(0, HFLayout.bottomInset - Spacing.spacing16))
            .frame(maxWidth: .infinity)
            // E1, like every footer — a shadow separator, not a hairline (frame 29).
            .background(
                Rectangle()
                    .fill(HFColor.surface)
                    .shadow(color: Color(.sRGB, red: 17/255, green: 19/255, blue: 24/255, opacity: 0.16),
                            radius: 2, x: 0, y: 0)
            )
        }
    }
}

/// MUI checkbox: 24 glyph (18 box, same for blank and ticked) in a 48 target.
struct V2Checkbox: View {
    let checked: Bool
    var body: some View {
        EncoreIcon(iconName: checked ? "LCheckboxFilled" : "LCheckboxBlank", size: 24)
            .foregroundColor(checked ? HFColor.primary : V2Token.actionActive)
            .frame(width: V2Metrics.touchTarget, height: V2Metrics.touchTarget)
    }
}

/// One handling unit. Hugs its content: py8; "HU ID" label over the code (shown in full, wrapping),
/// then "0/1 box" with the count in text/primary. Checkable rows (a clubbed page) lead with a 48 checkbox, top-aligned (29); single-task
/// rows start at 16 (48).
struct V2HURow: View {
    let hu: V2HU
    var checkable: Bool = false
    var checked: Bool = false
    var onToggle: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: checkable ? Spacing.spacing8 : Spacing.spacing12) {
            HStack(alignment: .top, spacing: Spacing.spacing4) {
                if checkable {
                    Button(action: onToggle) { V2Checkbox(checked: checked) }
                        .buttonStyle(.plain)
                }
                VStack(alignment: .leading, spacing: Spacing.spacing4) {
                    // Same Label/Value pairing as the HU card and the scanner: a static "HU ID" over
                    // the code, shown in full as the backend sends it.
                    VStack(alignment: .leading, spacing: 0) {
                        Text("HU ID")
                            .v2Label(V2Font.body2)
                            .foregroundColor(HFColor.textSecondary)
                        Text(hu.id)
                            .v2Text(V2Font.label1)
                            .foregroundColor(HFColor.textPrimary)
                    }
                    (Text("\(hu.scanned ? hu.boxes : 0)").foregroundColor(HFColor.textPrimary)
                        + Text("/\(hu.boxLabel)").foregroundColor(HFColor.textSecondary))
                        .v2Label(V2Font.body2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            EncoreIcon(iconName: "LOverflowVertical", size: V2Icon.bar)
                .foregroundColor(V2Token.actionActive)
                .frame(width: 34, height: V2Metrics.touchTarget)
        }
        .padding(.leading, checkable ? Spacing.spacing4 : V2Space.pageMargin)
        .padding(.trailing, Spacing.spacing4)
        .padding(.vertical, Spacing.spacing8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.surface)
    }
}

// MARK: The scanner — frames 06 → 19

struct V2ScannerPage: View {
    let task: V2Task
    /// What the last read produced. Nil before the first read (frame 49's empty state).
    let result: V2Engine.ScanResult?
    var onClose: () -> Void = {}
    var onRead: () -> Void = {}
    var onUndo: () -> Void = {}

    /// `Others/Global Left Pane` — the dark camera area. Kept empty by decision; no feed is drawn.
    private static let camera = Color(.sRGB, red: 34/255, green: 38/255, blue: 47/255, opacity: 1) // #22262F
    /// The result sheet keeps one height across states, so a read never resizes the camera area (49/50).
    private static let sheetHeight: CGFloat = 305

    var body: some View {
        VStack(spacing: 0) {
            viewfinder
            resultSheet
        }
        .background(Self.camera)
    }

    /// Tapping the empty area stands in for the camera reading the next unit.
    private var viewfinder: some View {
        VStack(spacing: 0) {
            chrome
                .padding(.top, V2Layout.statusStrip)
            Button(action: onRead) {
                Color.clear.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxHeight: .infinity)
            progress
                .padding(.horizontal, V2Space.pageMargin)
                .padding(.bottom, Spacing.spacing12)
        }
    }

    /// ⌄ dismisses (left); flashlight + manual entry (right). White, 24 in 48, px8 (frame 49).
    private var chrome: some View {
        HStack(spacing: 0) {
            chromeButton("LExpandMore", action: onClose)
            Spacer(minLength: 0)
            chromeButton("LFlashOn")
            chromeButton("LKeyboard")
        }
        .padding(.horizontal, Spacing.spacing8)
        .frame(height: V2Metrics.touchTarget)
    }

    private func chromeButton(_ icon: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            EncoreIcon(iconName: icon, size: V2Icon.bar)
                .foregroundColor(.white)
                .frame(width: V2Metrics.touchTarget, height: V2Metrics.touchTarget)
        }
        .buttonStyle(.plain)
    }

    /// The Trip Progress block in white on the camera: 4pt bar (white track, success fill, r4) in a
    /// 12 band, then "n/m HUs scanned" — HUs, not boxes.
    private var progress: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white)
                    Capsule().fill(HFColor.success)
                        .frame(width: max(V2Metrics.progressStub, geo.size.width * fraction))
                }
                .frame(height: V2Metrics.progressBar)
                .frame(maxHeight: .infinity)
            }
            .frame(height: V2Metrics.progressBand)
            HStack(spacing: V2Space.progressIconGap) {
                EncoreIcon(iconName: "LCheckCircle", size: V2Metrics.progressIcon)
                    .foregroundColor(.white)
                Text("\(task.scannedUnits)/\(task.units.count) HUs scanned")
                    .v2Label(V2Font.body2)
                    .foregroundColor(.white)
            }
            .frame(height: V2Metrics.subtextLine)
        }
    }

    private var fraction: CGFloat {
        CGFloat(task.scannedUnits) / CGFloat(max(1, task.units.count))
    }

    /// Grey shell, r12 top, handle, one white card, a 40pt action row — the same in every state.
    private var resultSheet: some View {
        VStack(spacing: Spacing.spacing12) {
            Capsule().fill(HFColor.divider).frame(width: 80, height: 4)
            card
                .frame(maxHeight: .infinity)
            actions
        }
        .padding(Spacing.spacing12)
        .padding(.bottom, max(0, HFLayout.bottomInset - Spacing.spacing12))
        .frame(height: Self.sheetHeight + max(0, HFLayout.bottomInset - Spacing.spacing12))
        .frame(maxWidth: .infinity)
        .background(
            UnevenTopRect(radius: 12).fill(HFColor.screen)
        )
    }

    @ViewBuilder private var card: some View {
        switch result {
        case .none:
            state(art: "LScanEmptyState", title: "Start by scanning an Entity ID",
                  sub: "Details of the scan will be displayed here")
        case .notRecognised:
            state(art: "LScanErrorSeal", title: "HU not recognised", sub: "Check the code and try again")
        case .scanned(let hu):
            unit(hu, seal: "LScanSuccessSeal", note: "Great! Now scan its next HU ID", tint: HFColor.success)
        case .alreadyScanned(let hu):
            unit(hu, seal: "LScanInfoSeal", note: "HU ID already scanned", tint: HFColor.primary)
        }
    }

    /// Empty / error card: art 125 × 120 → 16 → h6 title → 4 → body2 (frame 49). r12 all round.
    private func state(art: String, title: String, sub: String) -> some View {
        VStack(spacing: 0) {
            Image.withName(art)
                .resizable()
                .scaledToFit()
                .frame(width: 125, height: 120)
            Text(title)
                .v2Label(V2Font.sheetHeadline)
                .foregroundColor(HFColor.textPrimary)
                .padding(.top, Spacing.spacing16)
            Text(sub)
                .v2Label(V2Font.body2)
                .foregroundColor(HFColor.textSecondary)
                .padding(.top, Spacing.spacing4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
    }

    /// Scanned card (frame 50): top corners r12 with a 0.5 stroke on three sides; HU ID in h5 with the
    /// note under it and the 48 seal beside; then the grid, HU Category across both columns.
    private func unit(_ hu: V2HU, seal: String, note: String, tint: Color) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.spacing16) {
                HStack(alignment: .top, spacing: Spacing.spacing24) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("HU ID")
                            .v2Label(V2Font.body2)
                            .foregroundColor(HFColor.textSecondary)
                        Text(hu.id)
                            .v2Text(V2Font.h5)
                            .foregroundColor(HFColor.textPrimary)
                        Text(note)
                            .v2Label(V2Font.label2)
                            .foregroundColor(tint)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image.withName(seal)
                        .resizable()
                        .scaledToFit()
                        .frame(width: V2Icon.seal, height: V2Icon.seal)
                }
                HStack(alignment: .top, spacing: V2Space.gridGap) {
                    V2PairView(pair: V2Pair(id: "code", label: "HU code", value: hu.code), prominent: true)
                    V2PairView(pair: V2Pair(id: "boxes", label: "Boxes", value: "\(hu.boxes)/\(hu.boxes)"),
                               prominent: true)
                }
                V2PairView(pair: V2Pair(id: "cat", label: "HU Category", value: hu.category), prominent: true)
            }
            .padding(.horizontal, Spacing.spacing12)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UnevenTopRect(radius: 12).fill(HFColor.surface))
        .overlay(UnevenTopRect(radius: 12, open: true).stroke(HFColor.divider, lineWidth: V2Space.hairline))
        .clipShape(UnevenTopRect(radius: 12))
    }

    /// 40pt text-button row under the card: Undo (primary) and Raise an exception (error). Present
    /// but empty in the empty state, so the card height never moves.
    private var actions: some View {
        HStack {
            if case .scanned = result {
                textButton("Undo", tint: HFColor.primary, action: onUndo)
                Spacer(minLength: 0)
                textButton("Raise an exception", tint: Color.encore("Error/Main"))
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
    }

    private func textButton(_ label: String, tint: Color, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            Text(label)
                .v2Label(V2Font.buttonLarge)
                .foregroundColor(tint)
                .padding(.horizontal, 11)
                .frame(height: 40)
        }
        .buttonStyle(.plain)
    }
}

/// A rectangle with only its top corners rounded (iOS 15 has no `UnevenRoundedRectangle`). `open`
/// leaves the bottom edge undrawn, for a three-sided stroke.
struct UnevenTopRect: Shape {
    let radius: CGFloat
    var open: Bool = false

    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + radius))
        p.addQuadCurve(to: CGPoint(x: r.minX + radius, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - radius, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + radius), control: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        if !open { p.closeSubpath() }
        return p
    }
}
