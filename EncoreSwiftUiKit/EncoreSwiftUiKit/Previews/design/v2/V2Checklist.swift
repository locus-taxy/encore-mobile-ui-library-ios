import SwiftUI

// MARK: - P2 The checklist workflow
//
// Canonical source: the `Checklist ✅` page, section `Linear` (2751:168775). The V2 board only draws
// a `Checklist` placeholder, so every measurement below comes from that page.
//
// Geometry, uniform across all five item types (frame 06, 2751:169241):
//   section      full width, 1pt seam between sections, 16 inset
//   header       328 × 92 — counter row 20, gap 4, title 24, gap 4, help 40 (two 20pt lines)
//   header→field 16
//   field        signature 80 × 80 · OTP 328 × 56 · photo 272 × 80 · choice 328 × 170 · rating 200 × 40
//   footer       <DialogActions> 360 × 110 — taller than the usual 84 because it carries the caption
//
// The submit CTA is gated on the MANDATORY items only, and says so in the caption. That gate lives
// in the model (`V2ChecklistModel.canSubmit`), not in the page, so every checklist inherits it.

enum V2ChecklistField {
    case signature
    case otp(digits: Int)
    case photo
    case choice([String])
    case rating(max: Int)

    /// The field's own drawn height, from the `Checklist Item` instance in frame 06.
    var height: CGFloat {
        switch self {
        case .signature: return 80
        case .otp:       return 56
        case .photo:     return 80
        case .choice:    return 170
        case .rating:    return 40
        }
    }
}

enum V2ChecklistValue: Equatable {
    case empty
    case signed
    case otp(String)
    case photo(Int)
    case choice(Int)
    case rating(Int)

    var isFilled: Bool {
        switch self {
        case .empty:            return false
        case .otp(let s):       return !s.isEmpty
        case .photo(let n):     return n > 0
        case .rating(let n):    return n > 0
        case .signed, .choice:  return true
        }
    }
}

struct V2ChecklistItem: Identifiable {
    let id: String
    var title: String
    var help: String
    var mandatory: Bool = true
    var field: V2ChecklistField
    var value: V2ChecklistValue = .empty
    /// Small link under the field (e.g. "Didn't receive OTP? Resend").
    var footnote: String? = nil

    var isDone: Bool { value.isFilled }
}

struct V2ChecklistModel {
    var title: String
    var cta: String
    var items: [V2ChecklistItem]

    /// Only the starred items gate the CTA — that is what the footer caption promises.
    var canSubmit: Bool { items.filter(\.mandatory).allSatisfy(\.isDone) }

