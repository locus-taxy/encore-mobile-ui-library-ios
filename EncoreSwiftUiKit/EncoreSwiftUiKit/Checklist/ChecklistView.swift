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
    let initialValues: [String: Any]
    let onValueChange: (([String: Any]) -> Void)?
    let onSubmit: ([String: ChecklistItemValue]) -> Void
    var submitButtonText: String
    var itemCallbacks: ChecklistItemCallbackProvider?

    @StateObject private var stateManager: ChecklistStateManager

    /// Initializer with custom header view.
    public init(
        @ViewBuilder header: () -> Header,
        items: [ChecklistItem],
        initialValues: [String: Any] = [:],
        onValueChange: (([String: Any]) -> Void)? = nil,
        onSubmit: @escaping ([String: ChecklistItemValue]) -> Void,
        submitButtonText: String = "Submit",
        itemCallbacks: ChecklistItemCallbackProvider? = nil
    ) {
        self.header = header()
        self.items = items
        self.initialValues = initialValues
        self.onValueChange = onValueChange
        self.onSubmit = onSubmit
        self.submitButtonText = submitButtonText
        self.itemCallbacks = itemCallbacks
        self._stateManager = StateObject(wrappedValue: ChecklistStateManager(
            items: items, initialValues: initialValues, onValueChange: onValueChange
        ))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Checklist items list. The submit bar is a bottom safe-area inset of
            // the ScrollView (not a sibling in the VStack) so the ScrollView owns
            // keyboard avoidance and scrolls a focused text field above BOTH the
            // bar and the keyboard.
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            // 1px divider between fields — matches the Figma
                            // container `gap-px` (Background/ColumnHeading showing
                            // between the white field blocks). Full-bleed, no inset.
                            Color.encore("Background/ColumnHeading")
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                        }
                        ChecklistItemRenderer(
                            item: item,
                            itemIndex: index + 1,
                            totalItems: items.count,
                            stateManager: stateManager,
                            itemCallbacks: itemCallbacks
                        )
                        .transition(.checklistReveal)
                    }
                }
            }
            // Swipe down to dismiss the keyboard for text/number/PIN fields — the
            // bottom submit bar occupies the keyboard-accessory slot, so a Done
            // toolbar can't surface there.
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                // Submit — swipe-to-confirm, disabled until all visible mandatory items are valid.
                SlidingButtonView(label: submitButtonText, onSlideComplete: {
                    onSubmit(stateManager.buildSubmissionMap())
                })
                .disabled(!stateManager.areAllRequiredItemsValid())
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.encore("Background/Default"))
            }
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
        initialValues: [String: Any] = [:],
        onValueChange: (([String: Any]) -> Void)? = nil,
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
            initialValues: initialValues,
            onValueChange: onValueChange,
            onSubmit: onSubmit,
            submitButtonText: submitButtonText,
            itemCallbacks: itemCallbacks
        )
    }
}

// MARK: - Reveal transition

extension AnyTransition {
    /// Conditional-item reveal. The row keeps its full layout height the whole
    /// time (so the rows below reflow down as it appears), and its content is
    /// unclipped top-to-bottom in place — it grows out of the field above it
    /// instead of translating in over it the way `.move(edge:)` does. No fade.
    static var checklistReveal: AnyTransition {
        .modifier(
            active: ChecklistRevealModifier(progress: 0),
            identity: ChecklistRevealModifier(progress: 1)
        )
    }
}

private struct ChecklistRevealModifier: ViewModifier {
    let progress: CGFloat
    func body(content: Content) -> some View {
        content.clipShape(TopDownRevealShape(progress: progress))
    }
}

/// A top-anchored rectangle whose height grows 0 → full as `progress` goes
/// 0 → 1, wiping the clipped content in from the top edge (and back out on
/// removal). `animatableData` lets the clip height interpolate with the
/// ambient `withAnimation`.
private struct TopDownRevealShape: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height * max(0, progress)))
    }
}

// MARK: - Checklist Item Renderer

/// Renders the appropriate checklist item component based on the item format.
/// Mirrors Android's `ChecklistItemRenderer` composable.
struct ChecklistItemRenderer: View {
    let item: ChecklistItem
    let itemIndex: Int
    let totalItems: Int
    @ObservedObject var stateManager: ChecklistStateManager
    var itemCallbacks: ChecklistItemCallbackProvider?

