import SwiftUI

// MARK: - App shell: launch → log in → home / delivery tabs → profile
//
// Frames 01–10 and 112–117 — everything around the trip flow. Same rules as the trip surfaces: the
// engine owns state, surfaces only read it and fire intents.

/// Where the rider is in the session, before the tabbed app exists.
enum V2Session: Equatable {
    case splash          // 01
    case workspace       // 02–04
    case credentials     // 05 (background) — the IdP sheet rides over it
    case loadingApp      // 06
    case signedIn
}

private let brandPurple = Color.encore("Purple/800")

// MARK: 01 Splash

struct V2SplashPage: View {
    var onDone: () -> Void = {}
    var body: some View {
        ZStack {
            brandPurple.ignoresSafeArea()
            Image.withName("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 194.7, height: 48)
        }
        .ignoresSafeArea()                        // centre on the screen, not the safe area (01)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: onDone) }
    }
}

// MARK: 02–04 Workspace (org / client ID)

/// The purple band + white panel every login screen sits in (02–05).
private struct V2LoginScaffold<Content: View, Footer: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                brandPurple.ignoresSafeArea(edges: .top)
                Image.withName("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 97.35, height: 24)
                    .padding(.leading, Spacing.spacing20)
                    .padding(.bottom, Spacing.spacing32)
            }
            .frame(height: 98)

            VStack(alignment: .leading, spacing: 0) {
                // Style each line: `v2Label` pins ONE line's height, so applied to the stack it
                // squeezed both lines into 34 (frame 02: h4 24/34, pitch 34).
                VStack(alignment: .leading, spacing: 0) {
                    Text("Hi there,").v2Label(V2Font.h4)
                    Text("Log in to your workspace").v2Label(V2Font.h4)
                }
                .foregroundColor(HFColor.textPrimary)
                .padding(.top, Spacing.spacing32)

                content
                    .padding(.top, Spacing.spacing24)
                Spacer(minLength: 0)
                footer
                    .padding(.bottom, HFLayout.barBottom(Spacing.spacing16))
            }
            .padding(.horizontal, Spacing.spacing20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(HFColor.surface)
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

/// "By continuing, you agree to Locus's Terms of Service and Privacy Policy" — the two names are links.
private struct V2LegalCopy: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("By continuing, you agree to").v2Label(V2Font.label2)
            (Text("Locus’s ") + Text("Terms of Service").underline() + Text(" and ")
                + Text("Privacy Policy").underline())
                .v2Label(V2Font.label2)
        }
        .foregroundColor(HFColor.textSecondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

struct V2WorkspacePage: View {
    var onContinue: (String) -> Void = { _ in }

    @State private var orgId = ""
    @State private var state: V2TextField.Adornment = .none
    @State private var token = 0

    var body: some View {
        V2LoginScaffold {
            V2TextField(label: "Organization or Client ID", text: $orgId,
                        placeholder: "For example: company-id", adornment: state)
                .onChange(of: orgId) { validate($0) }
        } footer: {
            VStack(spacing: Spacing.spacing12) {
                V2Button(label: "Continue", enabled: state != .none || orgId.count >= 3) {
                    onContinue(orgId)
                }
                V2LegalCopy()
            }
        }
    }

    /// Frames 04 → 03: a pause after typing validates the workspace; any ID of 3+ characters passes.
    private func validate(_ value: String) {
        token += 1
        let t = token
        guard value.count >= 3 else { state = .none; return }
        state = .validating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            if t == token { withAnimation(V2Motion.standard) { state = .valid } }
        }
    }
}

// MARK: 05 Credentials + IdP sheet

/// The credentials screen. In the board it only ever appears dimmed under the IdP sheet (05); it is
/// where ✕ on that sheet lands, and `Single Log-on (SSO)` brings the sheet back.
struct V2CredentialsPage: View {
    let orgId: String
    var onChangeOrg: () -> Void = {}
    var onSSO: () -> Void = {}
    var onLogIn: () -> Void = {}

    @State private var userId = ""
    @State private var password = ""

