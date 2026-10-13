import SwiftUI

// MARK: - P0 gate harness
//
// Renders every value of all four status enums, both identifier-pill families, the resolved exception
// affordances for each stop config, and all five transitions — with no screen content. If the paradigm
// layer is wrong, it is wrong here, before ~100 frames depend on it.
//
// Launch: SIMCTL_CHILD_POC_STATE=p0

public struct V2P0Harness: View {
    /// Headless entry point. The simulator MCP can't drive taps in this environment, so each state is
    /// reachable directly: SIMCTL_CHILD_POC_STATE=p0-sheet, p0-task, p0-cover, p0-lateral, p0-alert,
    /// p0-affordance.
    private let demo: String

    public init(demo: String = "") { self.demo = demo }

    @State private var page: Int = 0            // law 1 — dissolve
    @State private var sheet = false            // law 2 — bottom sheet + backdrop
    @State private var taskInSheet = false      // law 3 — dissolve inside the sheet
    @State private var cover = false            // law 4 — workflow full pager
    @State private var lateral = false          // law 5 — lateral push
    @State private var alert: V2Alert? = nil
    @StateObject private var toast = HFToastCenter()

    public var body: some View {
        ZStack {
            base
                .zIndex(0)

            V2SheetLayer(isPresented: sheet, onDismiss: { sheet = false; taskInSheet = false }) {
                sheetContent
            }
            .zIndex(1)

            if cover {
                V2WorkflowCover(title: "Workflow", subtitle: "law 4 — full pager, ✕ right",
                                onClose: { V2Motion.txSurface { cover = false } }) {
                    Text("Scan / checklist / maps live here")
                        .v2Text(V2Font.body)
                        .foregroundColor(HFColor.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .ignoresSafeArea(.container, edges: .bottom)
                .transition(V2Motion.riseFromBottom)
                .zIndex(2)
            }

            if lateral {
                lateralScreen
                    .transition(V2Motion.pushFromTrailing)
                    .zIndex(3)
            }
        }
        .environment(\.hfToast, toast)
        .onAppear(perform: applyDemo)
    }

    private func applyDemo() {
        switch demo {
        case "sheet":      sheet = true
        case "task":       sheet = true; taskInSheet = true
        case "cover":      cover = true
        case "lateral":    lateral = true
        case "alert":      alert = .offline()
        case "affordance": page = 1
        case "toast":
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                toast.show("Toast — drag me down")
            }
        default: break
        }
    }

    // MARK: Base

    private var base: some View {
            VStack(spacing: 0) {
                HFTitleBar(title: "P0 — paradigm layer", trailing: .none)
            V2AlertHost(alert: alert)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.spacing24) {
                    if page == 0 { chipCatalogue } else { affordanceMatrix }
                }
                .padding(.horizontal, Spacing.spacing16)
                .padding(.vertical, Spacing.spacing16)
            }
            .background(HFColor.screen)

            // FAB rides above the footer and lifts by one toast slot when a toast appears.
            V2FabSlot {
                HStack {
                    Spacer()
                    HFTintButton(label: "Scan", icon: "LQrCodeScanner")
                }
                .padding(.horizontal, Spacing.spacing16)
                .padding(.bottom, Spacing.spacing8)
            }

            V2Footer(isTerminal: false) {
                VStack(spacing: Spacing.spacing8) {
                    HStack(spacing: Spacing.spacing8) {
                        harnessButton(page == 0 ? "Dissolve →" : "← Dissolve") {
                            V2Motion.tx { page = page == 0 ? 1 : 0 }
                        }
                        harnessButton("Sheet") { V2Motion.txSurface { sheet = true } }
                        harnessButton("Cover") { V2Motion.txSurface { cover = true } }
                    }
                    HStack(spacing: Spacing.spacing8) {
                        harnessButton("Lateral") { V2Motion.txSurface { lateral = true } }
                        harnessButton("Alert") {
                            V2Motion.tx { alert = alert == nil ? .offline() : nil }
                        }
                        harnessButton("Toast") { toast.show("Toast — drag me down") }
                    }
                }
            }
            }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: Law 3 — task dissolves inside the sheet's real estate

