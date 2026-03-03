import SwiftUI

/// Main ChecklistView that combines header, checklist items list, and submit button.
/// Manages state for all items, validates required fields, and returns a map on submit.
/// Mirrors Android's `ChecklistView` composable.
///
/// Usage:
/// ```swift
/// ChecklistView(
///     header: "Complete Your Information",
///     items: [...],
///     onSubmit: { submissionMap in
///         // Handle submission
///     }
/// )
/// ```
public struct ChecklistView<Header: View>: View {
    let header: Header
    let items: [ChecklistItem]
    let onSubmit: ([String: ChecklistItemValue]) -> Void
    var submitButtonText: String
    var itemCallbacks: ChecklistItemCallbackProvider?

    @StateObject private var stateManager: ChecklistStateManager

    /// Initializer with custom header view.
    public init(
        @ViewBuilder header: () -> Header,
        items: [ChecklistItem],
        onSubmit: @escaping ([String: ChecklistItemValue]) -> Void,
        submitButtonText: String = "Submit",
        itemCallbacks: ChecklistItemCallbackProvider? = nil
    ) {
        self.header = header()
        self.items = items
        self.onSubmit = onSubmit
        self.submitButtonText = submitButtonText
        self.itemCallbacks = itemCallbacks
        self._stateManager = StateObject(wrappedValue: ChecklistStateManager(items: items))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Checklist items list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        ChecklistItemRenderer(
                            item: item,
                            stateManager: stateManager,
                            itemCallbacks: itemCallbacks
                        )
                    }
                }
            }

            // Submit button
            Button(action: {
                let submissionMap = stateManager.buildSubmissionMap()
                onSubmit(submissionMap)
            }) {
                Text(submitButtonText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(stateManager.areAllRequiredItemsValid() ? Color.accentColor : Color.gray)
                    )
            }
            .disabled(!stateManager.areAllRequiredItemsValid())
            .padding(16)
        }
        .onChange(of: items) { newItems in
            stateManager.updateItems(newItems)
        }
    }
}

// MARK: - Convenience initializer with String header

public extension ChecklistView {
    /// Convenience initializer with String header.
    init(
        header headerText: String,
        items: [ChecklistItem],
        onSubmit: @escaping ([String: ChecklistItemValue]) -> Void,
        submitButtonText: String = "Submit",
        itemCallbacks: ChecklistItemCallbackProvider? = nil
    ) where Header == AnyView {
        self.init(
            header: {
                AnyView(
                    Text(headerText)
                        .font(.system(size: 20, weight: .bold))
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                )
            },
            items: items,
            onSubmit: onSubmit,
            submitButtonText: submitButtonText,
            itemCallbacks: itemCallbacks
        )
    }
}

// MARK: - Checklist Item Renderer

/// Renders the appropriate checklist item component based on the item format.
/// Mirrors Android's `ChecklistItemRenderer` composable.
struct ChecklistItemRenderer: View {
    let item: ChecklistItem
    @ObservedObject var stateManager: ChecklistStateManager
    var itemCallbacks: ChecklistItemCallbackProvider?