    /// The checklist a workflow intent opens. Written here so the intent — not the surface —
    /// decides what is being collected.
    /// The stop decides the checklist's name and CTA: a hub pickup is "Hub pickup checklist" /
    /// "Swipe to complete" (35); a hand-back completes its club, "Swipe to complete tasks" (102);
    /// a customer task is proof of delivery, "Swipe to complete task" (53).
    static func forIntent(_ intent: V2WorkflowIntent, stopKind: V2StopKind? = nil) -> V2ChecklistModel {
        switch intent {
        case .completeTask:
            let title: String, cta: String
            switch stopKind {
            case .hub:      title = "Hub pickup checklist"; cta = "Swipe to complete"
            case .handback: title = "Hand-back checklist";  cta = "Swipe to complete tasks"
            default:        title = "Proof of delivery";    cta = "Swipe to complete task"
            }
            return V2ChecklistModel(title: title, cta: cta,
                                    items: [
                V2ChecklistItem(id: "sign", title: "Collect signature",
                                help: "Ask your customer to provide with their signature as a part of approval",
                                field: .signature),
                V2ChecklistItem(id: "otp", title: "Enter a valid OTP",
                                help: "Ask your customer to provide with their signature as a part of approval",
                                field: .otp(digits: 4),
                                footnote: "Didn't receive OTP? Resend"),
                V2ChecklistItem(id: "photo", title: "Upload picture",
                                help: "Make sure the picture you click of the product is clear",
                                field: .photo),
                V2ChecklistItem(id: "condition", title: "Condition of the product delivered",
                                help: "Make sure the picture you click of the product is clear",
                                field: .choice(["Delivered product is good",
                                                "Delivered product is damaged",
                                                "Customer not at delivery location"])),
                V2ChecklistItem(id: "rating", title: "Rate your experience",
                                help: "Rate the following delivery as per your on ground experience",
                                mandatory: false,
                                field: .rating(max: 5)),
            ])

        case .failTask:
            return V2ChecklistModel(title: "Report task failure", cta: "Swipe to mark failed", items: [
                V2ChecklistItem(id: "reason", title: "Why did this task fail",
                                help: "Pick the reason that matches what happened on ground",
                                field: .choice(["Customer not available",
                                                "Customer refused the delivery",
                                                "Address could not be located"])),
                V2ChecklistItem(id: "photo", title: "Upload picture",
                                help: "Make sure the picture you click of the product is clear",
                                mandatory: false,
                                field: .photo),
            ])

        case .failStop:
            return V2ChecklistModel(title: "Mark stop as failed", cta: "Swipe to mark failed", items: [
                V2ChecklistItem(id: "reason", title: "Why did this stop fail",
                                help: "Every planned task at this stop will be cancelled",
                                field: .choice(["Location could not be reached",
                                                "Site closed",
                                                "Access denied"])),
                V2ChecklistItem(id: "photo", title: "Upload picture",
                                help: "Make sure the picture you click of the location is clear",
                                mandatory: false,
                                field: .photo),
            ])

        case .endTrip:
            // Frame 108 is a placeholder in the board; this stands in with the usual end-of-trip asks.
            return V2ChecklistModel(title: "Trip completion checklist", cta: "Swipe to end trip 1", items: [
                V2ChecklistItem(id: "odometer", title: "Upload odometer picture",
                                help: "Make sure the reading on the odometer is clearly visible",
                                field: .photo),
                V2ChecklistItem(id: "vehicle", title: "Any issues with the vehicle?",
                                help: "Report anything the next rider should know about",
                                mandatory: false,
                                field: .choice(["No issues", "Needs servicing", "Damaged"])),
            ])

        case .scanTask:
            // Scanning has its own surface; it never opens a checklist.
            return V2ChecklistModel(title: "Scan HUs", cta: "Next", items: [])
        }
    }
}

// MARK: Page

struct V2ChecklistPage: View {
    @State var model: V2ChecklistModel
    var onClose: () -> Void = {}
    var onSubmit: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            V2Navbar(title: model.title,
                     actions: [V2NavAction(id: "close", icon: "LCross", action: onClose)])

