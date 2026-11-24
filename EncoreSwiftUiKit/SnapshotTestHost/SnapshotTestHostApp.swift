import PreviewGallery
import SwiftUI

@main
struct SnapshotTestHostApp: App {
    init() {
        SduiDivKitRenderer.install()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                PreviewGallery()
            }
        }
    }
}
