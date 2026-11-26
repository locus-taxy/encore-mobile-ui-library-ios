import SwiftUI

// MARK: - Info block (DP-9789)
//
// The slot under a page header is for what the driver should KNOW before acting — the stop's visit
// note (S-D12, `Stop.notes`), the customer's own instruction (per order, K-D18), the delivery
// questionnaire (`deliveryInquiries`, DP-9482), and any future label → value content (K-D09).
// It is ONE pattern on both the stop and the task page: a list of typed sections. New content is a
// new section, never a new banner.
//
// Three presentations are under test (V2Variant): inline, preview + sheet, collapsible.

/// One questionnaire answer as the BFA sends it (DP-9482): `{inquiryCode, responseOption, responseValue}`.
/// The option is YES / NO / NA; the value is the customer's note, or the answer itself when there is
/// no option (FLOOR_NO: 3).
struct V2Inquiry: Identifiable {
    let code: String
    var option: String? = nil
    var value: String? = nil
    var id: String { code }
}

/// A block in the slot: paragraphs of free text, or Label Value Pairs at a column density (1–3).
/// No headings on real content (17 Nov): the sheet's title names it, the pair labels name each answer.
struct V2InfoSection: Identifiable {
    enum Body {
        case text([String])
        case pairs([V2Pair])
    }
    let id: String
    var heading: String = ""
    var body: Body
    var columns: Int = 2

    /// Every paragraph and every pair is one item — the X in "View all (X)".
    var itemCount: Int {
        switch body {
        case .text(let p): return p.count
        case .pairs(let p): return p.count
        }
    }
}

// MARK: Labels and answers

enum V2InquiryText {
    /// Readable labels are a follow-up (DP-9482 out of scope: i18n or a tenant code list, e.g.
    /// `PARKING_PERMIT_NEEDED` → "Parking permit needed?"). This table stands in for that list and
    /// covers the codes in DP-9482's stg-uk example.
    private static let labels: [String: String] = [
        "PARKING_PERMIT_NEEDED": "Parking permit needed?",
        "STAIR_CASE_SIZE": "Staircase size",
        "STAIR_CASE_WIDE_ENOUGH": "Staircase wide enough?",
        "FLOOR_NO": "Floor",
    ]

    /// Fallback for a code with no label: the code in sentence case, so a new code still reads as
    /// words — `STAIR_CASE_SIZE` → "Stair case size". Never hidden.
    static func label(_ code: String) -> String {
        if let l = labels[code] { return l }
        let words = code.split(separator: "_").map { $0.lowercased() }.joined(separator: " ")
        return words.prefix(1).uppercased() + words.dropFirst()
    }

    static func isNA(_ q: V2Inquiry) -> Bool { q.option?.uppercased() == "NA" }

    /// (answer, note). YES/NO → Yes/No with the value as the note; no option → the value is the answer.
    static func answer(_ q: V2Inquiry) -> (String, String?) {
        switch q.option?.uppercased() {
        case "YES": return ("Yes", q.value)
        case "NO": return ("No", q.value)
        case let o?: return (label(o), q.value)
        case nil: return (q.value ?? "", nil)
        }
    }
}