    private var sheetContent: some View {
        VStack(spacing: 0) {
            HFTitleBar(title: taskInSheet ? "Task detail" : "Stop sheet",
                       leading: taskInSheet ? .back : .none,
                       trailing: .close,
                       onBack: { V2Motion.tx { taskInSheet = false } },
                       onClose: { V2Motion.txSurface { sheet = false; taskInSheet = false } })

            ZStack {
                if taskInSheet {
                    sheetBody("Task detail — dissolved into the same sheet frame",
                              "The sheet never re-animates; only its content cross-fades.")
                        .transition(V2Motion.dissolve)
                } else {
                    sheetBody("Stop sheet — law 2",
                              "Rose from the bottom over the backdrop. Drag down or ✕ to abandon.")
                        .transition(V2Motion.dissolve)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(HFColor.screen)

            V2Footer(isTerminal: false) {
                harnessButton(taskInSheet ? "Back to stop" : "Open task (law 3)") {
                    V2Motion.tx { taskInSheet.toggle() }
                }
            }
        }
    }

    private func sheetBody(_ title: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            Text(title)
                .v2Label(V2Font.sheetHeadline)
                .foregroundColor(HFColor.textPrimary)
            Text(sub)
                .v2Text(V2Font.body)
                .foregroundColor(HFColor.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.spacing16)
    }

    // MARK: Law 5

    private var lateralScreen: some View {
        VStack(spacing: 0) {
            HFTitleBar(title: "Parallel screen", leading: .back,
                       onBack: { V2Motion.txSurface { lateral = false } })
            VStack(alignment: .leading, spacing: Spacing.spacing8) {
                Text("Law 5 — lateral push")
                    .v2Label(V2Font.sheetHeadline)
                    .foregroundColor(HFColor.textPrimary)
                Text("Profile and the Home / Hub ops / Delivery tabs are parallel screens, so they "
                     + "enter from the right rather than rising or dissolving.")
                    .v2Text(V2Font.body)
                    .foregroundColor(HFColor.textSecondary)
                Spacer()
            }
            .padding(Spacing.spacing16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(HFColor.screen)
        }
        .background(HFColor.surface)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: Page 0 — every chip value

    private var chipCatalogue: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing24) {
            group("Stop status — 9 values (pending is chip-less by design)") {
                ForEach(Array(V2StopStatus.allCases.enumerated()), id: \.offset) { _, s in
                    labelled(s.label ?? "pending → no chip") { V2StopStatusChip(status: s) }
                }
            }
            group("Task status — 6 values (partial is provisional, no Figma yet)") {
                ForEach(Array(V2TaskStatus.allCases.enumerated()), id: \.offset) { _, s in
                    labelled(s.label ?? "pending → no chip") { V2TaskStatusChip(status: s) }
                }
            }
            group("Trip status — 3 values") {
                ForEach(Array(V2TripStatus.allCases.enumerated()), id: \.offset) { _, s in
                    labelled(s.label) { V2TripStatusChip(status: s) }
                }
            }
            group("SLA — 5 values (tinted + outlined, dark label)") {
                ForEach(Array(V2Sla.allCases.enumerated()), id: \.offset) { _, s in
                    labelled(s.label) { V2SlaChip(sla: s) }
                }
            }
            group("Stop identifier") {
                ForEach(Array([V2StopKind.customer, .hub, .partner, .handback].enumerated()),
                        id: \.offset) { _, k in
                    labelled(k.pageTitle) { V2StopIdentifierChip(kind: k) }
                }
            }
            group("Task identifier") {
                ForEach(Array([V2TaskKind.delivery, .pickup, .service, .handback, .scheduledBreak]
                                .enumerated()), id: \.offset) { _, k in
                    labelled(k.pageTitle) { V2TaskIdentifierChip(kind: k) }
                }
            }
            group("Terminal ⇒ no actions (P0.5)") {
                labelled("non-terminal") {
                    V2ActionRow(isTerminal: false) {
                        HFTintButton(label: "Navigate", icon: "LNavigationOutlined")
                    }
                }
                labelled("terminal → row renders nothing") {
                    V2ActionRow(isTerminal: true) {
                        HFTintButton(label: "Navigate", icon: "LNavigationOutlined")
                    }
                }
            }
        }
    }

    // MARK: Page 1 — resolved exception affordances (P0.7)

    private var affordanceMatrix: some View {
        VStack(alignment: .leading, spacing: Spacing.spacing24) {
            Text("Exception affordances resolve from config, not stop kind. 1 option ⇒ direct chip; "
                 + "2+ ⇒ `Facing issues?` sheet.")
                .v2Text(V2Font.body)
                .foregroundColor(HFColor.textSecondary)

            ForEach(Array(matrixRows.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: Spacing.spacing8) {
                    Text("\(row.name) · deferralMax \(row.config.deferralMax)")
                        .v2Label(V2Font.cardTitle)
                        .foregroundColor(HFColor.textPrimary)
                    ForEach(Array([V2StopStatus.pending, .enRoute, .arrived, .inProgress, .completed]
                                    .enumerated()), id: \.offset) { _, status in
                        let stop = probe(row.config, status)
                        HStack(alignment: .top, spacing: Spacing.spacing8) {
                            Text(status.label ?? "pending")
                                .v2Text(V2Font.body)
                                .foregroundColor(HFColor.textSecondary)
                                .frame(width: 88, alignment: .leading)
                            Text(describe(stop.exceptions))
                                .v2Label(V2Font.label1)
                                .foregroundColor(HFColor.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(Spacing.spacing12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(HFColor.surface))
            }
        }
    }

    private var matrixRows: [(name: String, config: V2StopConfig)] {
        [("Customer", .customer), ("Hub", .hub), ("Partner", .partner), ("Return leg", .handback)]
    }

    private func probe(_ config: V2StopConfig, _ status: V2StopStatus) -> V2Stop {
        V2Stop(id: 0, seq: 1, kind: .customer, config: config,
               title: "probe", address: "", window: "", status: status, tasks: [])
    }

    private func describe(_ exceptions: [V2StopException]) -> String {
        switch exceptions.count {
        case 0: return "—"
        case 1: return "chip: \(exceptions[0].chipLabel)"
        default: return "sheet: " + exceptions.map(\.rowTitle).joined(separator: " · ")
        }
    }

    // MARK: Bits

    private func group<Content: View>(_ title: String,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.spacing8) {
            HFSectionHeader(text: title)
                .padding(.horizontal, -Spacing.spacing16)
            content()
        }
    }

    private func labelled<Content: View>(_ label: String,
                                         @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: Spacing.spacing12) {
            content()
            Text(label)
                .v2Text(V2Font.body)
                .foregroundColor(HFColor.textSecondary)
            Spacer()
        }
    }

    private func harnessButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .v2Label(V2Font.button)
                .foregroundColor(HFColor.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(HFColor.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
