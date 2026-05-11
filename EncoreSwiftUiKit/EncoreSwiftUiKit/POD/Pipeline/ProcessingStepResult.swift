import UIKit

internal enum ProcessingStepResult {
    case success(UIImage, ProcessingMetadata)
    case validationError(ValidationErrorType, UIImage, ProcessingMetadata)
}
