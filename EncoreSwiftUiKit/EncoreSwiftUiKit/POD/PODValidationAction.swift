import Foundation

public protocol PODValidationAction {
    func retry()
    func continueAnyway()
}

internal final class PODValidationActionImpl: PODValidationAction {
    func retry() {
        // Wired in T006
    }

    func continueAnyway() {
        // Wired in T006
    }
}
