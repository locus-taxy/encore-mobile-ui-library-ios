import SwiftUI

// Screen 11 — Customer Stop (reached the stop): STOP 1 "En route" chip, Navigate + Facing
// issues? pills. At the stop the swipe is enabled and shown in success green; completing it
// marks arrival and fires the "Arrived stop 1 at HH:MM" toast. Reuses HFStop* from HFScreen07.
struct HFScreen11: View {
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

            HFSheetFooter {
                SlidingButtonView(label: "Swipe to mark arrival",
                                  tint: HFColor.success,
                                  onSlideComplete: { onPrimary() })
            }
        }
        .background(HFColor.surface.ignoresSafeArea())
    }
}
