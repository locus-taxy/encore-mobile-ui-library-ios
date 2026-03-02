import Combine
import SwiftUI

/// Validation state for PIN input.
public enum PinValidationState {
    case valid
    case invalid
}

/// Reusable PIN/OTP input view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `PinView` composable.
public struct PinView: View {
    let pinValue: String
    let onPinChange: (String) -> Void
    var itemCount: Int
    var expectedPin: String?
    var onScanQrClick: (() -> Void)?
    var onResendOtpClick: (() -> Void)?
    var resendOtpCountdownDuration: Int?
    var showResendOtp: Bool

    @State private var remainingSeconds: Int?

    public init(
        pinValue: String,
        onPinChange: @escaping (String) -> Void,
        itemCount: Int = 4,
        expectedPin: String? = nil,
        onScanQrClick: (() -> Void)? = nil,
        onResendOtpClick: (() -> Void)? = nil,
        resendOtpCountdownDuration: Int? = nil,
        showResendOtp: Bool = false
    ) {
        self.pinValue = pinValue
        self.onPinChange = onPinChange
        self.itemCount = itemCount
        self.expectedPin = expectedPin
        self.onScanQrClick = onScanQrClick
        self.onResendOtpClick = onResendOtpClick
        self.resendOtpCountdownDuration = resendOtpCountdownDuration
        self.showResendOtp = showResendOtp
    }

    private var validationState: PinValidationState? {
        guard let expectedPin = expectedPin else { return nil }
        if pinValue.isEmpty { return nil }
        if pinValue == expectedPin { return .valid }
        if pinValue.count == expectedPin.count { return .invalid }
        return nil
    }

    private var formattedCountdown: String? {
        guard let seconds = remainingSeconds, seconds > 0 else { return nil }
        let minutes = seconds / 60
        let secs = seconds % 60
        return "\(minutes):\(String(format: "%02d", secs))"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TextField("", text: Binding(
                    get: { pinValue },
                    set: { newValue in
                        let filtered = String(newValue.prefix(itemCount))
                        onPinChange(filtered)
                    }
                ))
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            validationState == .invalid ? Color.red : Color.clear,
                            lineWidth: 1.5
                        )
                )
                .overlay(alignment: .trailing) {
                    if let state = validationState {
                        Image(systemName: state == .valid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(state == .valid ? .green : .red)
                            .padding(.trailing, 8)
                    }
                }

                if let onScanQrClick = onScanQrClick {
                    Button(action: onScanQrClick) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }

            if showResendOtp, onResendOtpClick != nil {
                HStack {
                    if let countdown = formattedCountdown {
                        Text("Resend OTP in \(countdown)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    } else {
                        Button("Resend OTP") {
                            onResendOtpClick?()
                            if let duration = resendOtpCountdownDuration {
                                remainingSeconds = duration
                                startCountdown()
                            }
                        }
                        .font(.system(size: 12))
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if let current = remainingSeconds, current > 0 {
                remainingSeconds = current - 1
            } else {
                remainingSeconds = nil
                timer.invalidate()
            }
        }
    }
}

