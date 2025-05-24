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

    /// Light mode:#b8ccde, Dark mode: #22262F — light beige with subtle green undertones for a calm, natural feel.
    static var appBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x22262F) : UIColor(hex: 0xf1e8d0)
    }

    /// Light mode:#5e9e79, Dark mode:rgb(231, 215, 177) — light sage green that complements the earth tone palette.
    static var pandaCircleBackground: UIColor {
        // return isDarkMode ? UIColor(hex: 0x374050) : UIColor(hex: 0xc4d1bc)
        // The line below was commented out in the user's previous change. I'm keeping it commented.
        // static let pandaCircleBackground = UIColor(hex: 0x374050)
        return isDarkMode ? UIColor(hex: 0x374050): UIColor(hex: 0x5a7f8e).withAlphaComponent(0.6)
    }
    
    // static let pandaCircleBackground = UIColor(hex: 0x374050) // This line was commented out by user, I'm keeping it that way

    // MARK: - Chat Colors
    
    /// Light mode: #D4D9C0, Dark mode: #374050 — Slightly darker sage background for chat area with better contrast.
    static var chatTableViewBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x374050): UIColor(hex: 0x8e756e).withAlphaComponent(0.2)
    }

    static var homeScreenCardViewBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x374050): UIColor(hex: 0x8e756e)
    }
    /// AI/Sage messages - soft blue-gray for wisdom in dark mode
    static var aiChatBubbleBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x2F3644) : UIColor(hex: 0xC1C7A5)
    }

    /// Light mode: #718e96, Dark mode: #284B65 — User messages using muted blue-gray.
    static var userChatBubbleBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x284B65) : UIColor(hex: 0x8e756e)
    }

    // MARK: - Text & Icons

    /// Light mode: #4A4A4A, Dark mode: #FDF5EB — neutral gray body text for clean readability.
    static var chatBubbleText: UIColor {
        return isDarkMode ? UIColor(hex: 0xFDF5EB) : UIColor(hex: 0x4A4A4A)
    }

    /// User chat text - white text for readability on dusky blue background
    static var userChatBubbleText: UIColor {
        return UIColor.white
    }

    /// #6B7B8C — neutral dusky gray for status labels and icons, matching the app title.
    static var statusLabelAndIcon: UIColor {
        return isDarkMode ? UIColor(hex: 0x6B7B8C) : UIColor(hex: 0x8e756e)
    }
    /// Always dusky blue for ZenPal app title - distinctive and calming
    static var appTitleBlue: UIColor {
        return isDarkMode ? UIColor(hex: 0x6B7B8C) : UIColor(hex: 0x5a7f8e)
    }
    // MARK: - Primary CTA

    /// Light mode: #4C8A5C, Dark mode: more faded green — green for primary actions with appropriate intensity per mode
    static var primaryButtonBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x4C8A5C).withAlphaComponent(0.8) : UIColor(hex: 0x6a966a)
    }

    /// Light mode:rgb(108, 166, 108) brighter green, Dark mode: #66D17A — green for listening indicator, bright and attention-getting
    static var brightListeningIndicator: UIColor {
        return isDarkMode ? UIColor(hex: 0x66D17A) : UIColor(hex: 0x6b956b)
    }

    /// Pure white for legibility atop the earthy button colors.
    static let primaryButtonText = UIColor.white

    /// Progress bar text - muted brown for progress indicators
    static var progressBarText: UIColor {
        return isDarkMode ? UIColor(hex: 0xFDF5EB) : UIColor(hex: 0xFDF5EB)
    }

    /// Section title text - bold, prominent color for main section headings
    static var sectionTitleText: UIColor {
        return isDarkMode ? UIColor.white.withAlphaComponent(0.75) : UIColor(hex: 0x5a7f8e)
    }
    
    /// Section subtitle text - softer color for descriptive text under section titles
    static var sectionSubtitleText: UIColor {
        return isDarkMode ? UIColor(hex: 0x6B7B8C).withAlphaComponent(0.9) : UIColor(hex: 0x8e756e).withAlphaComponent(0.9)
    }

    /// Login form text - white in light mode for better contrast on login screens
    static var loginFormText: UIColor {
        return isDarkMode ? UIColor(hex: 0xFDF5EB) : UIColor.white
    }
    
    /// Login form placeholder text - lighter color for placeholders
    static var loginFormPlaceholder: UIColor {
        return isDarkMode ? UIColor(hex: 0x6B7B8C) : UIColor.white.withAlphaComponent(0.7)
    }

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

    /// Meditation button - warm plum/mauve for calm, meditative feeling
    static var meditationButtonBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x8B7B8B) : UIColor(hex: 0xA08DA0)
    }
    
    /// Sleep button - muted gray to indicate not implemented
    static var sleepButtonBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x4A4A4A) : UIColor(hex: 0xD3D3D3)
    }
    
    /// Voice Journal button - muted gray to indicate not implemented  
    static var journalButtonBackground: UIColor {
        return isDarkMode ? UIColor(hex: 0x4A4A4A) : UIColor(hex: 0xD3D3D3)
    }
}
