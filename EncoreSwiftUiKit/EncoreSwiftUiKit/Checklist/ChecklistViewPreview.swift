import SwiftUI

/// Preview for ChecklistView demonstrating all item types.
/// Mirrors Android's `ChecklistViewPreview` composable.
    struct ChecklistViewPreview: PreviewProvider {
        static var previews: some View {
            ChecklistView(
                header: "Complete Your Information",
                items: [
                    ChecklistItem(
                        key: "accept_terms",
                        item: "Accept Terms and Conditions",
                        optional: false,
                        format: .boolean
                    ),
                    ChecklistItem(
                        key: "delivery_option",
                        item: "Select Delivery Option",
                        optional: false,
                        format: .singleChoice,
                        allowedValues: [
                            ChecklistPossibleValue(key: "standard", displayText: "Standard Delivery"),
                            ChecklistPossibleValue(key: "express", displayText: "Express Delivery"),
                            ChecklistPossibleValue(key: "overnight", displayText: "Overnight Delivery"),
                        ]
                    ),
                    ChecklistItem(
                        key: "services",
                        item: "Select Services",
                        optional: false,
                        format: .multiChoice,
                        allowedValues: [
                            ChecklistPossibleValue(key: "service_a", displayText: "Service A"),
                            ChecklistPossibleValue(key: "service_b", displayText: "Service B"),
                            ChecklistPossibleValue(key: "service_c", displayText: "Service C"),
                        ]
                    ),
                    ChecklistItem(
                        key: "pin",
                        item: "Enter PIN",
                        optional: false,
                        format: .pin,
                        possibleValues: ["1234"]
                    ),
                    ChecklistItem(
                        key: "rating",
                        item: "Service Rating",
                        optional: true,
                        format: .rating
                    ),
                    ChecklistItem(
                        key: "date",
                        item: "Select Date",
                        optional: false,
                        format: .date
                    ),
                    ChecklistItem(
                        key: "email_field",
                        item: "Email Address",
                        optional: false,
                        format: .textField,
                        additionalOptions: [
                            "hint": "Enter your email",
                            "regex": "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$",
                        ]
                    ),
                    ChecklistItem(
                        key: "photo",
                        item: "Take Photo",
                        optional: false,
                        format: .photo
                    ),
                    ChecklistItem(
                        key: "multi_photo",
                        item: "Add Multiple Photos",
                        optional: true,
                        format: .multiPhoto
                    ),
                    ChecklistItem(
                        key: "signature",
                        item: "Add Signature",
                        optional: false,
                        format: .signature
                    ),
                    ChecklistItem(
                        key: "terms_url",
                        item: "Terms and Conditions",
                        optional: false,
                        format: .url,
                        possibleValues: ["https://example.com/terms"]
                    ),
                    ChecklistItem(
                        key: "privacy_url",
                        item: "Privacy Policy",
                        optional: false,
                        format: .urlWithFeedback,
                        possibleValues: ["https://example.com/privacy"]
                    ),
                ],
                onSubmit: { checklistMap in
                    print("Submitted: \(checklistMap)")
                },
                submitButtonText: "Submit",
                itemCallbacks: { itemKey, format in
                    switch format {
                    case .pin:
                        return ChecklistItemCallbacks(
                            pinCallbacks: PinItemCallbacks(
                                onScanQrClick: {
                                    print("Scan QR clicked for item: \(itemKey)")
                                },
                                onResendOtpClick: {
                                    print("Resend OTP clicked for item: \(itemKey)")
                                },
                                resendOtpCountdownDuration: 60,
                                showResendOtp: true
                            )
                        )
                    case .url, .urlWithFeedback:
                        return ChecklistItemCallbacks(
                            urlCallbacks: UrlItemCallbacks(
                                onUrlClick: {
                                    print("URL clicked for item: \(itemKey)")
                                }
                            )
                        )
                    default:
                        return nil
                    }
                }
            )
        }
    }
