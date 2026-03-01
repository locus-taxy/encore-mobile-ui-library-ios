import SwiftUI

/// PIN/OTP checklist item matching Figma design specifications.
/// Composes ChecklistHeader + PinView.
/// Mirrors Android's `PinCheckListItem` composable.
public struct PinCheckListItem: View {
    let title: String
    let initialPinValue: String
    let onPinChange: (String) -> Void
    let isRequired: Bool
    let itemCount: Int
    let expectedPin: String?
    var onScanQrClick: (() -> Void)?
    var onResendOtpClick: (() -> Void)?
    var resendOtpCountdownDuration: Int?
    var showResendOtp: Bool

    @State private var pinValue: String

    public init(
        title: String,
        initialPinValue: String,
        onPinChange: @escaping (String) -> Void,
        isRequired: Bool,
        itemCount: Int = 4,
        expectedPin: String? = nil,
        onScanQrClick: (() -> Void)? = nil,
        onResendOtpClick: (() -> Void)? = nil,
        resendOtpCountdownDuration: Int? = nil,
        showResendOtp: Bool = false
    ) {
        self.title = title
        self.initialPinValue = initialPinValue
        self.onPinChange = onPinChange
        self.isRequired = isRequired
        self.itemCount = itemCount
        self.expectedPin = expectedPin
        self.onScanQrClick = onScanQrClick
        self.onResendOtpClick = onResendOtpClick
        self.resendOtpCountdownDuration = resendOtpCountdownDuration
        self.showResendOtp = showResendOtp
        self._pinValue = State(initialValue: initialPinValue)
    }

    private var isValid: Bool {
        ChecklistValidator.validatePin(pinValue, isRequired: isRequired, expectedPin: expectedPin)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired && !isValid
            )

            PinView(
                pinValue: pinValue,
                onPinChange: { newPin in
                    pinValue = newPin
                    onPinChange(newPin)
                },
                itemCount: itemCount,
                expectedPin: expectedPin,
                onScanQrClick: onScanQrClick,
                onResendOtpClick: onResendOtpClick,
                resendOtpCountdownDuration: resendOtpCountdownDuration,
                showResendOtp: showResendOtp
            )
            .padding(.top, ChecklistItemConstants.innerTopPadding)
        }
        .padding(ChecklistItemConstants.itemPadding)
        .onChange(of: initialPinValue) { newValue in
            pinValue = newValue
        }
    }
}

