import SwiftUI

public struct PODValidationView: View {
    let errorMessage: String
    let action: any PODValidationAction

    public init(errorMessage: String, action: any PODValidationAction) {
        self.errorMessage = errorMessage
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(.orange)

            Text(errorMessage)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button("Retry") {
                    action.retry()
                }
                .buttonStyle(.bordered)

                Button("Continue Anyway") {
                    action.continueAnyway()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