    var body: some View {
        V2LoginScaffold {
            VStack(alignment: .leading, spacing: 0) {
                orgChip
                VStack(spacing: Spacing.spacing16) {
                    V2TextField(label: "User ID", text: $userId, placeholder: "For example: lens321")
                    V2TextField(label: "Password", text: $password, secure: true)
                }
                .padding(.top, Spacing.spacing24)
                Text("Forgot password?")
                    .underline()
                    .v2Label(V2Font.label2)
                    .foregroundColor(HFColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, Spacing.spacing8)
                V2Button(label: "Log in", enabled: !userId.isEmpty && !password.isEmpty, action: onLogIn)
                    .padding(.top, Spacing.spacing16)
                HFSeam().overlay(HFColor.divider).padding(.vertical, Spacing.spacing24)
                Text("Other ways to log in:")
                    .v2Label(V2Font.label2)
                    .foregroundColor(HFColor.textSecondary)
                VStack(spacing: Spacing.spacing4) {
                    outlined("Single Log-on (SSO)", icon: "LPhonelink", action: onSSO)
                    HStack(spacing: Spacing.spacing8) {
                        outlined("OTP", icon: "LDialpad")
                        outlined("QR Code", icon: "LQr")
                    }
                }
                .padding(.top, Spacing.spacing8)
            }
        } footer: {
            V2LegalCopy()
        }
    }

    private var orgChip: some View {
        HStack(spacing: Spacing.spacing8) {
            EncoreIcon(iconName: "LCorporateFareOutlined", size: 20)
                .foregroundColor(HFColor.textPrimary)
            Text(orgId)
                .v2Label(V2Font.label2)
                .foregroundColor(HFColor.textPrimary)
            Spacer(minLength: 0)
            Button(action: onChangeOrg) {
                Text("Change").underline()
                    .v2Label(V2Font.label2)
                    .foregroundColor(V2Token.actionActive)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.spacing8)
        .background(RoundedRectangle(cornerRadius: 8).fill(HFColor.screen))
    }

    private func outlined(_ label: String, icon: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            HStack(spacing: 0) {
                EncoreIcon(iconName: icon, size: 20)
                Text(label)
                    .v2Label(V2Font.buttonSmall)
                    .padding(.horizontal, Spacing.spacing4)
            }
            .foregroundColor(HFColor.primary)
            .frame(maxWidth: .infinity)
            .frame(height: V2Metrics.touchTarget)
            .overlay(RoundedRectangle(cornerRadius: V2Metrics.footerRadius).stroke(HFColor.primary, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// The identity provider's own login page (05). Third-party chrome — Okta's greys, Noto Sans in the
/// original; set in Inter here at the same metrics since only Inter is bundled.
struct V2IdPSheet: View {
    var onClose: () -> Void = {}
    var onContinue: () -> Void = {}

    @State private var userId = "arjun12-indi-wf"
    @State private var password = "password123456"
    @State private var remember = true

    private static let ink = Color(.sRGB, red: 17/255, green: 19/255, blue: 24/255, opacity: 1)      // #111318
    private static let muted = Color(.sRGB, red: 103/255, green: 113/255, blue: 142/255, opacity: 1) // #67718E
    private static let rule = Color(.sRGB, red: 231/255, green: 233/255, blue: 238/255, opacity: 1)  // #E7E9EE

    var body: some View {
        VStack(spacing: 0) {
            // Native browser header
            HStack(spacing: Spacing.spacing8) {
                Button(action: onClose) {
                    EncoreIcon(iconName: "LCross", size: 24)
                        .foregroundColor(Self.muted)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Mara Labs, Inc. - Log In")
                        .v2Label(V2Font.sheetHeadline)
                        .foregroundColor(Self.ink)
                    Text("locus.okta.com")
                        .font(.custom("Inter18pt-Regular", size: 10))
                        .foregroundColor(.black)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.spacing8)
            .frame(height: 64)
            .overlay(alignment: .bottom) { Self.rule.frame(height: 1) }

            ScrollView {
                VStack(spacing: Spacing.spacing12) {
                    VStack(spacing: Spacing.spacing4) {
                        HStack(spacing: Spacing.spacing8) {
                            Text("Connecting to")
                                .v2Label(V2Font.inputValue)
                                .foregroundColor(Self.ink)
                            Image.withName("LogoColor")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 95.87, height: 23.6)
                        }
                        Text("Log in with your Mara Labs, Inc. account to access Locus")
                            .font(.custom("Inter18pt-Regular", size: 12))
                            .foregroundColor(Self.muted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, Spacing.spacing16)
                    .padding(.vertical, Spacing.spacing8)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .bottom) { Self.rule.frame(height: 1) }

                    VStack(spacing: Spacing.spacing16) {
                        Image.withName("HFRiderAvatar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.encore("Grey/100"), lineWidth: 1))
                        V2TextField(label: "User ID", text: $userId)
                        V2TextField(label: "Password", text: $password, secure: true)
                        Button { remember.toggle() } label: {
                            HStack(spacing: 0) {
                                EncoreIcon(iconName: remember ? "LCheckboxFilled" : "LCheckboxBlank", size: 20)
                                    .foregroundColor(remember ? HFColor.primary : HFColor.textSecondary)
                                    .frame(width: V2Metrics.touchTarget, height: V2Metrics.touchTarget)
                                Text("Remember me")
                                    .v2Label(V2Font.body1)
                                    .foregroundColor(HFColor.textPrimary)
                                    .padding(.leading, -Spacing.spacing8)
                                Spacer(minLength: 0)
                            }
                            .padding(.leading, -12)
                        }
                        .buttonStyle(.plain)
                        V2Button(label: "Continue", action: onContinue)
                    }
                    .padding(Spacing.spacing16)
                    .background(RoundedRectangle(cornerRadius: 4).fill(HFColor.surface))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Self.rule, lineWidth: 1))
                    .padding(.horizontal, Spacing.spacing16)

                    HStack {
                        Text("Powered by Okta")
                        Spacer()
                        Text("Privacy policy").underline()
                    }
                    .font(.custom("Inter18pt-Medium", size: 12))
                    .foregroundColor(Self.muted)
                    .padding(.horizontal, Spacing.spacing16)
                    .padding(.vertical, Spacing.spacing8)
                    .overlay(alignment: .top) { Self.rule.frame(height: 1) }
                }
                .padding(.bottom, HFLayout.bottomInset)
            }
        }
        .frame(height: 583 + HFLayout.bottomInset)
        .background(HFColor.surface)
    }
}

// MARK: - Home (frames 07–10, 113–115)

struct V2HomePage: View {
    let shift: V2Shift
    let canClockOut: Bool
    var onClockIn: () -> Void = {}
    var onClockOut: () -> Void = {}
    var onAvatar: () -> Void = {}
    var onTab: (V2AppTab) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            V2AppBar(title: "Hi, Arjun!", subtitle: shift.appBarSubtitle,
                     trailingInset: Spacing.spacing16, onAvatar: onAvatar)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.spacing8) {
                    Text("Your shift")
                        .v2Label(V2Font.sheetHeadline)
                        .foregroundColor(HFColor.textPrimary)
                        .frame(height: 28)
                    V2ShiftCard(shift: shift, canClockOut: canClockOut,
                                onClockIn: onClockIn, onClockOut: onClockOut)
                }
                .padding(.horizontal, V2Space.pageMargin)
                .padding(.top, Spacing.spacing16)
                .padding(.bottom, Spacing.spacing16)
            }
            .background(HFColor.screen)
            HFToastAnchor(height: 0)                     // toasts land 16 above the tab bar (09, 115)
            V2TabBar(active: .home, onSelect: onTab)
        }
    }
}

/// Shift card — Components → Shift card states: 8 states × expanded / collapsed (156).
/// One card with optional slots. The clock button and its reason line are the only affordances, so
/// Draft, Completed and No show drop the button; the reporting strip always stays (read-only info).
struct V2ShiftCard: View {
    let shift: V2Shift
    let canClockOut: Bool
    var onClockIn: () -> Void = {}
    var onClockOut: () -> Void = {}

