import SwiftUI

/// Image checklist item for photo/gallery upload matching Figma design specifications.
/// Composes ChecklistHeader + ImagePickerView.
/// Mirrors Android's `ImageCheckListItem` composable.
public struct ImageCheckListItem: View {
    let title: String
    let initialImageURLs: [URL]
    let onImageListChanged: ([URL]) -> Void
    let isRequired: Bool
    let allowMultiple: Bool
    let imageSourceType: ImageSourceType
    var onGetCaptionText: (() -> String?)?

    @State private var imageURLs: [URL]

    public init(
        title: String,
        initialImageURLs: [URL],
        onImageListChanged: @escaping ([URL]) -> Void,
        isRequired: Bool,
        allowMultiple: Bool,
        imageSourceType: ImageSourceType,
        onGetCaptionText: (() -> String?)? = nil
    ) {
        self.title = title
        self.initialImageURLs = initialImageURLs
        self.onImageListChanged = onImageListChanged
        self.isRequired = isRequired
        self.allowMultiple = allowMultiple
        self.imageSourceType = imageSourceType
        self.onGetCaptionText = onGetCaptionText
        self._imageURLs = State(initialValue: initialImageURLs)
    }

    private var isValid: Bool {
        ChecklistValidator.validateImage(imageURLs, isRequired: isRequired)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired && !isValid
            )

            ImagePickerView(
                imageURLs: imageURLs,
                onImageSelected: { url in
                    guard let url = url else { return }
                    let newURLs = allowMultiple ? imageURLs + [url] : [url]
                    imageURLs = newURLs
                    onImageListChanged(newURLs)
                },
                onRemoveImage: { index in
                    var newURLs = imageURLs
                    if newURLs.count == 1 {
                        newURLs = []
                    } else {
                        newURLs.remove(at: index)
                    }
                    imageURLs = newURLs
                    onImageListChanged(newURLs)
                },
                allowMultiple: allowMultiple,
                imageSourceType: imageSourceType,
                onGetCaptionText: onGetCaptionText
            )
            .padding(.top, ChecklistItemConstants.innerTopPadding)
        }
        .padding(ChecklistItemConstants.itemPadding)
        .onChange(of: initialImageURLs) { newValue in
            imageURLs = newValue
        }
    }
}

