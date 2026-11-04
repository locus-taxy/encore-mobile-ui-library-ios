import Foundation

enum ValidationErrorType {
    case blurDetected
    case textMismatch(missingTexts: [String])
}