    @State private var expanded = true

    private static let rail = Color.encore("Grey/300")

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.spacing16) {
                header
                if expanded {
                    legs
                    action
                }
            }
            .padding(Spacing.spacing16)

            reportingArea
        }
        .background(HFColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(HFColor.divider, lineWidth: V2Space.hairline))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.spacing12) {
            VStack(alignment: .leading, spacing: Spacing.spacing8) {
                V2EyebrowRow {
                    V2Eyebrow(text: "Shift \(shift.seq)")
                    if let label = shift.status.label {
                        HFStatusChip(text: label, fill: shift.status.fill)
                    }
                }
                Text(shift.window)
                    .v2Label(V2Font.sheetHeadline)
                    .foregroundColor(HFColor.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button { withAnimation(V2Motion.standard) { expanded.toggle() } } label: {
                EncoreIcon(iconName: expanded ? "LExpandLess" : "LExpandMore", size: 24)
                    .foregroundColor(V2Token.actionActive)
                    .frame(width: 34, height: V2Metrics.touchTarget)
            }
            .buttonStyle(.plain)
        }
    }

    private static let legRow: CGFloat = 42      // 4 + 34 pill + 4
    private static let dotCentre: CGFloat = 20   // dot sits at 12…28 in the row

    /// "Now" shows once the shift is under way — or should be (running late).
    private var showsNow: Bool {
        shift.status == .ongoing || (shift.status == .upcoming && shift.runningLate)
    }

    /// The legs as one timeline. The rail runs dot to dot only — no stub above the first dot, nothing
    /// below the last — and passes straight through a GAP (which has no dot). The "now" marker slides
    /// along that rail by time, drawn over the dots.
    private var legs: some View {
        let n = shift.legs.count
        let railLength = Self.legRow * CGFloat(max(0, n - 1))
        return VStack(spacing: 0) {
            ForEach(shift.legs) { legRow($0) }
        }
        .background(alignment: .topLeading) {
            Self.rail
                .frame(width: 1.25, height: railLength)
                .offset(x: 12 - 0.625, y: Self.dotCentre)
        }
        .overlay(alignment: .topLeading) {
            if showsNow {
                RoundedRectangle(cornerRadius: 8).fill(HFColor.textPrimary)
                    .frame(width: 20, height: 3)
                    .offset(x: 2, y: Self.dotCentre - 1.5
                            + Self.legRow * CGFloat(min(max(shift.nowAt, 0), Double(max(0, n - 1)))))
            }
        }
    }

    /// One leg: the dot column and the pill. A GAP has no pill and no dot.
    private func legRow(_ leg: V2ShiftLeg) -> some View {
        HStack(alignment: .top, spacing: Spacing.spacing12) {
            ZStack {
                if leg.kind != .gap {
                    Circle().fill(HFColor.surface)
                    Circle().stroke(leg.tint, lineWidth: 0.667)
                    Circle().fill(leg.tint).frame(width: 10.67, height: 10.67)
                }
            }
            .frame(width: 16, height: 16)
            .padding(.horizontal, 4)
            .padding(.top, 12)
            HStack(spacing: Spacing.spacing4) {
                Text(leg.label).foregroundColor(leg.tint)
                Text("·").foregroundColor(HFColor.textSecondary)
                Text(leg.window).foregroundColor(HFColor.textSecondary)
            }
            .v2Label(V2Font.overline2)
            .padding(.leading, Spacing.spacing12)
            .padding(.trailing, Spacing.spacing4)
            .padding(.vertical, Spacing.spacing8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(leg.kind == .gap ? Color.clear : HFColor.screen))
            .padding(.vertical, Spacing.spacing4)
        }
        .frame(height: Self.legRow)
    }

    /// Clock in / Clock out, full width; disabled states say why underneath. Copy in the board is a
    /// placeholder ("Add reason here"), so these lines are ours.
    @ViewBuilder private var action: some View {
        switch shift.status {
        case .upcoming:
            VStack(spacing: Spacing.spacing4) {
                V2Button(label: "Clock in", enabled: shift.canClockIn, action: onClockIn)
                if !shift.canClockIn {
                    reason("Clock in opens 15 mins before your shift")
                } else if shift.runningLate {
                    reason("Your shift has started — you'll be asked for a reason")
                }
            }
        case .ongoing:
            VStack(spacing: Spacing.spacing4) {
                V2Button(label: "Clock out", enabled: canClockOut, action: onClockOut)
                if !canClockOut {
                    reason("Clock out once your trip is completed")
                }
            }
        case .draft, .completed, .noShow:
            EmptyView()
        }
    }

    private func reason(_ text: String) -> some View {
        Text(text)
            .v2Label(V2Font.label2)
            .foregroundColor(HFColor.textSecondary)
            .frame(maxWidth: .infinity)
    }

    private var reportingArea: some View {
        HStack(spacing: Spacing.spacing12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.spacing4) {
                    EncoreIcon(iconName: "LLocationOnOutlined", size: 16)
                        .foregroundColor(HFColor.textSecondary)
                    V2Eyebrow(text: "Reporting area")
                }
                Text(shift.reportingArea)
                    .v2Label(V2Font.label1)
                    .foregroundColor(HFColor.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            EncoreIcon(iconName: "LNavigationOutlined", size: 16)
                .foregroundColor(HFColor.primary)
                .frame(width: 32, height: 32)
                .overlay(RoundedRectangle(cornerRadius: V2Metrics.footerRadius)
                    .stroke(HFColor.primary, lineWidth: 1))
                .frame(width: V2Metrics.touchTarget, height: V2Metrics.touchTarget)
        }
        .padding(.leading, Spacing.spacing16)
        .padding(.trailing, Spacing.spacing8)
        .padding(.vertical, Spacing.spacing12)
        .background(HFColor.screen)
    }
}

