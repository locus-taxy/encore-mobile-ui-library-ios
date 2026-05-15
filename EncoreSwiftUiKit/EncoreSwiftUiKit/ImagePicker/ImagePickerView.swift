import PhotosUI
import SwiftUI

/// Reusable image picker view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `ImageView` composable.
public struct ImagePickerView: View {
    let imageURLs: [URL]
    let onImageSelected: (URL?) -> Void
    var onRemoveImage: ((Int) -> Void)?
    var allowMultiple: Bool
    var imageSourceType: ImageSourceType
    var addImageText: String
    var onGetCaptionText: (() -> String?)?

    @State private var showActionSheet = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var fullScreenImageURL: URL?

    public init(
        imageURLs: [URL],
        onImageSelected: @escaping (URL?) -> Void,
        onRemoveImage: ((Int) -> Void)? = nil,
        allowMultiple: Bool = false,
        imageSourceType: ImageSourceType = .cameraOrGallery,
        addImageText: String = "Add Image",
        onGetCaptionText: (() -> String?)? = nil
    ) {
        self.imageURLs = imageURLs
        self.onImageSelected = onImageSelected
        self.onRemoveImage = onRemoveImage
        self.allowMultiple = allowMultiple
        self.imageSourceType = imageSourceType
        self.addImageText = addImageText
        self.onGetCaptionText = onGetCaptionText
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Display existing images
            if !imageURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.secondary.opacity(0.2))
                                        .overlay(
                                            ProgressView()
                                        )
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    fullScreenImageURL = url
                                }

                                Button {
                                    onRemoveImage?(index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
            }

            // Add image button (show if no images or if multiple allowed)
            if imageURLs.isEmpty || allowMultiple {
                Button {
                    launchImageSource()
                } label: {
                    HStack {
                        Image(systemName: "camera")
                            .font(.system(size: 20))
                        Text(addImageText)
                    }
                    .foregroundColor(.accentColor)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .confirmationDialog("Select Image Source", isPresented: $showActionSheet) {
            Button("Take Photo") {
                showCamera = true
            }
            Button("Choose from Gallery") {
                showPhotoPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .background(
            Group {
                if showCamera {
                    CameraPickerRepresentable(
                        onImagePicked: { url in
                            showCamera = false
                            onImageSelected(url)
                        },
                        onCancel: { showCamera = false }
                    )
                }
            }
        )
        .sheet(isPresented: $showPhotoPicker) {
            PHPickerRepresentable { url in
                onImageSelected(url)
            }
        }
        .fullScreenCover(item: $fullScreenImageURL) { url in
            FullScreenImageViewer(imageURL: url, onDismiss: { fullScreenImageURL = nil })
        }
    }

    private func launchImageSource() {
        switch imageSourceType {
        case .cameraOnly:
            showCamera = true
        case .galleryOnly:
            showPhotoPicker = true
        case .cameraOrGallery:
            showActionSheet = true
        }
    }
}

// MARK: - URL + Identifiable for fullScreenCover

extension URL: @retroactive Identifiable {
    public var id: String {
        absoluteString
    }
}

// MARK: - PHPicker (iOS 14+)

struct PHPickerRepresentable: UIViewControllerRepresentable {
    let onImagePicked: (URL?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: PHPickerViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImagePicked: (URL?) -> Void

        init(onImagePicked: @escaping (URL?) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self)
            else {
                onImagePicked(nil)
                return
            }
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let image = object as? UIImage,
                      let data = image.jpegData(compressionQuality: 0.8)
                else {
                    DispatchQueue.main.async { self?.onImagePicked(nil) }
                    return
                }
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("jpg")
                try? data.write(to: tempURL)
                DispatchQueue.main.async { self?.onImagePicked(tempURL) }
            }
        }
    }
}

// MARK: - Camera Picker

struct CameraPickerRepresentable: UIViewRepresentable {
    let onImagePicked: (URL?) -> Void
    let onCancel: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isHidden = true
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                  let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            else { return }
            var top = root
            while let presented = top.presentedViewController { top = presented }
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = context.coordinator
            top.present(picker, animated: true)
        }
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, onCancel: onCancel)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (URL?) -> Void
        let onCancel: () -> Void

        init(onImagePicked: @escaping (URL?) -> Void, onCancel: @escaping () -> Void) {
            self.onImagePicked = onImagePicked
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8)
            {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("jpg")
                try? data.write(to: tempURL)
                onImagePicked(tempURL)
            } else {
                onImagePicked(nil)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onCancel()
        }
    }
}

// MARK: - Full Screen Image Viewer

struct FullScreenImageViewer: View {
    let imageURL: URL
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss()
                    }
                }
            }
        }
    }
}
