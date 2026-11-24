import SwiftUI

#Preview("SDUI card in a dialog") {
    ZStack {
        Color.black.opacity(0.4).ignoresSafeArea()
        VStack(spacing: 0) {
            SduiCardPreview("sdui/sdui_preview_sample.card.preview.json")
            Divider()
            HStack {
                Button("Dismiss") {}
                Spacer()
                Button("Open notifications") {}
            }
            .padding(16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(width: 328)
    }
}
