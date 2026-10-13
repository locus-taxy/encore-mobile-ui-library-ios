import SwiftUI

// Screen 21 — Customer Stop (In progress, first task done). Same Customer-Stop layout as 07:
// shared app bar + stop header (STOP 1 + blue "In progress", verified title, address, window,
// Navigate action) over the grey "TASKS (2)" list. Order 1 now carries a green "Completed"
// chip; Order 2 is still open. No bottom CTA in this state. Reuses HFStop* from HFScreen07.
struct HFScreen21: View {
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HFStopAppBar(onClose: onClose)
            ScrollView {
                VStack(spacing: 0) {
                    // In progress → blue chip; only "Navigate" is offered here (no Facing issues?).
                    HFStopHeader(statusText: "In progress",
                                 statusFill: Color.encore("Status/BlueBold"),
                                 showFacingIssues: false)
                    HFStopTasks(onSelect: onSecondary,
                                order1Status: "Completed",
                                order1StatusFill: HFColor.success)
                }
            }
            .background(HFColor.screen)
        }
        .background(HFColor.surface.ignoresSafeArea())
    }
}

#Preview("HF 21 — Customer Stop · In progress") {
    HFScreen21()
}
