import SwiftUI
import UIKit

// POC 2 — Trip detail (full-screen page). Interactive: tap the dotted Trip ID to copy (toast);
// "Show more" expands Details; swipe starts the trip → toast → in-transit (chip + progress + navigate).
//
// Design-system linkage (per the docs' MUI/Encore foundation):
//   • Colours come from the real Encore tokens via Color.encore("…") — NOT hardcoded hexes.
//   • Type/Spacing from Typography/Spacing; the swipe CTA is the library's SlidingButtonView.
//   • Genuinely-missing components (status chip, stop card, toast, identifier chip, progress) are
//     LOCAL POC views below — flagged in the docs as candidates to graduate into the library.
//
// Rationale logged in: ui-decisions.md (#3 swipe, #9 alerts/toast + animation, #13 full-page,
//   "build POCs against real tokens") and ui-patterns.md ("Trip detail page (POC 2)").

public struct POC2TripView: View {
    @State private var detailsExpanded = false
    @State private var started = false
    @State private var toastMessage = ""
    @State private var toastShown = false

    public init(started: Bool = false, detailsExpanded: Bool = false, toast: String? = nil) {
        _started = State(initialValue: started)
        _detailsExpanded = State(initialValue: detailsExpanded)
        _toastMessage = State(initialValue: toast ?? "")
        _toastShown = State(initialValue: toast != nil)
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            POC2Color.surface.ignoresSafeArea() // fills status-bar + home-indicator insets (no letterbox)

            VStack(spacing: 0) {
                appBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header // white block: content + (expanded) Details card + Show more/less
                        stopsSection // sits on the grey screen background
                    }
                }
                .background(POC2Color.screen)

