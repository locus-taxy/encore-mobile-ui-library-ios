import SwiftUI

// Screen 01 — Home / Delivery: shift app bar, Today/Tomorrow tabs, trip cards, bottom nav.
//
// Data-driven: `today` / `tomorrow` arrays decide the layout —
//   • both empty            → empty "nothing scheduled" state (no tabs)
//   • tomorrow empty        → only-today list (no tabs)
//   • today empty (+ tmrw)  → tabs, Today shows a "Nothing for today" banner
//   • both populated        → tabs with counts
public struct HFHome: View {
    var today: [HFTrip]
    var tomorrow: [HFTrip]
    var offlineSynced: String?
    var onSecondary: (Int) -> Void

    public init(today: [HFTrip] = HFHome.defaultToday,
                tomorrow: [HFTrip] = HFHome.defaultTomorrow,
                offlineSynced: String? = nil,
                onSecondary: @escaping (Int) -> Void = { _ in }) {
        self.today = today
        self.tomorrow = tomorrow
        self.offlineSynced = offlineSynced
        self.onSecondary = onSecondary
    }

    @State private var selectedTab = 0
    private let sectionAnchors = ["today", "tomorrow"]

    private var isEmpty: Bool { today.isEmpty && tomorrow.isEmpty }
    private var showTabs: Bool { !tomorrow.isEmpty }

    public var body: some View {
        VStack(spacing: 0) {
            if let offlineSynced {
                HFOfflineBanner(lastSynced: offlineSynced)
            }
            HFHomeAppBar()

            if isEmpty {
                HFEmptyState(illustration: "HFEmptyRider",
                             title: "Nothing's scheduled for you",
                             subtitle: "You'll be notified of any trips or contact dispatcher to get assigned")
            } else if !showTabs {
                onlyTodayBody
            } else {
                tabbedBody
            }

            HFBottomNav(activeIndex: 2)
        }
        .background(HFColor.surface.ignoresSafeArea())
    }

    // MARK: - Only-today (no tabs)

    private var onlyTodayBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HFSectionHeader(text: "Today (\(today.count))")
                tripList(today)
                    .padding(.bottom, Spacing.spacing24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(HFColor.screen)
    }

    // MARK: - Tabbed (Today + Tomorrow)

    private var tabbedBody: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                HFTabs(tabs: ["Today (\(today.count))", "Tomorrow (\(tomorrow.count))"],
                       selection: $selectedTab) { i in
                    withAnimation { proxy.scrollTo(sectionAnchors[i], anchor: .top) }
                }

                GeometryReader { geo in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            HFSectionHeader(text: "Today (\(today.count))")
                                .id("today")
                                .hfTrackSection(0, in: "hfscroll")
                            if today.isEmpty {
                                HFInfoBanner(title: "Nothing for today",
                                             subtitle: "You'll be notified of any trips or contact dispatcher to get them assigned",
                                             illustration: "HFBannerNoTrips")
                                    .padding(.horizontal, Spacing.spacing16)
                            } else {
                                tripList(today)
                            }

                            HFSectionHeader(text: "Tomorrow (\(tomorrow.count))")
                                .id("tomorrow")
                                .hfTrackSection(1, in: "hfscroll")
                            tripList(tomorrow, tappable: false)
                                .padding(.bottom, Spacing.spacing24)

                            // Tail room so tapping a tab can scroll the last section to the very
                            // top, even when the content is shorter than the viewport.
                            Color.clear.frame(height: geo.size.height)
                        }
                    }
                    .coordinateSpace(name: "hfscroll")
                    .background(HFColor.screen)
                    .onPreferenceChange(HFSectionOffsetKey.self) { offsets in
                        let active = offsets.filter { $0.value <= 1 }.keys.max() ?? 0
                        if active != selectedTab { selectedTab = active }
                    }
                }
            }
            .onAppear {
                // Preview hook (mirrors POC_STATE): HF_FOCUS_TAB=<index> auto-focuses a
                // section on launch, so tab→section scrolling can be verified headlessly.
                if let raw = ProcessInfo.processInfo.environment["HF_FOCUS_TAB"],
                   let idx = Int(raw), sectionAnchors.indices.contains(idx) {
                    selectedTab = idx
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation { proxy.scrollTo(sectionAnchors[idx], anchor: .top) }
                    }
                }
            }
        }
    }

    // MARK: - Trip list (first Today card drills into the flow)

    @ViewBuilder
    private func tripList(_ trips: [HFTrip], tappable: Bool = true) -> some View {
        VStack(spacing: Spacing.spacing8) {
            ForEach(Array(trips.enumerated()), id: \.offset) { idx, trip in
                if tappable && idx == 0 {
                    Button { onSecondary(0) } label: { HFTripCard(trip) }
                        .buttonStyle(.plain)
                } else {
                    HFTripCard(trip)
                }
            }
        }
        .padding(.horizontal, Spacing.spacing16)
    }
}

