import Foundation

/// Checklist item model matching LOTR ChecklistItem structure.
/// This is the input model for ChecklistView.
/// Mirrors Android's `ChecklistItem` data class.
public struct ChecklistItem: Codable, Identifiable, Equatable {
    /// Unique key identifying this item
    public let key: String
    /// Title/label text
    public let item: String
    /// If true, item is not required (isRequired = !optional)
    public let optional: Bool
    /// The format/type of this checklist item
    public let format: ChecklistItemFormat
    /// For PIN expected value, URL string, TEXT_FIELD hints
    public let possibleValues: [String]
    /// For SINGLE_CHOICE and MULTI_CHOICE items
    public let allowedValues: [ChecklistPossibleValue]
    /// For TEXT_FIELD regex, date/time formats, etc.
    public let additionalOptions: [String: String]

    /// Conformance to Identifiable using key
    public var id: String { key }

    /// Returns true if this item is required.
    public var isRequired: Bool { !optional }

    public init(
        key: String,
        item: String,
        optional: Bool = false,
        format: ChecklistItemFormat,
        possibleValues: [String] = [],
        allowedValues: [ChecklistPossibleValue] = [],
        additionalOptions: [String: String] = [:]
    ) {
        self.key = key
        self.item = item
        self.optional = optional
        self.format = format
        self.possibleValues = possibleValues
        self.allowedValues = allowedValues
        self.additionalOptions = additionalOptions
    }
}

