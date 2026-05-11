import SwiftUI

public struct PODValidationView: View {
    public let errorMessage: String
    public let action: any PODValidationAction

    public init(errorMessage: String, action: any PODValidationAction) {
        self.errorMessage = errorMessage
        self.action = action
    }

    public var body: some View {
        // Placeholder — T005 will flesh this out with retry/continue buttons.
        Text(errorMessage)
    }
}
