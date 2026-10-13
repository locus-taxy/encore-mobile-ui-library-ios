import SwiftUI

// Screen 05 — "Checklist" stub. The Figma frame is a placeholder that only draws a centered
// "Checklist" label on the grey canvas, so we render exactly that.
struct HFScreen05: View {
    var onPrimary: () -> Void = {}          // the main forward action
    var onSecondary: (Int) -> Void = { _ in } // drill-in taps (cards), indexed 0,1,…
    var onClose: () -> Void = {}            // X / back

    var body: some View {
        ZStack {
            HFColor.screen.ignoresSafeArea()
            Text("Checklist")
                .typography(Typography.h5)
                .foregroundColor(HFColor.textPrimary)
                .contentShape(Rectangle())
                .onTapGesture { onPrimary() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("HF 05 — Checklist (stub)") {
    HFScreen05()
}