/// Dummy example (17 Nov): the slot's anatomy with lorem ipsum — a text block, then
/// Label Value Pairs at 1 and 2 columns (3 dropped 17 Nov: too clustered). Same for the stop ("Stop instructions") and the task
/// ("Task notes"); only the title differs. Launch with POC_VARIANT=infoSheet,infoDummy.
enum V2InfoDummy {
    static let sections: [V2InfoSection] = [
        V2InfoSection(id: "t-text", body: .text([
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation."])),
        V2InfoSection(id: "t-1col", body: .pairs([
            V2Pair(id: "a1", label: "Label", value: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
                   caption: "Caption lorem ipsum dolor sit amet"),
            V2Pair(id: "a2", label: "Label", value: "Lorem ipsum dolor sit amet"),
        ]), columns: 1),
        V2InfoSection(id: "t-2col", body: .pairs([
            V2Pair(id: "b1", label: "Label", value: "Value", caption: "Caption lorem ipsum"),
            V2Pair(id: "b2", label: "Label", value: "Value"),
            V2Pair(id: "b3", label: "Label", value: "Value"),
            V2Pair(id: "b4", label: "Label", value: "Value"),
        ]), columns: 2),
    ]
}

extension V2Task { var infoTitle: String { "Task notes" } }
extension V2Stop { var infoTitle: String { "Stop instructions" } }

// MARK: Projections — what each entity puts in the slot

extension V2Task {
    /// The customer's free-text instruction — the BFA's `orderInstructions` (DP-9482: special
    /// instructions, else special notes, else the DELIVERY_INSTRUCTIONS value). Shown once.
    var effectiveInstruction: String? {
        if let i = instruction, !i.isEmpty { return i }
        return inquiries.first { $0.code == "DELIVERY_INSTRUCTIONS" }?.value
    }

    var infoSections: [V2InfoSection] {
        var out: [V2InfoSection] = []
        // Authority to leave is NOT a note here: it is a tag on the card and in the task header
        // (Figma 10374:390537, updated 26 Nov). Task notes hold the customer's words only.
        if V2Variant.isOn(.infoDummy) { return V2InfoDummy.sections }
        if let note = effectiveInstruction, !note.isEmpty {
            out.append(V2InfoSection(id: "notes", body: .text([note])))
        }
        // In the order they appear on the order (DP-9482 AC). NA answers are dropped: "not
        // applicable" gives the driver nothing to act on.
        let pairs = inquiries
            .filter { $0.code != "DELIVERY_INSTRUCTIONS" && !V2InquiryText.isNA($0) }
            .map { q -> V2Pair in
                let (a, note) = V2InquiryText.answer(q)
                return V2Pair(id: q.code, label: V2InquiryText.label(q.code), value: a, caption: note)
            }
        if !pairs.isEmpty {
            out.append(V2InfoSection(id: "inquiries", body: .pairs(pairs)))
        }
        return out
    }
}

extension V2Stop {
    var infoSections: [V2InfoSection] {
        if V2Variant.isOn(.infoDummy) { return V2InfoDummy.sections }
        guard let n = notes, !n.isEmpty else { return [] }
        return [V2InfoSection(id: "stopnote", body: .text([n]))]
    }
}

// MARK: - Presentations

/// Which presentation is live. Baseline (no variant) keeps the shipped single-line banner.
enum V2InfoMode {
    case baseline, inline, preview, collapsible

    static var current: V2InfoMode {
        if V2Variant.isOn(.infoInline) { return .inline }
        if V2Variant.isOn(.infoSheet) { return .preview }
        if V2Variant.isOn(.infoCollapse) { return .collapsible }
        return .baseline
    }
}

/// The slot itself. Sits under the header card on the header's white, 16 sides / 12 bottom — the
/// same inset the instruction banner already used.
struct V2InfoSlot: View {
    let title: String
    let sections: [V2InfoSection]
    /// What today's one-line banner shows (baseline, no variant): the customer instruction only.
    var baseline: String? = nil
    var onViewAll: () -> Void = {}

    var body: some View {
        if !sections.isEmpty {
            Group {
                switch V2InfoMode.current {
                case .baseline:
                    if let t = baseline {
                        V2InstructionBanner(text: t)
                    }
                case .inline:
                    V2InfoInline(sections: sections)
                case .preview:
                    V2InfoPreview(title: title, sections: sections, onViewAll: onViewAll)
                case .collapsible:
                    V2InfoCollapsible(sections: sections,
                                      expanded: V2Variant.isOn(.infoOpen))
                }
            }
            .padding(.horizontal, V2Space.headerInset)
            .padding(.bottom, V2Space.headerInsetBottom)
            // The stop sheet's header proposes less height than the slot needs; never compress.
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Section content shared by every presentation: text → body1 paragraph; pairs → the key-value grid
/// (node 2835:228314), question as label, answer as value, the customer's note as caption.
struct V2InfoSectionBody: View {
    let section: V2InfoSection

    var body: some View {
        switch section.body {
        case .text(let paragraphs):
            VStack(alignment: .leading, spacing: Spacing.spacing8) {
                ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, t in
                    Text(t)
                        .v2Text(V2Font.body1)
                        .foregroundColor(HFColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .pairs(let p):
            V2GridView(slot: V2GridSlot(columns: section.columns, pairs: p, wraps: true))
        }
    }
}

private struct V2InfoHeading: View {
    let text: String
    var body: some View {
        Text(text)
            .v2Label(V2Font.label1)
            .foregroundColor(HFColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: A — inline

/// Every section, in full, in a bordered container. Nothing is hidden; the page grows with it.
struct V2InfoInline: View {
    let sections: [V2InfoSection]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing16) {
            ForEach(sections) { s in
                VStack(alignment: .leading, spacing: Spacing.spacing8) {
                    if !s.heading.isEmpty { V2InfoHeading(text: s.heading) }
                    V2InfoSectionBody(section: s)
                }
            }
        }
        .padding(Spacing.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(HFColor.screen))
    }
}

// MARK: B — preview + sheet

/// The info banner with a title and, when there is more than it shows, "View all (n)".
///   instruction only   → instruction, 2 lines
///   answers only       → answer summary "Label: Value · …", 2 lines
///   both               → instruction (1 line) + answer summary (1 line)
///   stop note          → the note, 2 lines
/// The link appears when the entity holds more than one item, or one item too long for its lines.
struct V2InfoPreview: View {
    let title: String
    let sections: [V2InfoSection]
    var onViewAll: () -> Void = {}

    private var paragraphs: [String] {
        sections.flatMap { s -> [String] in if case .text(let p) = s.body { return p } else { return [] } }
    }
    private var pairs: [V2Pair] {
        sections.flatMap { s -> [V2Pair] in if case .pairs(let p) = s.body { return p } else { return [] } }
    }
    private var digest: String? {
        pairs.isEmpty ? nil : pairs.map {
            // A question label answers itself: "Parking permit needed? No", never "needed?: No".
            $0.label.hasSuffix("?") ? "\($0.label) \($0.value)" : "\($0.label): \($0.value)"
        }.joined(separator: " \u{00B7} ")
    }
    /// The message is the first two of [paragraphs…, answer summary]: one item gets two lines,
    /// two or more get one line each.
    private var items: [String] { paragraphs + (digest.map { [$0] } ?? []) }
    private var total: Int { sections.reduce(0) { $0 + $1.itemCount } }

    /// Rough fit for the prototype: ~40 characters a line at 14pt across the banner's text column.
    private var overflows: Bool {
        let perLine = 40
        if items.count == 1 { return items[0].count > perLine * 2 || pairs.contains { $0.caption != nil } }
        return items.prefix(2).contains { $0.count > perLine }
    }

    private var link: String? {
        if total > 1 { return "View all (\(total))" }
        return overflows ? "View all" : nil
    }

    /// Frame 04: every item runs on as one paragraph, clamped to two lines with a tail ellipsis —
    /// the clamp lands wherever the text does, so no item gets a line it doesn't fill.
    /// Frame 04: items run on as one paragraph. Notes are sentences (full stop added if missing);
    /// answers are data ("Floor: 3"), never punctuated, joined by " · ".
    private var units: [(text: String, isAnswer: Bool)] {
        paragraphs.map { t in (t.last.map { ".?!".contains($0) } == true ? t : t + ".", false) }
            + pairs.map { p in (p.label.hasSuffix("?") ? "\(p.label) \(p.value)" : "\(p.label): \(p.value)", true) }
    }
    private func join(_ u: ArraySlice<(text: String, isAnswer: Bool)>) -> String {
        var out = ""
        for (i, x) in u.enumerated() {
            if i > 0 { out += (x.isAnswer && u[u.startIndex + i - 1].isAnswer) ? " \u{00B7} " : " " }
            out += x.text
        }
        return out
    }
    /// Every whole-item prefix, longest first — the banner takes the longest that fits two lines.
    private var fits: [String] { (1...max(1, units.count)).reversed().map { join(units.prefix($0)) } }
    private var flowed: String { join(units[...]) }

    var body: some View {
        if V2Variant.isOn(.infoIcon) {
            V2InstructionBanner(title: title,
                                text: items.first ?? "",
                                detail: items.count > 1 ? items[1] : nil,
                                link: link,
                                onLink: onViewAll)
        } else {
            V2InstructionBanner(title: title,
                                text: flowed,
                                link: total > 1 ? "View all (\(total))" : "View all",
                                showsIcon: false,
                                fits: units.isEmpty ? nil : fits,
                                linkEvenIfAllShown: pairs.contains { $0.caption != nil },
                                onLink: onViewAll)
        }
    }
}

/// The full sheet B opens: one white section per info section on the grey sheet, 1px seams —
/// the `View details` sheet construction (node 10956:665730).
struct V2InfoSheet: View {
    let title: String
    let sections: [V2InfoSection]
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HFSheetTitle(title: title, onClose: onClose)
                .background(HFColor.surface)
            HFSeam()
            ScrollView {
                VStack(spacing: V2Space.sectionSeam) {
                    ForEach(sections) { s in
                        VStack(alignment: .leading, spacing: V2Space.headingToGrid) {
                            if !s.heading.isEmpty { V2InfoHeading(text: s.heading) }
                            V2InfoSectionBody(section: s)
                        }
                        .padding(.horizontal, V2Space.headerInset)
                        .padding(.top, V2Space.detailsSectionTop)
                        .padding(.bottom, V2Space.detailsSectionBottom)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(HFColor.surface)
                    }
                }
                // Grey only shows through the 1px seams; any slack below the last section stays white.
                .background(HFColor.screen)
            }
            .frame(maxHeight: V2Layout.drawableHeight * 0.7)
            .fixedSize(horizontal: false, vertical: true)
        }
        .background(HFColor.surface)
        .padding(.bottom, HFLayout.bottomInset)
        .background(HFColor.surface)
    }
}

// MARK: C — collapsible

/// A 48-tall row naming the block and its count; expands in place to the inline content.
struct V2InfoCollapsible: View {
    let sections: [V2InfoSection]
    @State var expanded: Bool

    private var total: Int { sections.reduce(0) { $0 + $1.itemCount } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { withAnimation(V2Motion.standard) { expanded.toggle() } } label: {
                HStack(spacing: Spacing.spacing8) {
                    Text("Details (\(total))")
                        .v2Label(V2Font.label1)
                        .foregroundColor(HFColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    EncoreIcon(iconName: expanded ? "LExpandLess" : "LExpandMore", size: V2Icon.banner)
                        .foregroundColor(V2Token.actionActive)
                }
                .padding(.horizontal, Spacing.spacing12)
                .frame(height: 48)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if expanded {
                VStack(alignment: .leading, spacing: Spacing.spacing16) {
                    ForEach(sections) { s in
                        VStack(alignment: .leading, spacing: Spacing.spacing8) {
                            if !s.heading.isEmpty { V2InfoHeading(text: s.heading) }
                            V2InfoSectionBody(section: s)
                        }
                    }
                }
                .padding(.horizontal, Spacing.spacing12)
                .padding(.bottom, Spacing.spacing12)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(HFColor.screen))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
