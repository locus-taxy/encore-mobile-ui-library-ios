import Foundation

/// Sealed value type for checklist item submissions.
/// Used in the final submission map: [String: ChecklistItemValue]
/// Mirrors Android's `ChecklistItemValue` sealed class.
public enum ChecklistItemValue: Equatable {
    /// A plain text/string value (boolean, choice, pin, rating, date, time, text, url, etc.)
    case text(String)
    /// A single file path (photo, photoGallery, signature)
    case filePath(String)
    /// Multiple file paths (multiPhoto)
    case multipleFilePaths([String])
}