// MARK: - Preset data (Phase-2 states)

public extension HFHome {
    static let defaultToday: [HFTrip] = [
        HFTrip(eyebrow: "Trip 1", time: "08:30-11:00 · ~17 kms", sub: "1 stop",
               chips: [("1 Pickup", true), ("1 Delivery", false)]),
        HFTrip(eyebrow: "Trip 2", time: "14:30-18:00 · ~17 kms", sub: "6 stops",
               chips: [("5 Pickups", true), ("9 Deliveries", false)]),
    ]
    static let defaultTomorrow: [HFTrip] = [
        HFTrip(eyebrow: "Trip 1", time: "14:30-18:00 · ~17 kms", sub: "6 stops",
               chips: [("5 Pickups", true), ("9 Deliveries", false)]),
    ]
    /// Tomorrow with 4 trips (multi-trip day).
    static let multiTomorrow: [HFTrip] = [
        HFTrip(eyebrow: "Trip 1", time: "08:30-13:00 · ~87 kms", sub: "6 stops",
               chips: [("5 Pickups", true), ("9 Deliveries", false)]),
        HFTrip(eyebrow: "Trip 2", time: "14:30-18:00 · ~17 kms", sub: "1 stop",
               chips: [("2 Deliveries", false)]),
        HFTrip(eyebrow: "Trip 3", time: "14:30-18:00 · ~17 kms", sub: "1 stop",
               chips: [("2 Deliveries", false)]),
        HFTrip(eyebrow: "Trip 4", time: "14:30-18:00 · ~17 kms", sub: "1 stop",
               chips: [("2 Deliveries", false)]),
    ]
    /// Today with trip 1 in transit (progress) + trip 2 waiting.
    static let ongoingToday: [HFTrip] = [
        HFTrip(eyebrow: "Trip 1", time: "08:30-11:00 · ~17 kms", sub: "0/1 stop completed",
               chips: [("1 Pickup", true), ("1 Delivery", false)], status: .inTransit, progress: 0),
        HFTrip(eyebrow: "Trip 2", time: "14:30-18:00 · ~17 kms", sub: "6 stops",
               chips: [("5 Pickups", true), ("9 Deliveries", false)]),
    ]
    /// Today with trip 1 completed + trip 2 pending hub dispatch.
    static let dispatchToday: [HFTrip] = [
        HFTrip(eyebrow: "Trip 1", time: "08:30-11:00 · ~17 kms", sub: "1 stop completed",
               chips: [("1 Pickups", true), ("1 Deliveries", false)], status: .completed),
        HFTrip(eyebrow: "Trip 2", time: "14:30-18:00 · ~17 kms", sub: "1 stop",
               chips: [("2 Deliveries", false)], status: .pendingDispatch),
    ]
}

// MARK: - Blocked / gated trip page (Phase-3 CTA States · Not-at-hub · Offline)

// A pre-start trip detail (summary + Stops(1) + stop card) whose swipe CTA is disabled with a
// reason caption — the framework surface for every "CTA State" (Figma 4007:112807), plus the
// Not-at-hub (4007:111833) and Offline (4007:112025) gates:
//   • caption          → the greyed reason line under the disabled swipe
//   • status           → optional trip status chip beside the eyebrow (e.g. Pending dispatch)
//   • offlineSynced    → orange "Offline · Last synced …" strip above the app bar
//   • offlineToast     → static info toast resting 16px above the footer (tap-blocked feedback)
struct HFBlockedTrip: View {
    var eyebrow: String = "TRIP 1"
    var time: String = "08:30-11:00 · ~17 kms"
    var sub: String = "1 stop"
    var chips: [(String, Bool)] = [("1 Pickup", true), ("1 Delivery", false)]
    var status: HFTripStatus? = nil
    var primaryLabel: String
    var caption: String? = nil
    var offlineSynced: String? = nil
    var offlineToast: String? = nil
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            if let offlineSynced {
                HFOfflineBanner(lastSynced: offlineSynced)
            }
            HFTitleBar(title: "Trip", leading: .back, onBack: onClose)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    summary
                    HFSectionHeader(text: "Stops (1)")
                    HFStopCard()
                        .padding(.horizontal, Spacing.spacing16)
                        .padding(.bottom, Spacing.spacing24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(HFColor.screen)

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HFColor.surface.ignoresSafeArea())
    }

    // Trip summary (pre-start: no progress bar), with an optional status chip.
    private var summary: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            HStack(spacing: Spacing.spacing8) {
                HFCopyableEyebrow(text: eyebrow, entity: "Trip", id: HFEntityID.trip)
                if let status {
                    HFStatusChip(text: status.text, fill: status.fill)
                }
            }
            Text(time)
                .typography(Typography.h5)
                .foregroundColor(HFColor.textPrimary)
            Text(sub)
                .typography(Typography.body2)
                .foregroundColor(HFColor.textSecondary)
            HStack(spacing: Spacing.spacing8) {
                ForEach(chips, id: \.0) { c in
                    HFPillChip(text: c.0, glyph: c.1 ? .pickup : .deliver)
                }
            }
            .padding(.top, Spacing.spacing2)

            Divider().overlay(HFColor.divider)
                .padding(.vertical, Spacing.spacing8)

            HStack(spacing: Spacing.spacing12) {
                HFTintButton(label: "Map", icon: "LLocationMap")
                HFTintButton(label: "View details")
            }
        }
        .padding(Spacing.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HFColor.surface)
    }

    @ViewBuilder
    private var footer: some View {
        if let offlineToast {
            VStack(spacing: 0) {
                HFToastPill(title: offlineToast, icon: "LInformation")
                    .padding(.horizontal, Spacing.spacing16)
                    .padding(.bottom, Spacing.spacing16)   // 16px above the base
                HFSheetFooter {
                    disabledSwipe
                }
            }
        } else {
            HFSheetFooter(caption: caption) {
                disabledSwipe
            }
        }
    }

    private var disabledSwipe: some View {
        SlidingButtonView(label: primaryLabel, onSlideComplete: {})
            .disabled(true)
    }
}