/// Clock-in sheet (08): title bar, "Start your shift" body, swipe.
struct V2ClockInSheet: View {
    let shift: V2Shift
    var onClose: () -> Void = {}
    var onSwipe: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HFSheetTitle(title: "Clock in", onClose: onClose)
            HFSeam()
            VStack(alignment: .leading, spacing: Spacing.spacing4) {
                Text("Start your shift")
                    .v2Label(V2Font.h5)
                    .foregroundColor(HFColor.textPrimary)
                Text("This shift runs from \(shift.window) today")
                    .v2Text(V2Font.body1)
                    .foregroundColor(HFColor.textSecondary)
            }
            .padding(Spacing.spacing16)
            .frame(maxWidth: .infinity, alignment: .leading)
            HFSheetFooter {
                V2SwipeCTA(label: "Swipe to start shift \(shift.seq)", action: onSwipe)
            }
        }
        .background(HFColor.surface)
    }
}

// MARK: - Summaries (109 trip, 114 clock-out)

extension V2Trip {
    var tasksDone: Int { allTasks.filter { $0.status == .completed }.count }
    var tasksFailed: Int { allTasks.filter { $0.status == .failed }.count }
    var tasksCancelled: Int { allTasks.filter { $0.status == .cancelled }.count }
    var onTimeStops: Int { stops.filter { $0.sla == .onTime || $0.sla == .early }.count }

