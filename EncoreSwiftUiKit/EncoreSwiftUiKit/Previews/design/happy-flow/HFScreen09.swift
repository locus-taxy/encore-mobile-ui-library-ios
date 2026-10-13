import SwiftUI

// Screen 09 — Customer Stop (en route, not yet reached): STOP 1 "En route" chip, Navigate +
// Facing issues? pills. Swipe-to-mark-arrival is DISABLED with a helper line — the rider must
// navigate to the stop before they can mark arrival. Reuses HFStop* from HFScreen07.
struct HFScreen09: View {
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}
    var body: some View {
        VStack(spacing: 0) {
            HFStopAppBar(onClose: onClose)
            ScrollView {
                VStack(spacing: 0) {
                    HFStopHeader(statusText: "En route", statusFill: Color.encore("Status/GreyBold"))
                    HFStopTasks(onSelect: onSecondary)
                }
            }
            .background(HFColor.screen)

            // En route (not yet reached): swipe is disabled; tap is the test shortcut for onPrimary().
            HFSheetFooter(caption: "Navigate to stop to mark reached") {
                SlidingButtonView(label: "Swipe to mark arrival", onSlideComplete: {})
                    .disabled(true)
                    .contentShape(Rectangle())
                    .onTapGesture { onPrimary() }
            }
        }
        .background(HFColor.surface.ignoresSafeArea())
    }
}
