import Foundation

/// Value wrapper for checklist item values matching LOTR structure.
/// Used in the final submission map: [String: ChecklistItemValue]
/// Mirrors Android's `ChecklistItemValue` data class.
public struct ChecklistItemValue: Equatable {
    /// The string value of the item
    public let value: String
    /// Whether the value is a pod file path
    public let isValuePodFilePath: Bool
    /// Whether multiple files are present
    public let isMultipleFilePresent: Bool

    public init(
        value: String,
        isValuePodFilePath: Bool = false,
        isMultipleFilePresent: Bool = false
    ) {
        self.value = value
        self.isValuePodFilePath = isValuePodFilePath
        self.isMultipleFilePresent = isMultipleFilePresent
    }
}

