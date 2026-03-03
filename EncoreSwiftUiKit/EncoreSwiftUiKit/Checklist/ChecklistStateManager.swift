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
                result[item.key] = .text(String(boolValue))

            case .singleChoice:
                let selectedIndex = (value as? Int) ?? -1
                if selectedIndex >= 0 {
                    let allowedValues = item.allowedValues ?? []
                    if !allowedValues.isEmpty, selectedIndex < allowedValues.count {
                        result[item.key] = .text(allowedValues[selectedIndex].key)
                    } else {
                        let displayOptions = allowedValues.map(\.displayText)
                        if selectedIndex < displayOptions.count {
                            result[item.key] = .text(displayOptions[selectedIndex])
                        }
                    }
                }

            case .multiChoice:
                let selectedIndices = (value as? Set<Int>) ?? []
                if !selectedIndices.isEmpty {
                    let allowedValues = item.allowedValues ?? []
                    let selectedKeys = selectedIndices
                        .filter { $0 < allowedValues.count }
                        .map { allowedValues[$0].key }
                    if let jsonData = try? JSONSerialization.data(withJSONObject: selectedKeys),
                       let jsonString = String(data: jsonData, encoding: .utf8)
                    {
                        result[item.key] = .text(jsonString)
                    }
                }

            case .pin:
                let pinValue = (value as? String) ?? ""
                if !pinValue.isEmpty {
                    result[item.key] = .text(pinValue)
                }

            case .rating:
                let rating = (value as? Int) ?? 0
                if rating > 0 {
                    result[item.key] = .text(String(rating))
                }

            case .date:
                let dateValue = (value as? String) ?? ""
                if !dateValue.isEmpty {
                    result[item.key] = .text(dateValue)
                }

            case .time:
                let timeValue = (value as? String) ?? ""
                if !timeValue.isEmpty {
                    result[item.key] = .text(timeValue)
                }

            case .dateTime:
                let dateTimeValue = (value as? String) ?? ""
                if !dateTimeValue.isEmpty {
                    result[item.key] = .text(dateTimeValue)
                }

            case .photo, .photoGallery:
                let imageURLs = (value as? [URL]) ?? []
                if !imageURLs.isEmpty {
                    let path = imageURLs.first?.path ?? ""
                    result[item.key] = .filePath(path)
                }

            case .multiPhoto:
                let imageURLs = (value as? [URL]) ?? []
                if !imageURLs.isEmpty {
                    let filePaths = imageURLs.map(\.path)
                    result[item.key] = .multipleFilePaths(filePaths)
                }

            case .signature:
                let signatureURL = value as? URL
                if let signatureURL = signatureURL {
                    result[item.key] = .filePath(signatureURL.path)
                }

            case .textField:
                let textValue = (value as? String) ?? ""
                if !textValue.isEmpty {
                    result[item.key] = .text(textValue)
                }

            case .url, .urlWithFeedback:
                let url = item.possibleValues?.first ?? ""
                if !url.isEmpty {
                    if item.format == .urlWithFeedback {
                        let urlClicked = (value as? Bool) ?? false
                        result[item.key] = .text(String(urlClicked))
                    } else {
                        result[item.key] = .text(url)
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

