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

    /// Light mode: #E0E5CC, Dark mode: #22262F — light beige with subtle green undertones for a calm, natural feel.
    static var appBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x22262F) : UIColor(hex: 0xE0E5CC)
    }

    /// Light mode: #B8CCB3, Dark mode: #374050 — light sage green that complements the earth tone palette.
    static var pandaCircleBackground: UIColor {
        // return isDarkMode ? UIColor(hex: 0x374050) : UIColor(hex: 0xc4d1bc)
        // The line below was commented out in the user's previous change. I'm keeping it commented.
        // static let pandaCircleBackground = UIColor(hex: 0x374050)
        return isDarkMode ? UIColor(hex: 0x374050) : UIColor(hex: 0xB8CCB3)
    }
    
    // static let pandaCircleBackground = UIColor(hex: 0x374050) // This line was commented out by user, I'm keeping it that way

    /// Light mode: #E8F0F5, Dark mode: #284B65 — AI/Sage messages with soft blue-gray for wisdom.
    static var chatBubbleBackground: UIColor {
        return aiChatBubbleBackground
    }

    /// Light mode: #F5F5F0, Dark mode: #2F3644 — User messages in warm cream for better contrast.
    static var userChatBubbleBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x2F3644) : UIColor(hex: 0xF2F0E8)
    }

    /// Light mode: #DCE1C8, Dark mode: #374050 — Subtle sage background for chat area that harmonizes with main background.
    static var chatTableViewBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x374050) : UIColor(hex: 0xDCE1C8)
    }

    // MARK: - Text & Icons

    /// Light mode: #4A4A4A, Dark mode: #FDF5EB — neutral gray body text for clean readability.
    static var chatBubbleText: UIColor {
        return isDarkMode ? UIColor(hex: 0xFDF5EB) : UIColor(hex: 0x4A4A4A)
    }

    /// #6B7B8C — neutral dusky gray for status labels and icons, matching the app title.
    static let statusLabelAndIcon = UIColor(hex: 0x6B7B8C)

    /// Always dusky blue for ZenPal app title - distinctive and calming
    static let appTitleBlue = UIColor(hex: 0x6B7B8C)

    // MARK: - Primary CTA

    /// Light mode: #6B8E5A, Dark mode: #4A9B5E — always green for primary actions and consistency
    static var primaryButtonBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x4A9B5E) : UIColor(hex: 0x6B8E5A)
    }

    /// Light mode: #5FB669, Dark mode: #66D17A — always green for listening indicator, consistent with primary actions
    static var brightListeningIndicator: UIColor {
        return isDarkMode ? UIColor(hex: 0x66D17A) : UIColor(hex: 0x5FB669)
    }

    /// Pure white for legibility atop the earthy button colors.
    static let primaryButtonText = UIColor.white

    // MARK: - Warm Earth Accents

    /// Warm golden yellow for highlights and special elements
    static let warmGoldenAccent = UIColor(hex: 0xD4AC0D)
    
    /// Rich earth brown for secondary elements
    static let earthBrownAccent = UIColor(hex: 0x8B4513)

    // MARK: - Panda accents (rarely used)

    /// Light mode: #DC3545, Dark mode: #FF6B6B — reddish warning color for sign out and destructive actions.
    static var pandaAccentOrange: UIColor {
        return isDarkMode ? UIColor(hex: 0xFF6B6B) : UIColor(hex: 0xDC3545)
    }

    /// #6B3A1E — solid brown for hairline dividers or subtle shadows.
    static let pandaAccentBrown = UIColor(hex: 0x6B3A1E)

    // MARK: - Distinct Button Colors

    /// Meditation button - vibrant sage green to stand out as the main implemented feature
    static var meditationButtonBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x4A9B5E) : UIColor(hex: 0x8DB88A)
    }
    
    /// Sleep button - muted gray to indicate not implemented
    static var sleepButtonBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x4A4A4A) : UIColor(hex: 0xD3D3D3)
    }
    
    /// Voice Journal button - muted gray to indicate not implemented  
    static var journalButtonBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x4A4A4A) : UIColor(hex: 0xD3D3D3)
    }

    // MARK: - Distinct Chat Colors
    
    /// AI/Sage messages - soft sage tone that harmonizes with the earth palette
    static var aiChatBubbleBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x284B65) : UIColor(hex: 0xE5E8DC)
    }
}
