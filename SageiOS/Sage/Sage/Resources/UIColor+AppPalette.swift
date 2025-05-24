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

    // MARK: - Helper function for dynamic colors
    private static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                return traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        } else {
            return light // Default to light for older iOS
        }
    }

    // MARK: - Foundations (major surfaces)

    /// Light mode:#f1e8d0, Dark mode: #22262F — light beige with subtle green undertones for a calm, natural feel.
    static var appBackground: UIColor {
        return dynamicColor(light: UIColor(hex: 0xf1e8d0), dark: UIColor(hex: 0x22262F))
    }

    /// Light mode:#5a7f8e with alpha, Dark mode: #374050 — light sage green that complements the earth tone palette.
    static var pandaCircleBackground: UIColor {
        return dynamicColor(light: UIColor(hex: 0x5a7f8e).withAlphaComponent(0.6), dark: UIColor(hex: 0x374050))
    }

    // MARK: - Chat Colors
    
    /// Light mode: #D4D9C0, Dark mode: #374050 — Slightly darker sage background for chat area with better contrast.
    static var chatTableViewBackground: UIColor {
        return dynamicColor(light: UIColor(hex: 0x8e756e).withAlphaComponent(0.2), dark: UIColor(hex: 0x374050))
    }

    static var homeScreenCardViewBackground: UIColor {
        return dynamicColor(light: UIColor(hex: 0x8e756e), dark: UIColor(hex: 0x374050))
    }
    /// AI/Sage messages - soft blue-gray for wisdom in dark mode
    static var aiChatBubbleBackground: UIColor {
        return dynamicColor(light: UIColor(hex: 0xC1C7A5), dark: UIColor(hex: 0x2F3644))
    }

    /// Light mode: #718e96, Dark mode: #284B65 — User messages using muted blue-gray.
    static var userChatBubbleBackground: UIColor {
        return dynamicColor(light: UIColor(hex: 0x8e756e), dark: UIColor(hex: 0x284B65))
    }

    // MARK: - Text & Icons

    /// Light mode: #4A4A4A, Dark mode: #FDF5EB — neutral gray body text for clean readability.
    static var chatBubbleText: UIColor {
        return dynamicColor(light: UIColor(hex: 0x4A4A4A), dark: UIColor(hex: 0xFDF5EB))
    }

    /// User chat text - white text for readability on dusky blue background
    static var userChatBubbleText: UIColor {
        return UIColor.white
    }

    /// #6B7B8C — neutral dusky gray for status labels and icons, matching the app title.
    static var statusLabelAndIcon: UIColor {
        return dynamicColor(light: UIColor(hex: 0x8e756e), dark: UIColor(hex: 0x6B7B8C))
    }
    /// Always dusky blue for ZenPal app title - distinctive and calming
    static var appTitleBlue: UIColor {
        return dynamicColor(light: UIColor(hex: 0x5a7f8e), dark: UIColor(hex: 0x6B7B8C))
    }
    // MARK: - Primary CTA

    /// Light mode: #4C8A5C, Dark mode: more faded green — green for primary actions with appropriate intensity per mode
    static var primaryButtonBackground: UIColor {
        return dynamicColor(light: UIColor(hex: 0x6a966a), dark: UIColor(hex: 0x4C8A5C).withAlphaComponent(0.8))
    }

    /// Light mode:rgb(108, 166, 108) brighter green, Dark mode: #66D17A — green for listening indicator, bright and attention-getting
    static var brightListeningIndicator: UIColor {
        return dynamicColor(light: UIColor(hex: 0x6b956b), dark: UIColor(hex: 0x66D17A))
    }

    /// Pure white for legibility atop the earthy button colors.
    static let primaryButtonText = UIColor.white

    /// Progress bar text - muted brown for progress indicators
    static var progressBarText: UIColor {
        return UIColor(hex: 0xFDF5EB) // Same for both modes
    }

    /// Section title text - bold, prominent color for main section headings
    static var sectionTitleText: UIColor {
        return dynamicColor(light: UIColor(hex: 0x5a7f8e), dark: UIColor.white)
    }
    
    /// Section subtitle text - softer color for descriptive text under section titles
    static var sectionSubtitleText: UIColor {
        return dynamicColor(light: UIColor(hex: 0x8e756e).withAlphaComponent(0.9), dark: UIColor(hex: 0x6B7B8C).withAlphaComponent(0.9))
    }

    /// Login form text - white in light mode for better contrast on login screens
    static var loginFormText: UIColor {
        return dynamicColor(light: UIColor.white, dark: UIColor(hex: 0xFDF5EB))
    }
    
    /// Login form placeholder text - lighter color for placeholders
    static var loginFormPlaceholder: UIColor {
        return dynamicColor(light: UIColor.white.withAlphaComponent(0.7), dark: UIColor(hex: 0x6B7B8C))
    }

    // MARK: - Warm Earth Accents

    /// Warm golden yellow for highlights and special elements
    static let warmGoldenAccent = UIColor(hex: 0xD4AC0D)
    
    /// Rich earth brown for secondary elements
    static let earthBrownAccent = UIColor(hex: 0x8B4513)

    // MARK: - Panda accents (rarely used)

    /// Light mode: #DC3545, Dark mode: #FF6B6B — reddish warning color for sign out and destructive actions.
    static var pandaAccentOrange: UIColor {
        return dynamicColor(light: UIColor(hex: 0xDC3545), dark: UIColor(hex: 0xFF6B6B))
    }

    /// #6B3A1E — solid brown for hairline dividers or subtle shadows.
    static let pandaAccentBrown = UIColor(hex: 0x6B3A1E)

    // MARK: - Distinct Button Colors

    /// Meditation button - warm plum/mauve for calm, meditative feeling
    static var meditationButtonBackground: UIColor {
        return dynamicColor(light: UIColor(hex: 0xA08DA0), dark: UIColor(hex: 0x8B7B8B))
    }
    
    /// Sleep button - muted gray to indicate not implemented
    static var sleepButtonBackground: UIColor {
        return dynamicColor(light: UIColor(hex: 0xD3D3D3), dark: UIColor(hex: 0x4A4A4A))
    }
    
    /// Voice Journal button - muted gray to indicate not implemented  
    static var journalButtonBackground: UIColor {
        return dynamicColor(light: UIColor(hex: 0xD3D3D3), dark: UIColor(hex: 0x4A4A4A))
    }
}
