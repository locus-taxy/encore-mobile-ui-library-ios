import SwiftUI

// Placeholder screens that Figma itself leaves as stubs (Checklist, POD) or hands off externally
// (turn-by-turn navigation → Google Maps). Rendered to match the Figma placeholder frames.

/// Screens 08 & 10 — navigation hand-off to Google Maps (external). Figma shows a Maps screenshot;
/// we represent the hand-off (no bespoke in-app map — per ui-decisions "navigate = external").
struct HFNavHandoff: View {
    var body: some View {
        ZStack {
            Color(.sRGB, red: 0.09, green: 0.12, blue: 0.18, opacity: 1).ignoresSafeArea()
            VStack(spacing: Spacing.spacing16) {
                EncoreIcon(iconName: "LNavigationOutlined", size: 40)
                    .foregroundColor(HFColor.onPrimary)
                Text("Navigating in Google Maps")
                    .typography(Typography.h6)
                    .foregroundColor(HFColor.onPrimary)
                Text("Turn-by-turn is handed off to Google Maps\n(external) — no in-app map.")
                    .typography(Typography.body2)
                    .foregroundColor(HFColor.onPrimary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

/// Figma stub frames — a centered label, matching the placeholder as drawn.
struct HFStubScreen: View {
    let title: String
    var body: some View {
        ZStack {
            HFColor.surface.ignoresSafeArea()
            VStack(spacing: Spacing.spacing8) {
                Text("….")
                    .typography(Typography.h6)
                    .foregroundColor(HFColor.textSecondary)
                Text(title)
                    .typography(Typography.h5)
                    .foregroundColor(HFColor.textPrimary)
            }
        }
    }
}
