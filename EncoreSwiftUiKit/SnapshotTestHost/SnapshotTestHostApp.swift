import EncoreDesignPreviews
import PreviewGallery
import SwiftUI

@main
struct SnapshotTestHostApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                PreviewGallery()
            }
        }
    }
}
