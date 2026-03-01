import Foundation

/// Possible value for SINGLE_CHOICE and MULTI_CHOICE items.
/// Contains both the key (for submission) and display text (for UI).
/// Mirrors Android's `ChecklistPossibleValue` data class.
public struct ChecklistPossibleValue: Codable, Equatable, Hashable {
    /// The key used for submission
    public let key: String
    /// The display text shown in the UI
    public let displayText: String

    public init(key: String, displayText: String) {
        self.key = key
        self.displayText = displayText
    }
}