                if !started {
                    SlidingButtonView(label: "Swipe to start trip 1") {
                        startTrip()
                    }
                    .padding(Spacing.spacing16)
                    .background(POC2Color.surface)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // Bottom toast — slides fully in from / out to below the screen (offset-driven so it
            // clears the frame, not just the safe area). Doesn't block the page while shown.
            POC2Toast(text: toastMessage) { dismissToast() }
                .padding(.horizontal, Spacing.spacing16)
                .padding(.bottom, Spacing.spacing16)
                .frame(maxWidth: .infinity)
                .offset(y: toastShown ? 0 : 220)
                .opacity(toastShown ? 1 : 0)
                .allowsHitTesting(toastShown)
        }
    }

    // MARK: Actions

    private func startTrip() {
        withAnimation(.easeInOut(duration: 0.25)) { started = true }
        show(toast: "Trip 1 started")
    }

    private func copyTripID() {
        UIPasteboard.general.string = "TRIP 1"
        show(toast: "Copied Trip ID")
    }

    private func show(toast text: String) {
        toastMessage = text
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) { toastShown = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastMessage == text {
                withAnimation(.easeInOut(duration: 0.35)) { toastShown = false } // slides down out of frame
            }
        }
    }

    private func dismissToast() {
        withAnimation(.easeInOut(duration: 0.35)) { toastShown = false }
    }

    // MARK: App bar

    private var appBar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Trip")
                    .typography(Typography.label0) // Inter Medium 16 (matches Figma app-bar title)
                    .foregroundColor(POC2Color.textPrimary)
                Spacer()
                Button {
                    // X = abandon the workflow → back to Home (nav model). No-op in the POC.
                } label: {
                    EncoreIcon(iconName: "LCross", size: Spacing.spacing24) // outline = actionable, 24pt glyph
                        .foregroundColor(POC2Color.textPrimary)
                        .frame(width: Spacing.spacing48, height: Spacing.spacing48)
                }
            }
            .padding(.leading, Spacing.spacing16)
            .padding(.trailing, Spacing.spacing4)
            .frame(height: Spacing.spacing56)

            Rectangle().fill(POC2Color.screen).frame(height: 1) // 1px grey seam (not a #c2c2c2 divider)
        }
        .background(POC2Color.surface)
    }

    // MARK: Header (white surface)

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.spacing8) { // Content: 8px gaps
                HStack(spacing: Spacing.spacing8) {
                    Button(action: copyTripID) {
                        Text("TRIP 1")
                            .typography(Typography.overline2)
                            .foregroundColor(POC2Color.textSecondary)
                            .overlay(alignment: .bottom) {
                                POC2DottedLine()
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [1.5, 2.5]))
                                    .foregroundColor(POC2Color.textSecondary)
                                    .frame(height: 1)
                                    .offset(y: 2)
                            }
                    }
                    .buttonStyle(.plain)

                    if started { POC2StatusChip(text: "In transit") }
                }

                Text("08:30-11:00 · ~17 kms")
                    .typography(Typography.h6)
                    .foregroundColor(POC2Color.textPrimary)

                if started {
                    POC2ProgressBar(progress: 0)
                    HStack(spacing: Spacing.spacing6) {
                        EncoreIcon(iconName: "LCheckCircle", size: 16) // filled = info/status
                            .foregroundColor(POC2Color.success)
                        Text("0/1 stop completed")
                            .typography(Typography.body2)
                            .foregroundColor(POC2Color.textSecondary)
                    }
                } else {
                    Text("1 stop")
                        .typography(Typography.body2)
                        .foregroundColor(POC2Color.textSecondary)
                }
            }

            if detailsExpanded {
                detailsCard.padding(.top, Spacing.spacing12)
            }

            // "Show more/less" sits at the bottom of the section (below the Details card when
            // expanded), with a 48pt touch target (per Figma).
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { detailsExpanded.toggle() }
            } label: {
                HStack(spacing: Spacing.spacing4) {
                    Text(detailsExpanded ? "Show less" : "Show more")
                        .typography(Typography.Button.small) // SemiBold 12
                        .foregroundColor(POC2Color.primary)
                    EncoreIcon(iconName: detailsExpanded ? "LArrowChevronUp" : "LArrowChevronDown", size: 20)
                        .foregroundColor(POC2Color.primary)
                }
                .frame(minHeight: Spacing.spacing48, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, Spacing.spacing16)
        .padding(.horizontal, Spacing.spacing16) // no bottom padding, per Figma Sheet Header
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(POC2Color.surface)
    }

    // MARK: Details (inline, push-down)

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing12) {
            Text("Details")
                .typography(Typography.h6)
                .foregroundColor(POC2Color.textPrimary)
            HStack(alignment: .top, spacing: Spacing.spacing16) {
                POC2Field(label: "LUNCH BREAK", value: "12:00-12:45")
                POC2Field(label: "HELPER", value: "Suresh")
            }
            HStack(alignment: .top, spacing: Spacing.spacing16) {
                POC2Field(label: "VEHICLE", value: "KA-01-AB-1234\n(LCV Tata Ace)")
                POC2Field(label: "FUEL ALLOWANCE", value: "₹600")
            }
        }
        .padding(Spacing.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(POC2Color.screen)) // grey tinted Details card
    }

    // MARK: Stops (grey screen)

    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            Text("STOPS (1)")
                .typography(Typography.overline2)
                .foregroundColor(POC2Color.textSecondary)
                .padding(.horizontal, Spacing.spacing16)

            POC2StopCard(showNavigate: started)
                .padding(.horizontal, Spacing.spacing16)
        }
        .padding(.top, Spacing.spacing16)
        .padding(.bottom, Spacing.spacing24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Local POC components (candidates to graduate into the library)

private struct POC2Toast: View {
    let text: String
    let onClose: () -> Void
    var body: some View {
        HStack(spacing: Spacing.spacing12) {
            EncoreIcon(iconName: "LCheckCircle", size: 20) // filled = confirmation
                .foregroundColor(POC2Color.surface)
            Text(text)
                .typography(Typography.body1)
                .foregroundColor(POC2Color.surface)
            Spacer(minLength: Spacing.spacing8)
            Button(action: onClose) {
                EncoreIcon(iconName: "LCross", size: 16) // outline = actionable
                    .foregroundColor(POC2Color.surface)
            }
        }
        .padding(.horizontal, Spacing.spacing12)
        .padding(.vertical, Spacing.spacing16) // taller, matching the Figma toast height (~52pt)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(POC2Color.toast)
        .cornerRadius(Spacing.spacing8)
    }
}

private struct POC2StatusChip: View {
    let text: String
    var body: some View {
        Text(text)
            .typography(Typography.Status.label)
            .foregroundColor(POC2Color.onPrimary)
            .padding(.horizontal, Spacing.spacing8)
            .padding(.vertical, Spacing.spacing2)
            .background(POC2Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 4)) // status chip = small radius, not a pill
    }
}

