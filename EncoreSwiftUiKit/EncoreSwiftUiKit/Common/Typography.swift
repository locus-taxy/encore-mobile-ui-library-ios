import CoreText
import SwiftUI

public struct TypographyStyle {
    public let font: Font
    public let tracking: CGFloat

    public init(font: Font, tracking: CGFloat = 0) {
        self.font = font
        self.tracking = tracking
    }
}

public extension View {
    @ViewBuilder func typography(_ style: TypographyStyle) -> some View {
        if #available(iOS 16.0, *) {
            self.font(style.font).tracking(style.tracking)
        } else {
            // tracking() requires iOS 16; letter spacing is not applied on iOS 15.
            self.font(style.font)
        }
    }
}

// Registers all four Inter variants once, lazily, before first use.
private let _registerInterFonts: Void = {
    let names = ["Inter-Regular", "Inter-Medium", "Inter-MediumItalic", "Inter-SemiBold"]
    for name in names {
        guard let url = BundleToken.bundle.url(forResource: name, withExtension: "ttf") else {
            assertionFailure("Missing font resource: \(name).ttf")
            continue
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}()

// Inter PostScript names in the bundled .ttf files use an "18pt" optical-size suffix
// (e.g. Inter18pt-Medium). If font files are ever updated, verify PostScript names via
// Font Book → Get Info, or `fc-query <file>.ttf | grep postscriptname`.
private func inter(_ psName: String, size: CGFloat) -> Font {
    _ = _registerInterFonts
    return Font.custom("Inter18pt-\(psName)", size: size)
}

public enum Typography {

    // MARK: - Base type scale

    public static let h1 = TypographyStyle(font: inter("Medium",   size: 42))
    public static let h2 = TypographyStyle(font: inter("Medium",   size: 36))
    public static let h3 = TypographyStyle(font: inter("Medium",   size: 32))
    public static let h4 = TypographyStyle(font: inter("Medium",   size: 24))
    public static let h5 = TypographyStyle(font: inter("SemiBold", size: 20))
    public static let h6 = TypographyStyle(font: inter("SemiBold", size: 16))

    public static let label0 = TypographyStyle(font: inter("Medium", size: 16))
    public static let label1 = TypographyStyle(font: inter("Medium", size: 14))
    public static let label2 = TypographyStyle(font: inter("Medium", size: 12))
    public static let label3 = TypographyStyle(font: inter("Medium", size: 10), tracking: 0.46)

    public static let body0 = TypographyStyle(font: inter("Regular", size: 16))
    public static let body1 = TypographyStyle(font: inter("Regular", size: 14))
    public static let body2 = TypographyStyle(font: inter("Regular", size: 12))
    public static let body3 = TypographyStyle(font: inter("Regular", size: 10), tracking: 0.46)

    public static let italics0 = TypographyStyle(font: inter("MediumItalic", size: 16))
    public static let italics1 = TypographyStyle(font: inter("MediumItalic", size: 14))
    public static let italics2 = TypographyStyle(font: inter("MediumItalic", size: 12))
    public static let italics3 = TypographyStyle(font: inter("MediumItalic", size: 10), tracking: 0.46)

    // Consumer adds .underline() modifier for link styles.
    public static let link0 = TypographyStyle(font: inter("Medium", size: 16))
    public static let link1 = TypographyStyle(font: inter("Medium", size: 14))
    public static let link2 = TypographyStyle(font: inter("Medium", size: 12))

    public static let subtitle1 = TypographyStyle(font: inter("Regular", size: 14), tracking: 0.15)
    public static let subtitle2 = TypographyStyle(font: inter("Medium",  size: 12), tracking: 0.17)

    // Consumer adds .textCase(.uppercase) for overline styles.
    public static let overline0 = TypographyStyle(font: inter("SemiBold", size: 16))
    public static let overline1 = TypographyStyle(font: inter("SemiBold", size: 14))
    public static let overline2 = TypographyStyle(font: inter("SemiBold", size: 12))
    public static let overline3 = TypographyStyle(font: inter("SemiBold", size: 10), tracking: 0.46)

    public static let caption = TypographyStyle(font: inter("Regular", size: 10), tracking: 0.4)

    // MARK: - Component styles

    public enum Alert {
        public static let title       = TypographyStyle(font: inter("Medium",  size: 16), tracking: 0.15)
        public static let description = TypographyStyle(font: inter("Regular", size: 14), tracking: 0.15)
    }

    public enum Avatar {
        public static let initialsXLg = TypographyStyle(font: inter("SemiBold", size: 24), tracking: 0.14)
        public static let initialsLg  = TypographyStyle(font: inter("SemiBold", size: 16), tracking: 0.14)
        public static let initialsMd  = TypographyStyle(font: inter("SemiBold", size: 12))
        public static let initialsSm  = TypographyStyle(font: inter("SemiBold", size: 10))
    }

    public enum Badge {
        public static let label = TypographyStyle(font: inter("Medium", size: 12), tracking: 0.14)
    }

    public enum BottomNavigation {
        public static let activeLabel = TypographyStyle(font: inter("Regular", size: 14), tracking: 0.4)
    }

    public enum Button {
        public static let large  = TypographyStyle(font: inter("SemiBold", size: 16))
        public static let medium = TypographyStyle(font: inter("SemiBold", size: 14))
        public static let small  = TypographyStyle(font: inter("SemiBold", size: 12))
    }

    public enum Chip {
        public static let labelSmall = TypographyStyle(font: inter("Medium", size: 13), tracking: 0.16)
        public static let label      = TypographyStyle(font: inter("Medium", size: 14), tracking: 0.16)
        public static let labelLg    = TypographyStyle(font: inter("Medium", size: 16), tracking: 0.16)
        public static let labelXLg   = TypographyStyle(font: inter("Medium", size: 18), tracking: 0.16)
    }

    public enum Status {
        // Consumer adds .textCase(.uppercase)
        public static let label = TypographyStyle(font: inter("Medium", size: 12), tracking: 0.4)
    }

    public enum DatePicker {
        public static let currentMonth = TypographyStyle(font: inter("Medium", size: 16), tracking: 0.15)
    }

    public enum Input {
        public static let label  = TypographyStyle(font: inter("Regular", size: 12), tracking: 0.15)
        public static let value  = TypographyStyle(font: inter("Regular", size: 16), tracking: 0.15)
        public static let helper = TypographyStyle(font: inter("Regular", size: 12), tracking: 0.4)
    }

    public enum List {
        public static let subheader = TypographyStyle(font: inter("Medium", size: 12), tracking: 0.1)
    }

    public enum Menu {
        public static let itemLarge   = TypographyStyle(font: inter("Regular", size: 16), tracking: 0.15)
        public static let itemDefault = TypographyStyle(font: inter("Regular", size: 14), tracking: 0.15)
        public static let itemDense   = TypographyStyle(font: inter("Regular", size: 12), tracking: 0.17)
    }

    public enum Table {
        public static let header = TypographyStyle(font: inter("Medium", size: 12), tracking: 0.17)
    }

    public enum Tooltip {
        public static let label = TypographyStyle(font: inter("Medium", size: 10))
    }

    public enum DataGrid {
        // Consumer adds .textCase(.uppercase)
        public static let aggregationColumnHeaderLabel = TypographyStyle(font: inter("Medium", size: 12), tracking: 0.15)
    }

    public enum Nav {
        public static let sidebarCompact = TypographyStyle(font: inter("Medium", size: 9),  tracking: 0.04)
        public static let sidebarWide    = TypographyStyle(font: inter("Medium", size: 12), tracking: 0.05)
    }
}
