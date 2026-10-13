import SwiftUI

// Screen 12 — Customer Stop (arrival marked): STOP 1 "Arrived" chip, app-bar overflow menu,
// Navigate + Facing issues? pills. No swipe CTA here; the arrival feedback is the framework
// toast ("Arrived stop 1 at HH:MM"), which rises in and sinks out 16px above the bottom base.
struct HFScreen12: View {
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}
    var body: some View {
        VStack(spacing: 0) {
            HFStopAppBar(showMenu: true, onClose: onClose)
            ScrollView {
                VStack(spacing: 0) {
                    HFStopHeader(statusText: "Arrived", statusFill: Color.encore("Status/BlueBold"))
                    HFStopTasks(onSelect: onSecondary)
                }
            }
            .background(HFColor.screen)

            // No CTA on this state — an empty footer just hosts the framework toast above the base.
            HFToastFooter { Color.clear.frame(height: 0) }
        }
        .background(HFColor.surface.ignoresSafeArea())
    }
}
