import SwiftUI

/// Design tokens for ChecklistItem components.
/// Centralized location for all size, spacing, and typography values.
/// Mirrors Android's `ChecklistItemConstants` object.
public enum ChecklistItemConstants {
    /// Font size for checklist item titles
    public static let titleFontSize: CGFloat = 14

    /// Line height for checklist item titles
    public static let titleLineHeight: CGFloat = 20

    /// Font size for option text (single choice, multi choice)
    public static let optionFontSize: CGFloat = 16

    /// Line height for option text
    public static let optionLineHeight: CGFloat = 24

    /// Font size for URL text
    public static let urlTextFontSize: CGFloat = 14

    /// Line height for URL text
    public static let urlTextLineHeight: CGFloat = 20

    /// Font size for required indicator text
    public static let requiredTextFontSize: CGFloat = 14

    /// Line height for required indicator text
    public static let requiredTextLineHeight: CGFloat = 20

    /// Standard item padding
    public static let itemPadding: CGFloat = 15

    /// Standard top padding for inner component
    public static let innerTopPadding: CGFloat = 8
}

