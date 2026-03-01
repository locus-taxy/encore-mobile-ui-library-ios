import Foundation
import SwiftUI

/// Manages state for all checklist items and builds the submission map.
/// Handles different value types internally and converts to ChecklistItemValue on submit.
/// Mirrors Android's `ChecklistStateManager` class.
public class ChecklistStateManager: ObservableObject {

    /// Internal state storage - key -> value (Any type)
    @Published private var stateMap: [String: Any] = [:]

    /// Validation state - key -> isValid
    @Published private var validationMap: [String: Bool] = [:]

    /// The current list of items
    private var items: [ChecklistItem]

    public init(items: [ChecklistItem]) {
        self.items = items
        // Initialize validation state for all items
        for item in items {
            validationMap[item.key] = validateItem(key: item.key, value: nil)
        }
    }

    // MARK: - Public API

    /// Updates the items list while preserving existing state values.
    public func updateItems(_ newItems: [ChecklistItem]) {
        let oldKeys = Set(items.map(\.key))
        let newKeys = Set(newItems.map(\.key))

        // Re-validate existing items in case their properties changed
        let existingKeys = oldKeys.intersection(newKeys)
        for key in existingKeys {
            let currentValue = stateMap[key]
            validationMap[key] = validateItem(key: key, value: currentValue)
        }

        // Initialize validation for truly new items
        let addedKeys = newKeys.subtracting(oldKeys)
        for key in addedKeys {
            validationMap[key] = validateItem(key: key, value: nil)
        }

        items = newItems
    }

    /// Updates the value for a specific item and validates it.
    public func updateValue(key: String, value: Any?) {
        if let value = value {
            stateMap[key] = value
        } else {
            stateMap.removeValue(forKey: key)
        }
        validationMap[key] = validateItem(key: key, value: value)
    }

    /// Gets the current value for a specific item.
    public func getValue(key: String) -> Any? {
        stateMap[key]
    }

    /// Checks if all required items are valid.
    public func areAllRequiredItemsValid() -> Bool {
        items
            .filter { !$0.optional }
            .allSatisfy { validationMap[$0.key] == true }
    }

