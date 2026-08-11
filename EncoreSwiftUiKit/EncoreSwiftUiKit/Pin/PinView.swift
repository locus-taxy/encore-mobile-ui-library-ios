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
    @FocusState private var isFocused: Bool
    /// Editable backing store the (transparent) capture field binds to directly.
    /// Filtering/capping happens in `onChange`, so entered digits stay fully
    /// editable (backspace + retype).
    @State private var input: String

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
        self._input = State(initialValue: pinValue)
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
        VStack(alignment: .leading, spacing: Spacing.spacing16) {
            // Row 1: PIN slots + QR icon
            HStack {
                // Visible slots with a transparent TextField overlaid on top: the
                // field owns keyboard input + focus (tap to focus natively), while
                // the slots render the digits. Text/caret are clear so only the
                // slots show.
                HStack(spacing: Spacing.spacing4) {
                    ForEach(0 ..< itemCount, id: \.self) { index in
                        pinSlot(at: index)
                    }
                }
                .overlay(captureField)

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

    // MARK: - Capture field

    // Design note — the 4-box look is rendered by `pinSlot` cells with ONE
    // transparent `TextField` overlaid on top capturing all input. Keeping a
    // single coherent value string means SMS one-time-code autofill + paste work
    // natively and there's no inter-field focus choreography.
    //
    // PARKED ENHANCEMENT (preferred, pure SwiftUI) — replace the single overlay
    // with 4 separate one-character `TextField`s (one per box) for a real per-box
    // caret and direct tap-to-box focus. Deferred because it needs explicit
    // handling for:
    //   • backspace on an already-empty box (SwiftUI fires no `onChange`, so
    //     focus-retreat needs a zero-width-space sentinel or equivalent),
    //   • SMS autofill / paste delivering the whole code into one box,
    //   • `@FocusState` auto-advance / retreat across the boxes.
    // Until then, the single-field-behind-slots approach stays.
    private var captureField: some View {
        TextField("", text: $input)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($isFocused)
            .foregroundColor(.clear) // digits render in the slots, not here
            .tint(.clear) // hide the caret
            .contentShape(Rectangle())
            .onChange(of: input) { newValue in
                // Filter to digits, cap at itemCount. Every edit (incl. backspace)
                // flows through here, so entered digits can always be changed.
                let filtered = String(newValue.filter(\.isNumber).prefix(itemCount))
                if filtered != newValue { input = filtered }
                if filtered != pinValue { onPinChange(filtered) }
                // Auto-dismiss once the code is complete. The checklist's bottom
                // submit bar occupies the keyboard-accessory slot, so a Done
                // toolbar can't show; swipe-to-dismiss (ChecklistView's
                // `.scrollDismissesKeyboard`) covers the partial-entry case.
                if filtered.count == itemCount { isFocused = false }
            }
            .onChange(of: pinValue) { newValue in
                // Reflect external changes (draft restore / clear).
                if newValue != input { input = newValue }
            }
    }

    // MARK: - Slot

    @ViewBuilder
    private func pinSlot(at index: Int) -> some View {
        let chars = Array(input)
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