    var body: some View {
        switch item.format {
        case .boolean:
            let currentValue = stateManager.getValue(key: item.key) as? Bool ?? false
            BooleanCheckListItem(
                title: item.item,
                helperText: item.helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: stateManager.isAnswered(key: item.key),
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
            if options.count > ChecklistItemConstants.dropdownThreshold {
                // Long option lists render as an anchored dropdown (Figma Menu),
                // not inline radios.
                DropdownChoiceCheckListItem(
                    title: item.item,
                    helperText: item.helperText,
                    itemIndex: itemIndex,
                    totalItems: totalItems,
                    isCompleted: stateManager.isAnswered(key: item.key),
                    options: options,
                    mode: .single,
                    initialSelection: currentValue >= 0 ? [currentValue] : [],
                    onCommit: { selection in
                        stateManager.updateValue(key: item.key, value: selection.first ?? -1)
                    },
                    isRequired: item.isRequired
                )
            } else {
                SingleChoiceCheckListItem(
                    title: item.item,
                    helperText: item.helperText,
                    itemIndex: itemIndex,
                    totalItems: totalItems,
                    isCompleted: stateManager.isAnswered(key: item.key),
                    options: options,
                    initialSelectedIndex: currentValue,
                    onSelectionChange: { index, _ in
                        stateManager.updateValue(key: item.key, value: index)
                    },
                    isRequired: item.isRequired
                )
            }

        case .multiChoice:
            let options: [String] = {
                if let allowed = item.allowedValues, !allowed.isEmpty {
                    return allowed.map(\.displayText)
                }
                return item.possibleValues ?? []
            }()
            let currentValue = stateManager.getValue(key: item.key) as? Set<Int> ?? []
            if options.count > ChecklistItemConstants.dropdownThreshold {
                // Long option lists render as an anchored dropdown (Figma Menu),
                // not inline checkboxes.
                DropdownChoiceCheckListItem(
                    title: item.item,
                    helperText: item.helperText,
                    itemIndex: itemIndex,
                    totalItems: totalItems,
                    isCompleted: stateManager.isAnswered(key: item.key),
                    options: options,
                    mode: .multi,
                    initialSelection: currentValue,
                    onCommit: { selection in
                        stateManager.updateValue(key: item.key, value: selection)
                    },
                    isRequired: item.isRequired
                )
            } else {
                MultiChoiceCheckListItem(
                    title: item.item,
                    helperText: item.helperText,
                    itemIndex: itemIndex,
                    totalItems: totalItems,
                    isCompleted: stateManager.isAnswered(key: item.key),
                    options: options,
                    initialSelectedIndices: currentValue,
                    onSelectionChanged: { selectedIndices in
                        stateManager.updateValue(key: item.key, value: selectedIndices)
                    },
                    isRequired: item.isRequired
                )
            }

        case .pin:
            let expectedPin = item.possibleValues?.first
            let currentValue = stateManager.getValue(key: item.key) as? String ?? ""
            let callbacks = itemCallbacks?(item.key, item.format)
            let pinCallbacks = callbacks?.pinCallbacks
            PinCheckListItem(
                title: item.item,
                helperText: item.helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: stateManager.isAnswered(key: item.key),
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
                helperText: item.helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: stateManager.isAnswered(key: item.key),
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
                helperText: item.helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: stateManager.isAnswered(key: item.key),
                initialDateValue: currentValue,
                onDateSelected: { date in
                    let formattedDate = DateTimeHelper.formatDate(date, format: dateFormat)
                    stateManager.updateValue(key: item.key, value: formattedDate)
                },
                onClear: { stateManager.updateValue(key: item.key, value: nil) },
                isRequired: item.isRequired,
                dateFormat: dateFormat
            )

        case .time:
            let timeFormat = item.additionalOptions?["timeFormat"] ?? "HH:mm"
            let currentValue = stateManager.getValue(key: item.key) as? String ?? ""
            TimeCheckListItem(
                title: item.item,
                helperText: item.helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: stateManager.isAnswered(key: item.key),
                initialTimeValue: currentValue,
                onTimeSelected: { hour, minute in
                    let formattedTime = DateTimeHelper.formatTime(hour: hour, minute: minute)
                    stateManager.updateValue(key: item.key, value: formattedTime)
                },
                onClear: { stateManager.updateValue(key: item.key, value: nil) },
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
                helperText: item.helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: stateManager.isAnswered(key: item.key),
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
                helperText: item.helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: stateManager.isAnswered(key: item.key),
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
                helperText: item.helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: stateManager.isAnswered(key: item.key),
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
                helperText: item.helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: stateManager.isAnswered(key: item.key),
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
            let currentValue = stateManager.getValue(key: item.key) as? String ?? ""
            TextFieldCheckListItem(
                title: item.item,
                helperText: item.helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: stateManager.isAnswered(key: item.key),
                initialValue: currentValue,
                onValueChange: { stateManager.updateValue(key: item.key, value: $0) },
                isRequired: item.isRequired,
                hint: item.additionalOptions?["hint"] ?? "",
                regexPattern: item.additionalOptions?["regex"]
            )

        case .url:
            // URL lives in additionalOptions.url on the wire; possibleValues is a legacy fallback.
            let url = item.additionalOptions?["url"] ?? item.possibleValues?.first ?? ""
            let callbacks = itemCallbacks?(item.key, item.format)
            let urlCallbacks = callbacks?.urlCallbacks
            UrlCheckListItem(
                title: item.item,
                helperText: item.helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: stateManager.isAnswered(key: item.key),
                url: url,
                onUrlClick: urlCallbacks?.onUrlClick,
                isRequired: item.isRequired
            )

        case .urlWithFeedback:
            let url = item.additionalOptions?["url"] ?? item.possibleValues?.first ?? ""
            let callbacks = itemCallbacks?(item.key, item.format)
            let urlCallbacks = callbacks?.urlCallbacks
            UrlCheckListItem(
                title: item.item,
                helperText: item.helperText,
                itemIndex: itemIndex,
                totalItems: totalItems,
                isCompleted: stateManager.isAnswered(key: item.key),
                url: url,
                onUrlClick: urlCallbacks?.onUrlClick ?? {
                    stateManager.updateValue(key: item.key, value: true)
                },
                isRequired: item.isRequired
            )
        }
    }
}
