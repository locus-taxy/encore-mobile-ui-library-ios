import Foundation

/// Validation logic for checklist items matching LOTR validation patterns.
/// Mirrors Android's `ChecklistValidator` object.
public enum ChecklistValidator {

    // MARK: - Standalone helpers (used by individual item views)

    /// Validates a boolean value. Boolean items are always valid.
    public static func validateBoolean(_ value: Bool, isRequired: Bool) -> Bool {
        true
    }

    /// Validates a single choice value.
    /// If optional: always valid. If required: must have selectedIndex >= 0.
    public static func validateSingleChoice(_ selectedIndex: Int, isRequired: Bool) -> Bool {
        if !isRequired { return true }
        return selectedIndex >= 0
    }

    /// Validates a multi choice value.
    /// If optional: always valid. If required: must have at least one selection.
    public static func validateMultiChoice(_ selectedIndices: Set<Int>, isRequired: Bool) -> Bool {
        if !isRequired { return true }
        return !selectedIndices.isEmpty
    }

    /// Validates a PIN value.
    /// If optional: valid if empty OR matches expected PIN.
    /// If required: must match expected PIN (if provided) or must not be empty.
    public static func validatePin(_ pinValue: String, isRequired: Bool, expectedPin: String?) -> Bool {
        if !isRequired {
            return pinValue.isEmpty || expectedPin == nil || pinValue == expectedPin
        }
        if let expectedPin = expectedPin {
            return pinValue == expectedPin
        }
        return !pinValue.isEmpty
    }

    /// Validates a rating value.
    /// If optional: always valid. If required: must be > 0.
    public static func validateRating(_ rating: Int, isRequired: Bool) -> Bool {
        if !isRequired { return true }
        return rating > 0
    }

    /// Validates a date value.
    /// If optional: always valid. If required: must not be empty.
    public static func validateDate(_ dateValue: String, isRequired: Bool) -> Bool {
        if !isRequired { return true }
        return !dateValue.isEmpty
    }

    /// Validates a time value.
    /// If optional: always valid. If required: must not be empty.
    public static func validateTime(_ timeValue: String, isRequired: Bool) -> Bool {
        if !isRequired { return true }
        return !timeValue.isEmpty
    }

    /// Validates a date/time value.
    /// If optional: always valid. If required: must not be empty.
    public static func validateDateTime(_ dateTimeValue: String, isRequired: Bool) -> Bool {
        if !isRequired { return true }
        return !dateTimeValue.isEmpty
    }

    /// Validates an image/photo value.
    /// If optional: always valid. If required: must have at least one image.
    public static func validateImage(_ imageURLs: [URL], isRequired: Bool) -> Bool {
        if !isRequired { return true }
        return !imageURLs.isEmpty
    }

    /// Validates a signature value.
    /// If optional: always valid. If required: must have signature URL.
    public static func validateSignature(_ signatureURL: URL?, isRequired: Bool) -> Bool {
        if !isRequired { return true }
        return signatureURL != nil
    }

    /// Validates a text field value.
    /// If optional: valid if empty OR matches regex (if provided).
    /// If required: must not be empty AND must match regex (if provided).
    public static func validateTextField(_ textValue: String, isRequired: Bool, regexPattern: String?) -> Bool {
        if !isRequired {
            if textValue.isEmpty { return true }
            if let pattern = regexPattern {
                return textValue.range(of: pattern, options: .regularExpression) != nil
            }
            return true
        }
        if textValue.isEmpty { return false }
        if let pattern = regexPattern {
            return textValue.range(of: pattern, options: .regularExpression) != nil
        }
        return true
    }

    /// Validates a URL value. URL items are always valid (read-only).
    public static func validateUrl(_ url: String, isRequired: Bool) -> Bool {
        true
    }

    // MARK: - Item-based helpers (used by ChecklistStateManager)

    public static func validateBoolean(_ value: Bool, item: ChecklistItem) -> Bool {
        validateBoolean(value, isRequired: item.isRequired)
    }

    public static func validateSingleChoice(_ selectedIndex: Int, item: ChecklistItem) -> Bool {
        validateSingleChoice(selectedIndex, isRequired: item.isRequired)
    }

    public static func validateMultiChoice(_ selectedIndices: Set<Int>, item: ChecklistItem) -> Bool {
        validateMultiChoice(selectedIndices, isRequired: item.isRequired)
    }

    public static func validatePin(_ pinValue: String, item: ChecklistItem) -> Bool {
        let expectedPin = item.possibleValues.first
        return validatePin(pinValue, isRequired: item.isRequired, expectedPin: expectedPin)
    }

    public static func validateRating(_ rating: Int, item: ChecklistItem) -> Bool {
        validateRating(rating, isRequired: item.isRequired)
    }

    public static func validateDate(_ dateValue: String, item: ChecklistItem) -> Bool {
        validateDate(dateValue, isRequired: item.isRequired)
    }

    public static func validateTime(_ timeValue: String, item: ChecklistItem) -> Bool {
        validateTime(timeValue, isRequired: item.isRequired)
    }

    public static func validateDateTime(_ dateTimeValue: String, item: ChecklistItem) -> Bool {
        validateDateTime(dateTimeValue, isRequired: item.isRequired)
    }

    public static func validateImage(_ imageURLs: [URL], item: ChecklistItem) -> Bool {
        validateImage(imageURLs, isRequired: item.isRequired)
    }

    public static func validateSignature(_ signatureURL: URL?, item: ChecklistItem) -> Bool {
        validateSignature(signatureURL, isRequired: item.isRequired)
    }

    public static func validateTextField(_ textValue: String, item: ChecklistItem) -> Bool {
        let regexPattern = item.additionalOptions["regex"]
        return validateTextField(textValue, isRequired: item.isRequired, regexPattern: regexPattern)
    }

    public static func validateUrl(_ url: String, item: ChecklistItem) -> Bool {
        validateUrl(url, isRequired: item.isRequired)
    }
}