            ScrollView {
                VStack(spacing: 0) {   // not lazy: rows must ride the cover's rise
                    ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                        section(index: index, item: item)
                        Rectangle().fill(HFColor.divider).frame(height: V2Space.hairline)
                    }
                }
                Color.clear.frame(height: V2Layout.footerClearance)
            }
            .background(HFColor.surface)

            V2Footer(isTerminal: false,
                     caption: model.canSubmit ? nil
                        : "Finish mandatory (*) checklist items to complete task") {
                V2SwipeCTA(label: model.cta, enabled: model.canSubmit, action: onSubmit)
            }
        }
    }

    private func section(index: Int, item: V2ChecklistItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Counter row — the tick is the item's own completion, so it appears next to its number
            // rather than on the field.
            HStack(spacing: V2Space.tagGap) {
                Text("\(index + 1)/\(model.items.count)")
                    .v2Label(V2Font.eyebrow)
                    .foregroundColor(HFColor.textSecondary)
                if item.isDone {
                    EncoreIcon(iconName: "LCheckCircle", size: V2Metrics.progressIcon)
                        .foregroundColor(HFColor.success)
                }
            }
            .frame(height: V2Metrics.eyebrowRow)

            // A mandatory item is starred, and the star is what the footer caption refers to.
            (Text(item.title).foregroundColor(HFColor.textPrimary)
                + Text(item.mandatory ? " *" : "").foregroundColor(Color.encore("Error/Main")))
                .v2Label(V2Font.cardTitle)
                .frame(height: V2Metrics.headlineLine, alignment: .leading)
                .padding(.top, V2Space.headlineToSub)

            Text(item.help)
                .v2Text(V2Font.helper)
                .foregroundColor(HFColor.textSecondary)
                .frame(height: V2Metrics.checklistHelp, alignment: .topLeading)
                .padding(.top, V2Space.headlineToSub)

            field(for: item)
                .padding(.top, V2Space.contentToTags)

            if let footnote = item.footnote {
                Text(footnote)
                    .v2Label(V2Font.body)
                    .foregroundColor(HFColor.primary)
                    .padding(.top, V2Space.contentToActions)
            }
        }
        .padding(V2Space.headerInset)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Fields
    //
    // Each one writes back through the same binding, so "is this item done" is never tracked
    // separately from its value.

    private func binding(_ id: String) -> Binding<V2ChecklistValue> {
        Binding(
            get: { model.items.first { $0.id == id }?.value ?? .empty },
            set: { v in
                guard let i = model.items.firstIndex(where: { $0.id == id }) else { return }
                model.items[i].value = v
            })
    }

    @ViewBuilder private func field(for item: V2ChecklistItem) -> some View {
        let value = binding(item.id)
        switch item.field {
        case .signature:
            tile(icon: "LSignature", label: "Add", filled: value.wrappedValue.isFilled,
                 size: item.field.height) { value.wrappedValue = .signed }

        case .otp(let digits):
            HStack(spacing: V2Space.chipGap) {
                ForEach(0..<digits, id: \.self) { i in
                    let filled = value.wrappedValue.isFilled
                    Text(filled ? "\(i + 1)" : "")
                        .v2Label(V2Font.buttonLarge)
                        .foregroundColor(HFColor.textPrimary)
                        .frame(width: V2Metrics.otpBox, height: item.field.height)
                        .background(RoundedRectangle(cornerRadius: 8).fill(HFColor.screen))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(filled ? HFColor.success : HFColor.divider,
                                    lineWidth: V2Space.hairline))
                }
            }
            .frame(height: item.field.height)
            .contentShape(Rectangle())
            .onTapGesture { value.wrappedValue = .otp("1234") }

        case .photo:
            HStack(spacing: V2Space.chipGap) {
                tile(icon: "LCameraAlt", label: "Add", filled: false, size: item.field.height) {
                    if case .photo(let n) = value.wrappedValue {
                        value.wrappedValue = .photo(n + 1)
                    } else {
                        value.wrappedValue = .photo(1)
                    }
                }
                if case .photo(let n) = value.wrappedValue {
                    ForEach(0..<n, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(HFColor.screen)
                            .frame(width: item.field.height, height: item.field.height)
                            .overlay {
                                EncoreIcon(iconName: "LPackage", size: V2Icon.field)
                                    .foregroundColor(HFColor.textSecondary)
                            }
                    }
                }
            }
            .frame(height: item.field.height, alignment: .leading)

        case .choice(let options):
            VStack(alignment: .leading, spacing: V2Space.contentToActions) {
                ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                    Button { value.wrappedValue = .choice(i) } label: {
                        HStack(spacing: V2Space.contentToActions) {
                            ZStack {
                                Circle().stroke(
                                    value.wrappedValue == .choice(i) ? HFColor.primary : HFColor.divider,
                                    lineWidth: 1.5)
                                if value.wrappedValue == .choice(i) {
                                    Circle().fill(HFColor.primary).padding(5)
                                }
                            }
                            .frame(width: V2Icon.field, height: V2Icon.field)
                            Text(option)
                                .v2Label(V2Font.body)
                                .foregroundColor(HFColor.textPrimary)
                            Spacer(minLength: 0)
                        }
                        .frame(height: V2Metrics.touchTarget)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: item.field.height, alignment: .top)

        case .rating(let max):
            HStack(spacing: 0) {
                ForEach(1...max, id: \.self) { star in
                    Button { value.wrappedValue = .rating(star) } label: {
                        let on: Bool = {
                            if case .rating(let n) = value.wrappedValue { return star <= n }
                            return false
                        }()
                        EncoreIcon(iconName: on ? "LStarFilled" : "LStarOutline",
                                   size: V2Icon.bar)
                            .foregroundColor(on ? HFColor.primary : HFColor.divider)
                            .frame(width: V2Metrics.ratingStar, height: item.field.height)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: item.field.height)
        }
    }

    private func tile(icon: String, label: String, filled: Bool, size: CGFloat,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: V2Space.tagGap) {
                EncoreIcon(iconName: filled ? "LCheckCircle" : icon, size: V2Icon.field)
                    .foregroundColor(filled ? HFColor.success : HFColor.primary)
                Text(filled ? "Done" : label)
                    .v2Label(V2Font.body)
                    .foregroundColor(filled ? HFColor.success : HFColor.primary)
            }
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: 8).fill(HFColor.primary.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(HFColor.pillBorder, lineWidth: V2Space.hairline))
        }
        .buttonStyle(.plain)
    }
}
