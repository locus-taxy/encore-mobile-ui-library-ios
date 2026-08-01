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
        return String(format: "%02d:%02ds", minutes, secs)
    }

    public var body: some View {
        // Hidden text field captures keyboard input; the visible slots render on top.
        ZStack(alignment: .topLeading) {
            TextField("", text: Binding(
                get: { pinValue },
                set: { newValue in
                    let filtered = String(newValue.filter { $0.isNumber }.prefix(itemCount))
                    onPinChange(filtered)
                }
            ))
            .keyboardType(.numberPad)
            .opacity(0)
            .frame(width: 1, height: 1)

            VStack(alignment: .leading, spacing: Spacing.spacing16) {
                // Row 1: PIN slots + QR icon
                HStack {
                    // PIN slots
                    HStack(spacing: Spacing.spacing4) {
                        ForEach(0 ..< itemCount, id: \.self) { index in
                            pinSlot(at: index)
                        }
                    }

                    if onScanQrClick != nil {
                        Spacer()
                        Button {
                            onScanQrClick?()
                        } label: {
                            EncoreIcon(iconName: "LQrCodeScanner", size: 32)
                                .foregroundColor(Color.encore("Text/Secondary"))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Row 2: Resend OTP line
                if showResendOtp {
                    resendLine
                }
            }
        }
    }

    // MARK: - Slot

    @ViewBuilder
    private func pinSlot(at index: Int) -> some View {
        let chars = Array(pinValue)
        let isFilled = index < chars.count

        let fillColor: Color = isFilled ? Color.encore("Background/Default") : Color.encore("Background/ColumnHeading")
        let borderColor: Color = isFilled ? Color.encore("Success/Main") : Color.encore("Divider")
        let borderWidth: CGFloat = isFilled ? 3 : 0.5

        ZStack {
            if isFilled {
                Text(String(chars[index]))
                    .typography(Typography.Input.value)
                    .foregroundColor(Color.encore("Text/Primary"))
            } else {
                Circle()
                    .stroke(Color.encore("Divider"), lineWidth: 1)
                    .frame(width: 12, height: 12)
            }
        }
        .frame(width: 56, height: 56)
        .background(RoundedRectangle(cornerRadius: 8).fill(fillColor))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(borderColor, lineWidth: borderWidth))
    }

    // MARK: - Resend line

    @ViewBuilder
    private var resendLine: some View {
        if let countdown = formattedCountdown {
            // Countdown active — disabled resend
            (
                Text("Didn't receive OTP? ")
                    .foregroundColor(Color.encore("Text/Secondary"))
                + Text("Resend in \(countdown)")
                    .underline()
                    .foregroundColor(Color.encore("Divider"))
            )
            .typography(Typography.label2)
        } else {
            // Countdown expired (or never started) — tappable resend
            (
                Text("Didn't receive OTP? ")
                    .foregroundColor(Color.encore("Text/Secondary"))
                + Text("Resend")
                    .underline()
                    .foregroundColor(Color.encore("Primary/Main"))
            )
            .typography(Typography.label2)
            .onTapGesture {
                onResendOtpClick?()
                if let duration = resendOtpCountdownDuration, duration > 0 {
                    remainingSeconds = duration
                    startCountdown()
                }
            }
        }
    }

    // MARK: - Timer

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