private struct POC2IdentifierChip: View {
    let text: String
    var body: some View {
        HStack(spacing: Spacing.spacing4) {
            EncoreIcon(iconName: "LPerson", size: 12) // Material "Person" (added to set)
                .foregroundColor(POC2Color.infoText)
            Text(text)
                .typography(Typography.Chip.labelSmall)
                .foregroundColor(POC2Color.infoText)
        }
        .padding(.horizontal, Spacing.spacing8)
        .padding(.vertical, Spacing.spacing4)
        .background(POC2Color.infoBg)
        .clipShape(Capsule()) // identifier chip = pill
    }
}

private struct POC2ProgressBar: View {
    let progress: Double // 0...1
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(POC2Color.primary.opacity(0.24))
                Capsule().fill(POC2Color.primary)
                    .frame(width: max(0, geo.size.width * progress))
            }
        }
        .frame(height: 4)
    }
}

private struct POC2Field: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing4) {
            Text(label)
                .typography(Typography.overline2)
                .foregroundColor(POC2Color.textSecondary)
            Text(value)
                .typography(Typography.body1)
                .foregroundColor(POC2Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct POC2StopCard: View {
    let showNavigate: Bool
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.spacing12) {
            VStack(alignment: .leading, spacing: Spacing.spacing12) {
                Text("STOP 1")
                    .typography(Typography.overline2)
                    .foregroundColor(POC2Color.textSecondary)
                VStack(alignment: .leading, spacing: Spacing.spacing4) {
                    Text("Locus - Logistics Optimization & Decision-making Platform")
                        .typography(Typography.label1)
                        .foregroundColor(POC2Color.textPrimary)
                    Text("08:30 - 10:00 • 2 tasks")
                        .typography(Typography.body2)
                        .foregroundColor(POC2Color.textSecondary)
                }
                POC2IdentifierChip(text: "Customer")
            }
            if showNavigate {
                Button {} label: {
                    EncoreIcon(iconName: "LNavigation", size: 20) // Material "Navigation" (added to set)
                        .foregroundColor(POC2Color.primary)
                        .frame(width: Spacing.spacing48, height: Spacing.spacing48)
                        .background(POC2Color.screen)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(POC2Color.surface)) // rounded fill = corners clip to the border
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(POC2Color.divider, lineWidth: 0.5))
    }
}

private struct POC2DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

// Design-system tokens (real Encore/MUI colours via the asset catalog).
private enum POC2Color {
    static let primary = Color.encore("Primary/Main")
    static let onPrimary = Color.encore("Primary/ContrastText")
    static let textPrimary = Color.encore("Text/Primary")
    static let textSecondary = Color.encore("Text/Secondary")
    static let surface = Color.encore("Background/Default")
    static let screen = Color.encore("Background/ColumnHeading")
    static let divider = Color.encore("Divider")
    static let success = Color.encore("Success/Main")
    static let toast = Color.encore("Action/Active")
    static let infoText = Color.encore("Info/Dark")            // #0070a9
    static let infoBg = Color.encore("Info/Main").opacity(0.08) // ~rgba(1,136,204,0.08) light tint
}

#Preview("POC 2 — Trip (interactive)") {
    POC2TripView()
}
