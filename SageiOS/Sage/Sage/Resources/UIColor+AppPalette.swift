import UIKit

/// Dark-mode–forward palette for the “Sage” meditation app.
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

    // MARK: - Foundations (major surfaces)

    /// #22262F — rich midnight slate that blankets the entire root view.
    static let appBackground = UIColor(hex: 0x22262F)

    /// #374050 — subtly lighter slate ring behind the panda avatar.
    static let pandaCircleBackground = UIColor(hex: 0x374050)

    /// #2F3644 — Sage’s chat-bubble fill (dark blue-grey).
    static let chatBubbleBackground = UIColor(hex: 0x284B65)

    /// #284B65 — User’s chat-bubble fill (deep teal-slate for contrast).
    static let userChatBubbleBackground = UIColor(hex: 0x2F3644)

    /// Same tone as the root view for seamless scrolling.
    static let chatTableViewBackground = UIColor(hex: 0x374050)

    // MARK: - Text & Icons

    /// #FDF5EB — warm cream body text inside all bubbles.
    static let chatBubbleText = UIColor(hex: 0xFDF5EB)

    /// #A0B4C1 — muted blue-grey tint for status label & gear icon.
    static let statusLabelAndIcon = UIColor(hex: 0xA0B4C1)

    // MARK: - Primary CTA

    /// #E36A3B — panda-fur orange reserved exclusively for
    ///           “Start My Meditation” (high-attention button).
    static let primaryButtonBackground = UIColor(hex: 0xcb631b)

    /// Pure white for legibility atop the orange button.
    static let primaryButtonText = UIColor.white

    // MARK: - Panda accents (rarely used)

    /// Same panda orange for any future live voice indicators / badges.
    static let pandaAccentOrange = UIColor(hex: 0xE36A3B)

    /// #6B3A1E — solid brown for hairline dividers or subtle shadows.
    static let pandaAccentBrown = UIColor(hex: 0x6B3A1E)
}