// MARK: - Router: POC_STATE env var = screen number ("01".."28") or a named home state

public struct HFRouter: View {
    let screen: String
    public init(screen: String) { self.screen = screen }
    public var body: some View {
        switch screen {
        case "01": HFHome()
        case "02": HFScreen02()
        case "03": HFScreen03()
        case "04": HFScreen04()
        case "05": HFScreen05()
        case "06": HFScreen06()
        case "07": HFScreen07()
        case "08": HFScreen08()
        case "09": HFScreen09()
        case "10": HFScreen10()
        case "11": HFScreen11()
        case "12": HFScreen12()
        case "13": HFScreen13()
        case "14": HFScreen14()
        case "15": HFScreen15()
        case "16": HFScreen16()
        case "17": HFScreen17()
        case "18": HFScreen18()
        case "19": HFScreen19()
        case "20": HFScreen20()
        case "21": HFScreen21()
        case "22": HFScreen22()
        case "23": HFScreen23()
        case "24": HFScreen24()
        case "25": HFScreen25()
        case "26": HFScreen26()
        case "27": HFScreen27()
        case "28": HFScreen28()
        // Phase-2 home data states
        case "home-empty":    HFHome(today: [], tomorrow: [])
        case "home-today":    HFHome(today: HFHome.defaultToday, tomorrow: [])
        case "home-tomorrow": HFHome(today: [], tomorrow: HFHome.defaultTomorrow)
        case "home-multi":    HFHome(today: HFHome.defaultToday, tomorrow: HFHome.multiTomorrow)
        case "home-ongoing":  HFHome(today: HFHome.ongoingToday, tomorrow: HFHome.multiTomorrow)
        case "home-dispatch": HFHome(today: HFHome.dispatchToday, tomorrow: HFHome.multiTomorrow)
        // Phase-3 gating: blocked-CTA trip states
        case "cta-finish1":
            HFBlockedTrip(eyebrow: "TRIP 2", primaryLabel: "Swipe to start trip 2",
                          caption: "Finish trip 1 to start this trip")
        case "cta-clockin":
            HFBlockedTrip(primaryLabel: "Swipe to start trip 1",
                          caption: "Clock in to start a trip")
        case "cta-hub":
            HFBlockedTrip(eyebrow: "TRIP 2", status: .pendingDispatch,
                          primaryLabel: "Swipe to start trip 2",
                          caption: "Hub clearance is pending")
        case "cta-nothub":
            HFBlockedTrip(primaryLabel: "Swipe to start trip 1",
                          caption: "Proceed to hub to start the trip")
        // Phase-3 offline
        case "offline-home":
            HFHome(today: HFHome.defaultToday, tomorrow: HFHome.multiTomorrow, offlineSynced: "08:16")
        case "offline-trip":
            HFBlockedTrip(primaryLabel: "Swipe to start trip 1", offlineSynced: "08:16")
        case "offline-toast":
            HFBlockedTrip(primaryLabel: "Swipe to start trip 1", offlineSynced: "08:16",
                          offlineToast: "Connect to the internet to start trip 1")
        default: HFPlaceholder(n: screen)
        }
    }
}