    var summarySections: [V2SummarySection] {
        [
            V2SummarySection(id: "lead", heading: "Trip ran from \(window)", leadHeading: true,
                             chip: V2ChipSlot("status") { V2TripStatusChip(status: status) },
                             columns: 2, pairs: [
                                V2Pair(id: "time", label: "Executed time", value: "08:05 AM - 02:04 PM"),
                                V2Pair(id: "vehicle", label: "Vehicle", value: "KA-01-AB-1234",
                                       caption: "(LCV Tata Ace)"),
                                V2Pair(id: "exec", label: "Executed distance", value: "~15 km"),
                                V2Pair(id: "plan", label: "Planned distance", value: distance),
                             ]),
            V2SummarySection(id: "stops", heading: "Stops (\(stops.count))", columns: 3, pairs: [
                V2Pair(id: "c", label: "Completed", value: "\(stops(.completed))"),
                V2Pair(id: "f", label: "Failed", value: "\(stops(.failed))"),
                V2Pair(id: "p", label: "Partial", value: "\(stops(.partial))"),
                V2Pair(id: "s", label: "Skipped", value: "\(stops(.skipped))"),
                V2Pair(id: "x", label: "Cancelled", value: "0"),
            ]),
            V2SummarySection(id: "tasks", heading: "Tasks (\(allTasks.count))", columns: 3, pairs: [
                V2Pair(id: "c", label: "Completed", value: "\(tasksDone)"),
                V2Pair(id: "f", label: "Failed", value: "\(tasksFailed)"),
                V2Pair(id: "x", label: "Cancelled", value: "\(tasksCancelled)"),
            ]),
            V2SummarySection(id: "perf", heading: "Stop performance", columns: 3, pairs: [
                V2Pair(id: "o", label: "On-time", value: "\(onTimeStops)"),
                V2Pair(id: "d", label: "Delayed", value: "\(stops.count - onTimeStops)"),
            ]),
        ]
    }

    /// Clock-out summary (114) — same anatomy; the lead section describes the shift.
    func shiftSections(_ shift: V2Shift) -> [V2SummarySection] {
        [
            V2SummarySection(id: "lead", heading: "Shift ran from \(shift.window)", leadHeading: true,
                             columns: 2, pairs: [
                                V2Pair(id: "clocked", label: "Clocked time", value: shift.clockedTime),
                                V2Pair(id: "on", label: "On-shift", value: shift.onShift),
                             ]),
            V2SummarySection(id: "stops", heading: "Stops (\(stops.count))", columns: 3, pairs: [
                V2Pair(id: "c", label: "Completed", value: "\(stops(.completed))"),
                V2Pair(id: "p", label: "Partial", value: "\(stops(.partial))"),
                V2Pair(id: "f", label: "Failed", value: "\(stops(.failed))"),
            ]),
            V2SummarySection(id: "tasks", heading: "Tasks (\(allTasks.count))", columns: 3, pairs: [
                V2Pair(id: "c", label: "Completed", value: "\(tasksDone)"),
                V2Pair(id: "f", label: "Failed", value: "\(tasksFailed)"),
                V2Pair(id: "x", label: "Cancelled", value: "\(tasksCancelled)"),
            ]),
            V2SummarySection(id: "perf", heading: "Net stop performance", columns: 3, pairs: [
                V2Pair(id: "o", label: "On-time", value: "\(onTimeStops)"),
                V2Pair(id: "d", label: "Delayed", value: "\(stops.count - onTimeStops)"),
            ]),
        ]
    }
}