    /// Builds the final submission map matching LOTR structure.
    public func buildSubmissionMap() -> [String: ChecklistItemValue] {
        var result: [String: ChecklistItemValue] = [:]

        for item in items {
            let value = stateMap[item.key]

            switch item.format {
            case .boolean:
                let boolValue = (value as? Bool) ?? false
                result[item.key] = ChecklistItemValue(value: String(boolValue))

            case .singleChoice:
                let selectedIndex = (value as? Int) ?? -1
                if selectedIndex >= 0 {
                    if !item.allowedValues.isEmpty, selectedIndex < item.allowedValues.count {
                        result[item.key] = ChecklistItemValue(value: item.allowedValues[selectedIndex].key)
                    } else {
                        let displayOptions = item.allowedValues.map(\.displayText)
                        if selectedIndex < displayOptions.count {
                            result[item.key] = ChecklistItemValue(value: displayOptions[selectedIndex])
                        }
                    }
                }

            case .multiChoice:
                let selectedIndices = (value as? Set<Int>) ?? []
                if !selectedIndices.isEmpty {
                    let selectedKeys = selectedIndices
                        .filter { $0 < item.allowedValues.count }
                        .map { item.allowedValues[$0].key }
                    if let jsonData = try? JSONSerialization.data(withJSONObject: selectedKeys),
                       let jsonString = String(data: jsonData, encoding: .utf8)
                    {
                        result[item.key] = ChecklistItemValue(value: jsonString)
                    }
                }

            case .pin:
                let pinValue = (value as? String) ?? ""
                if !pinValue.isEmpty {
                    result[item.key] = ChecklistItemValue(value: pinValue)
                }

            case .rating:
                let rating = (value as? Int) ?? 0
                if rating > 0 {
                    result[item.key] = ChecklistItemValue(value: String(rating))
                }

            case .date:
                let dateValue = (value as? String) ?? ""
                if !dateValue.isEmpty {
                    result[item.key] = ChecklistItemValue(value: dateValue)
                }

            case .time:
                let timeValue = (value as? String) ?? ""
                if !timeValue.isEmpty {
                    result[item.key] = ChecklistItemValue(value: timeValue)
                }

            case .dateTime:
                let dateTimeValue = (value as? String) ?? ""
                if !dateTimeValue.isEmpty {
                    result[item.key] = ChecklistItemValue(value: dateTimeValue)
                }

            case .photo, .photoGallery:
                let imageURLs = (value as? [URL]) ?? []
                if !imageURLs.isEmpty {
                    let filePath = imageURLs.first?.path ?? ""
                    result[item.key] = ChecklistItemValue(
                        value: filePath,
                        isValuePodFilePath: true,
                        isMultipleFilePresent: false
                    )
                }

            case .multiPhoto:
                let imageURLs = (value as? [URL]) ?? []
                if !imageURLs.isEmpty {
                    let filePaths = imageURLs.map(\.path)
                    if let jsonData = try? JSONSerialization.data(withJSONObject: filePaths),
                       let jsonString = String(data: jsonData, encoding: .utf8)
                    {
                        result[item.key] = ChecklistItemValue(
                            value: jsonString,
                            isValuePodFilePath: true,
                            isMultipleFilePresent: true
                        )
                    }
                }

            case .signature:
                let signatureURL = value as? URL
                if let signatureURL = signatureURL {
                    result[item.key] = ChecklistItemValue(
                        value: signatureURL.path,
                        isValuePodFilePath: true,
                        isMultipleFilePresent: false
                    )
                }

            case .textField:
                let textValue = (value as? String) ?? ""
                if !textValue.isEmpty {
                    result[item.key] = ChecklistItemValue(value: textValue)
                }

            case .url, .urlWithFeedback:
                let url = item.possibleValues.first ?? ""
                if !url.isEmpty {
                    if item.format == .urlWithFeedback {
                        let urlClicked = (value as? Bool) ?? false
                        result[item.key] = ChecklistItemValue(value: String(urlClicked))
                    } else {
                        result[item.key] = ChecklistItemValue(value: url)
                    }
                }
            }
        }

        return result
    }

    // MARK: - Private

    private func validateItem(key: String, value: Any?) -> Bool {
        guard let item = items.first(where: { $0.key == key }) else { return false }

        switch item.format {
        case .boolean:
            let boolValue = (value as? Bool) ?? false
            return ChecklistValidator.validateBoolean(boolValue, item: item)

        case .singleChoice:
            let index = (value as? Int) ?? -1
            return ChecklistValidator.validateSingleChoice(index, item: item)

        case .multiChoice:
            let indices = (value as? Set<Int>) ?? []
            return ChecklistValidator.validateMultiChoice(indices, item: item)

        case .pin:
            let pinValue = (value as? String) ?? ""
            return ChecklistValidator.validatePin(pinValue, item: item)

        case .rating:
            let rating = (value as? Int) ?? 0
            return ChecklistValidator.validateRating(rating, item: item)

        case .date:
            let dateValue = (value as? String) ?? ""
            return ChecklistValidator.validateDate(dateValue, item: item)

        case .time:
            let timeValue = (value as? String) ?? ""
            return ChecklistValidator.validateTime(timeValue, item: item)

        case .dateTime:
            let dateTimeValue = (value as? String) ?? ""
            return ChecklistValidator.validateDateTime(dateTimeValue, item: item)

        case .photo, .photoGallery, .multiPhoto:
            let imageURLs = (value as? [URL]) ?? []
            return ChecklistValidator.validateImage(imageURLs, item: item)

        case .signature:
            let signatureURL = value as? URL
            return ChecklistValidator.validateSignature(signatureURL, item: item)

        case .textField:
            let textValue = (value as? String) ?? ""
            return ChecklistValidator.validateTextField(textValue, item: item)

        case .url, .urlWithFeedback:
            let url = (value as? String) ?? ""
            return ChecklistValidator.validateUrl(url, item: item)
        }
    }
}

