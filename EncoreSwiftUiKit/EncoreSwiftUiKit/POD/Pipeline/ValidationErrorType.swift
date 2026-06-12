import Foundation

internal enum ValidationErrorType {
    case blurDetected
    case textMismatch(missingTexts: [String])
}