    var body: some View {
        switch item.format {
        case .boolean:
            let currentValue = stateManager.getValue(key: item.key) as? Bool ?? false
            BooleanCheckListItem(
                title: item.item,
                initialChecked: currentValue,
                onCheckedChange: { newValue in
                    stateManager.updateValue(key: item.key, value: newValue)
                },
                isRequired: item.isRequired
            )

        case .singleChoice:
            let options: [String] = {
                if let allowed = item.allowedValues, !allowed.isEmpty {
                    return allowed.map(\.displayText)
                }
                return item.possibleValues ?? []
            }()
            let currentValue = stateManager.getValue(key: item.key) as? Int ?? -1
            SingleChoiceCheckListItem(
                title: item.item,
                options: options,
                initialSelectedIndex: currentValue,
                onSelectionChange: { index, _ in
                    stateManager.updateValue(key: item.key, value: index)
                },
                isRequired: item.isRequired
            )

        case .multiChoice:
            let options: [String] = {
                if let allowed = item.allowedValues, !allowed.isEmpty {
                    return allowed.map(\.displayText)
                }
                return item.possibleValues ?? []
            }()
            let currentValue = stateManager.getValue(key: item.key) as? Set<Int> ?? []
            MultiChoiceCheckListItem(
                title: item.item,
                options: options,
                initialSelectedIndices: currentValue,
                onSelectionChanged: { selectedIndices in
                    stateManager.updateValue(key: item.key, value: selectedIndices)
                },
                isRequired: item.isRequired
            )

        case .pin:
            let expectedPin = item.possibleValues?.first
            let currentValue = stateManager.getValue(key: item.key) as? String ?? ""
            let callbacks = itemCallbacks?(item.key, item.format)
            let pinCallbacks = callbacks?.pinCallbacks
            PinCheckListItem(
                title: item.item,
                initialPinValue: currentValue,
                onPinChange: { newPin in
                    stateManager.updateValue(key: item.key, value: newPin)
                },
                isRequired: item.isRequired,
                itemCount: expectedPin?.count ?? 4,
                expectedPin: expectedPin,
                onScanQrClick: pinCallbacks?.onScanQrClick,
                onResendOtpClick: pinCallbacks?.onResendOtpClick,
                resendOtpCountdownDuration: pinCallbacks?.resendOtpCountdownDuration,
                showResendOtp: pinCallbacks?.showResendOtp ?? false
            )

        case .rating:
            let currentValue = stateManager.getValue(key: item.key) as? Int ?? 0
            RatingCheckListItem(
                title: item.item,
                initialRating: currentValue,
                onRatingChange: { newRating in
                    stateManager.updateValue(key: item.key, value: newRating)
                },
                isRequired: item.isRequired
            )

        case .date:
            let dateFormat = item.additionalOptions?["dateFormat"] ?? "MM/dd/yyyy"
            let currentValue = stateManager.getValue(key: item.key) as? String ?? ""
            DateCheckListItem(
                title: item.item,
                initialDateValue: currentValue,
                onDateSelected: { date in
                    let formattedDate = DateTimeHelper.formatDate(date, format: dateFormat)
                    stateManager.updateValue(key: item.key, value: formattedDate)
                },
                isRequired: item.isRequired,
                dateFormat: dateFormat
            )

        case .time:
            let timeFormat = item.additionalOptions?["timeFormat"] ?? "HH:mm"
            let currentValue = stateManager.getValue(key: item.key) as? String ?? ""
            TimeCheckListItem(
                title: item.item,
                initialTimeValue: currentValue,
                onTimeSelected: { hour, minute in
                    let formattedTime = DateTimeHelper.formatTime(hour: hour, minute: minute)
                    stateManager.updateValue(key: item.key, value: formattedTime)
                },
                isRequired: item.isRequired,
                timeFormat: timeFormat
            )

        case .dateTime:
            let dateFormat = item.additionalOptions?["dateFormat"] ?? "MM/dd/yyyy"
            let timeFormat = item.additionalOptions?["timeFormat"] ?? "HH:mm"
            let currentValue = stateManager.getValue(key: item.key) as? String ?? ""
            let (dateValue, timeValue): (String, String) = {
                if !currentValue.isEmpty {
                    let parts = currentValue.split(separator: " ", maxSplits: 1).map(String.init)
                    if parts.count == 2 {
                        return (parts[0], parts[1])
                    } else if currentValue.contains("/") || currentValue.contains("-") {
                        return (currentValue, "")
                    } else {
                        return ("", currentValue)
                    }
                }
                return ("", "")
            }()
            DateTimeCheckListItem(
                title: item.item,
                initialDateValue: dateValue,
                initialTimeValue: timeValue,
                onDateTimeChanged: { combinedDateTime in
                    stateManager.updateValue(key: item.key, value: combinedDateTime)
                },
                isRequired: item.isRequired,
                dateFormat: dateFormat,
                timeFormat: timeFormat
            )

        case .photo, .photoGallery:
            let allowMultiple = item.format == .photoGallery
            let currentValue = stateManager.getValue(key: item.key) as? [URL] ?? []
            let callbacks = itemCallbacks?(item.key, item.format)
            let imageCallbacks = callbacks?.imageCallbacks
            ImageCheckListItem(
                title: item.item,
                initialImageURLs: currentValue,
                onImageListChanged: { imageURLs in
                    stateManager.updateValue(key: item.key, value: imageURLs)
                },
                isRequired: item.isRequired,
                allowMultiple: allowMultiple,
                imageSourceType: item.format == .photo ? .cameraOnly : .cameraOrGallery,
                onGetCaptionText: imageCallbacks?.onGetCaptionText
            )

        case .multiPhoto:
            let currentValue = stateManager.getValue(key: item.key) as? [URL] ?? []
            let callbacks = itemCallbacks?(item.key, item.format)
            let imageCallbacks = callbacks?.imageCallbacks
            ImageCheckListItem(
                title: item.item,
                initialImageURLs: currentValue,
                onImageListChanged: { imageURLs in
                    stateManager.updateValue(key: item.key, value: imageURLs)
                },
                isRequired: item.isRequired,
                allowMultiple: true,
                imageSourceType: .cameraOrGallery,
                onGetCaptionText: imageCallbacks?.onGetCaptionText
            )

        case .signature:
            let currentValue = stateManager.getValue(key: item.key) as? URL
            let callbacks = itemCallbacks?(item.key, item.format)
            let signatureCallbacks = callbacks?.signatureCallbacks
            SignatureCheckListItem(
                title: item.item,
                initialSignatureURL: currentValue,
                onSignatureSelected: { url in
                    stateManager.updateValue(key: item.key, value: url)
                },
                onRemoveSignature: {
                    stateManager.updateValue(key: item.key, value: nil)
                },
                isRequired: item.isRequired,
                onGetCaptionText: signatureCallbacks?.onGetCaptionText
            )

        case .textField:
            let regexPattern = item.additionalOptions?["regex"]
            let currentValue = stateManager.getValue(key: item.key) as? String ?? ""
            TextFieldCheckListItem(
                title: item.item,
                initialValue: currentValue,
                onValueChange: { newValue in
                    stateManager.updateValue(key: item.key, value: newValue)
                },
                isRequired: item.isRequired,
                hint: item.additionalOptions?["hint"] ?? "",
                regexPattern: regexPattern
            )

        case .url:
            let url = item.possibleValues?.first ?? ""
            let callbacks = itemCallbacks?(item.key, item.format)
            let urlCallbacks = callbacks?.urlCallbacks
            UrlCheckListItem(
                title: item.item,
                url: url,
                onUrlClick: urlCallbacks?.onUrlClick,
                isRequired: item.isRequired
            )

        case .urlWithFeedback:
            let url = item.possibleValues?.first ?? ""
            let callbacks = itemCallbacks?(item.key, item.format)
            let urlCallbacks = callbacks?.urlCallbacks
            UrlCheckListItem(
                title: item.item,
                url: url,
                onUrlClick: urlCallbacks?.onUrlClick ?? {
                    stateManager.updateValue(key: item.key, value: true)
                },
                isRequired: item.isRequired
            )
        }
    }
}

