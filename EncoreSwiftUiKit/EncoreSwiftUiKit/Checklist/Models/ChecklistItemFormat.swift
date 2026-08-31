import Foundation

/// Enum for checklist item formats matching LOTR FormatEnum (excluding PAYMENT).
/// Mirrors Android's `ChecklistItemFormat` enum.
public enum ChecklistItemFormat: String, Codable, CaseIterable {
    case boolean = "BOOLEAN"
    case singleChoice = "SINGLE_CHOICE"
    /// Single choice whose options are resolved dynamically from an `optionsSource` expression
    /// (HLD §9). Behaves like `.singleChoice` once resolved.
    case singleChoiceDynamic = "SINGLE_CHOICE_DYNAMIC"
    case multiChoice = "MULTI_CHOICE"
    case pin = "PIN"
    case rating = "RATING"
    case date = "DATE"
    case time = "TIME"
    case dateTime = "DATETIME"
    case photo = "PHOTO"
    case photoGallery = "PHOTO_GALLERY"
    case multiPhoto = "MULTI_PHOTO"
    case signature = "SIGNATURE"
    case textField = "TEXT_FIELD"
    case url = "URL"
    case urlWithFeedback = "URL_WITH_FEEDBACK"
}
