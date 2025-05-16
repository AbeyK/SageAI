import UIKit

/// Dark-mode–forward palette for the "Sage" meditation app.
/// • No translucency or alpha tweaks.  
/// • Panda-orange (#E36A3B) is reserved for the main CTA only.  
/// • Everything else lives in a calm, midnight-slate spectrum for low-light use.
extension UIColor {

    // MARK: - Hex helper
    convenience init(hex: Int) {
        self.init(
            red:   CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >>  8) & 0xFF) / 255.0,
            blue:  CGFloat( hex        & 0xFF) / 255.0,
            alpha: 1.0
        )
    }

    // MARK: - Interface Style Helper
    private static var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
        // Default to dark mode for older iOS versions or if style cannot be determined
        return true 
    }

    // MARK: - Foundations (major surfaces)

    /// Light mode: #fff8df, Dark mode: #22262F — rich midnight slate that blankets the entire root view.
    static var appBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x22262F) : UIColor(hex: 0xfff8df)
    }

    /// Light mode:#e0e8d8, Dark mode: #374050 — subtly lighter slate ring behind the panda avatar.
    static var pandaCircleBackground: UIColor {
        // return isDarkMode ? UIColor(hex: 0x374050) : UIColor(hex: 0xc4d1bc)
        // The line below was commented out in the user's previous change. I'm keeping it commented.
        // static let pandaCircleBackground = UIColor(hex: 0x374050)
        return isDarkMode ? UIColor(hex: 0x374050) : UIColor(hex: 0xe0e8d8)
    }
    
    // static let pandaCircleBackground = UIColor(hex: 0x374050) // This line was commented out by user, I'm keeping it that way

    /// Light mode: #f0e1c0, Dark mode: #284B65 — Sage's chat-bubble fill (dark blue-grey).
    static var chatBubbleBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x284B65) : UIColor(hex: 0xf0e1c0)
    }

    /// Light mode: #d6e4d4, Dark mode: #2F3644 — User's chat-bubble fill (deep teal-slate for contrast).
    static var userChatBubbleBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x2F3644) : UIColor(hex: 0xd6e4d4)
    }

    /// Light mode: #f0e8cf, Dark mode: #374050 — Same tone as the root view for seamless scrolling.
    static var chatTableViewBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x374050) : UIColor(hex: 0xf0e8cf)
    }

    // MARK: - Text & Icons

    /// Light mode: #4A4A4A, Dark mode: #FDF5EB — warm cream body text inside all bubbles.
    static var chatBubbleText: UIColor {
        return isDarkMode ? UIColor(hex: 0xFDF5EB) : UIColor(hex: 0x4A4A4A)
    }

    /// #A0B4C1 — muted blue-grey tint for status label & gear icon.
    static let statusLabelAndIcon = UIColor(hex: 0xA0B4C1)

    // MARK: - Primary CTA

    /// Light mode: #93b59b, Dark mode: #cb631b — primary button color
    static var primaryButtonBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0xcb631b) : UIColor(hex: 0x93b59b)
    }

    /// Pure white for legibility atop the orange button.
    static let primaryButtonText = UIColor.white

    // MARK: - Panda accents (rarely used)

    /// Same panda orange for any future live voice indicators / badges.
    static let pandaAccentOrange = UIColor(hex: 0xE36A3B)

    /// #6B3A1E — solid brown for hairline dividers or subtle shadows.
    static let pandaAccentBrown = UIColor(hex: 0x6B3A1E)
}
