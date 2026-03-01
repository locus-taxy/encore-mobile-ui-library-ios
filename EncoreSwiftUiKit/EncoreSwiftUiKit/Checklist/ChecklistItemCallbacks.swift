import Foundation

/// Callbacks for PIN/OTP checklist items.
/// Mirrors Android's `PinItemCallbacks` data class.
public struct PinItemCallbacks {
    /// Optional callback when QR code scan button is clicked
    public let onScanQrClick: (() -> Void)?
    /// Optional callback when resend OTP button is clicked
    public let onResendOtpClick: (() -> Void)?
    /// Optional countdown duration in seconds (e.g., 60 for 1 minute)
    public let resendOtpCountdownDuration: Int?
    /// Whether to show the resend OTP button
    public let showResendOtp: Bool

    public init(
        onScanQrClick: (() -> Void)? = nil,
        onResendOtpClick: (() -> Void)? = nil,
        resendOtpCountdownDuration: Int? = nil,
        showResendOtp: Bool = false
    ) {
        self.onScanQrClick = onScanQrClick
        self.onResendOtpClick = onResendOtpClick
        self.resendOtpCountdownDuration = resendOtpCountdownDuration
        self.showResendOtp = showResendOtp
    }
}

/// Callbacks for URL checklist items.
/// Mirrors Android's `UrlItemCallbacks` data class.
public struct UrlItemCallbacks {
    /// Optional callback when URL is clicked
    public let onUrlClick: (() -> Void)?

    public init(onUrlClick: (() -> Void)? = nil) {
        self.onUrlClick = onUrlClick
    }
}

/// Callbacks for Image checklist items (PHOTO, PHOTO_GALLERY, MULTI_PHOTO).
/// Mirrors Android's `ImageItemCallbacks` data class.
public struct ImageItemCallbacks {
    /// Optional callback to get caption text to add to image before saving
    public let onGetCaptionText: (() -> String?)?

    public init(onGetCaptionText: (() -> String?)? = nil) {
        self.onGetCaptionText = onGetCaptionText
    }
}

/// Callbacks for Signature checklist items.
/// Mirrors Android's `SignatureItemCallbacks` data class.
public struct SignatureItemCallbacks {
    /// Optional callback to get caption text to add to signature before saving
    public let onGetCaptionText: (() -> String?)?

    public init(onGetCaptionText: (() -> String?)? = nil) {
        self.onGetCaptionText = onGetCaptionText
    }
}

/// Container for callbacks for different checklist item types.
/// Mirrors Android's `ChecklistItemCallbacks` data class.
public struct ChecklistItemCallbacks {
    public let pinCallbacks: PinItemCallbacks?
    public let urlCallbacks: UrlItemCallbacks?
    public let imageCallbacks: ImageItemCallbacks?
    public let signatureCallbacks: SignatureItemCallbacks?

    public init(
        pinCallbacks: PinItemCallbacks? = nil,
        urlCallbacks: UrlItemCallbacks? = nil,
        imageCallbacks: ImageItemCallbacks? = nil,
        signatureCallbacks: SignatureItemCallbacks? = nil
    ) {
        self.pinCallbacks = pinCallbacks
        self.urlCallbacks = urlCallbacks
        self.imageCallbacks = imageCallbacks
        self.signatureCallbacks = signatureCallbacks
    }
}

/// Provider function type for checklist item callbacks.
/// Receives the item key and format, and returns appropriate callbacks or nil.
/// Mirrors Android's `ChecklistItemCallbackProvider` typealias.
public typealias ChecklistItemCallbackProvider = (_ itemKey: String, _ format: ChecklistItemFormat) -> ChecklistItemCallbacks?