// MARK: - 112 Delivery, nothing scheduled

struct V2NoTripsState: View {
    var body: some View {
        VStack(spacing: 0) {
            Image.withName("HFEmptyRider")
                .resizable()
                .scaledToFit()
                .frame(width: 268, height: 268)
            VStack(spacing: Spacing.spacing8) {
                Text("Nothing's scheduled for you")
                    .v2Label(V2Font.sheetHeadline)
                    .foregroundColor(HFColor.textPrimary)
                Text("You'll be notified of any trips or contact dispatcher to get assigned")
                    .v2Text(V2Font.label1)
                    .foregroundColor(HFColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 268)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Figma centres the block on the FRAME (112); between a 64 app bar and a 64 tab bar that
        // reads ~26 lower, so lift it by the difference.
        .offset(y: -26)
    }
}

// MARK: - 116 Profile, 117 Log out

struct V2ProfilePage: View {
    var onBack: () -> Void = {}
    var onLogOut: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            V2Navbar(back: onBack, title: "Profile",
                     actions: [V2NavAction(id: "kebab", icon: "LOverflowVertical")])
            ScrollView {
                VStack(spacing: Spacing.spacing16) {
                    identity
                    VStack(spacing: V2Space.sectionSeam) {
                        V2CompactSectionHeader(text: "Activity")
                        V2NavRow(title: "Trip history")
                        V2NavRow(title: "My metrics")
                    }
                    VStack(spacing: V2Space.sectionSeam) {
                        V2CompactSectionHeader(text: "Account")
                        V2NavRow(title: "Contact us")
                        V2NavRow(title: "Change password")
                        V2NavRow(title: "Log out", tint: Color.encore("Error/Main"), action: onLogOut)
                    }
                    Text("App version 2.4.1 (build 4287)")
                        .v2Label(V2Font.caption)
                        .foregroundColor(HFColor.textSecondary)
                        .padding(.bottom, Spacing.spacing16)
                }
            }
            .background(HFColor.screen)
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private var identity: some View {
        HStack(spacing: Spacing.spacing16) {
            HFAvatar()
            VStack(alignment: .leading, spacing: 2) {
                HFCopyableEyebrow(text: "Driver", entity: "Driver", id: "arjun12-indi-wf")
                Text("Arjun Kumar")
                    .v2Label(V2Font.sheetHeadline)
                    .foregroundColor(HFColor.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("Manage")
                .v2Label(V2Font.buttonMedium)
                .foregroundColor(HFColor.primary)
                .padding(.horizontal, 12)
                .frame(minWidth: 64, minHeight: V2Metrics.touchTarget)
        }
        .padding(.leading, V2Space.pageMargin)
        .padding(.trailing, Spacing.spacing4)
        .padding(.vertical, Spacing.spacing16)
        .background(HFColor.surface)
    }
}

struct V2LogOutSheet: View {
    var onLogOut: () -> Void = {}
    var onCancel: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.spacing16) {
                EncoreIcon(iconName: "LLogout", size: 20)
                    .foregroundColor(Color.encore("Error/Main"))
                    .padding(.horizontal, Spacing.spacing16)
                    .padding(.vertical, Spacing.spacing8)
                    .background(Capsule().fill(Color.encore("Error/Main").opacity(0.08)))
                VStack(alignment: .leading, spacing: Spacing.spacing4) {
                    Text("Log out?")
                        .v2Label(V2Font.h5)
                        .foregroundColor(HFColor.textPrimary)
                    Text("You'll need to log in again with your Client ID and credentials")
                        .v2Text(V2Font.body1)
                        .foregroundColor(HFColor.textSecondary)
                }
            }
            .padding(Spacing.spacing16)
            .frame(maxWidth: .infinity, alignment: .leading)
            HFSheetFooter {
                V2Button(label: "Log out", role: .danger, action: onLogOut)
                V2Button(label: "Cancel", role: .text, action: onCancel)
            }
        }
        .background(HFColor.surface)
    }
}
