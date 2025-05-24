import UIKit

/// Typography system for ZenPal meditation app
/// Provides calming, mindful font choices for better user experience
struct FontManager {
    
    // MARK: - Font Names (Variable Fonts)
    
    /// Primary font family: Nunito Sans - Clean, calm, and highly readable
    static let nunitoSans = "NunitoSans"
    
    /// Secondary font family: Source Serif 4 - Elegant and warm for headings
    static let sourceSerif = "SourceSerif4"
    
    /// Accent font family: Comfortaa - Rounded, friendly for special elements
    static let comfortaa = "Comfortaa"
    
    /// Modern clean font: Inter - Very clean and readable
    static let inter = "Inter"
    
    // MARK: - Typography Scale
    
    /// App title and main branding - warm serif for elegance
    static func appTitle(size: CGFloat = 36) -> UIFont {
        return createFont(name: comfortaa, size: size, weight: .bold) ??
               .boldSystemFont(ofSize: size)
    }
    
    /// Large headings (like screen titles) - serif for warmth
    static func heading1(size: CGFloat = 28) -> UIFont {
        return createFont(name: comfortaa, size: size, weight: .semibold) ??
               createFont(name: nunitoSans, size: size, weight: .semibold) ??
               .systemFont(ofSize: size, weight: .semibold)
    }
    
    /// Medium headings (like section titles) - serif for personality
    static func heading2(size: CGFloat = 22) -> UIFont {
        return createFont(name: sourceSerif, size: size, weight: .medium) ??
               createFont(name: nunitoSans, size: size, weight: .medium) ??
               .systemFont(ofSize: size, weight: .medium)
    }
    
    /// Small headings and important labels - clean sans serif
    static func heading3(size: CGFloat = 18) -> UIFont {
        return createFont(name: nunitoSans, size: size, weight: .semibold) ??
               createFont(name: inter, size: size, weight: .semibold) ??
               .systemFont(ofSize: size, weight: .semibold)
    }
    
    /// Body text and descriptions - highly readable sans serif
    static func body(size: CGFloat = 18) -> UIFont {
        return createFont(name: nunitoSans, size: size, weight: .regular) ??
               createFont(name: inter, size: size, weight: .regular) ??
               .systemFont(ofSize: size)
    }
    
    /// Body text with emphasis
    static func bodyMedium(size: CGFloat = 16) -> UIFont {
        return createFont(name: nunitoSans, size: size, weight: .medium) ??
               createFont(name: inter, size: size, weight: .medium) ??
               .systemFont(ofSize: size, weight: .medium)
    }
    
    /// Small text, captions, and labels
    static func caption(size: CGFloat = 14) -> UIFont {
        return createFont(name: nunitoSans, size: size, weight: .regular) ??
               createFont(name: inter, size: size, weight: .regular) ??
               .systemFont(ofSize: size)
    }
    
    /// Very small text
    static func footnote(size: CGFloat = 12) -> UIFont {
        return createFont(name: nunitoSans, size: size, weight: .light) ??
               createFont(name: inter, size: size, weight: .light) ??
               .systemFont(ofSize: size, weight: .light)
    }
    
    /// Button text - clean and readable
    static func button(size: CGFloat = 17) -> UIFont {
        return createFont(name: nunitoSans, size: size, weight: .semibold) ??
               createFont(name: inter, size: size, weight: .semibold) ??
               .systemFont(ofSize: size, weight: .semibold)
    }
    
    /// Special accent text (like meditation status labels) - rounded and friendly
    static func accent(size: CGFloat = 18) -> UIFont {
        return createFont(name: comfortaa, size: size, weight: .medium) ??
               createFont(name: nunitoSans, size: size, weight: .medium) ??
               .systemFont(ofSize: size, weight: .medium)
    }
    
    /// Large timer/countdown text - clean and bold
    static func timer(size: CGFloat = 48) -> UIFont {
        return createFont(name: nunitoSans, size: size, weight: .bold) ??
               createFont(name: inter, size: size, weight: .bold) ??
               .systemFont(ofSize: size, weight: .bold)
    }
    
    // MARK: - Helper Methods
    
    /// Creates a font with specific weight for variable fonts
    private static func createFont(name: String, size: CGFloat, weight: UIFont.Weight) -> UIFont? {
        // For variable fonts, we can use the font descriptor to set weight
        guard let font = UIFont(name: name, size: size) else {
            return nil
        }
        
        // Create font descriptor with the desired weight
        let descriptor = font.fontDescriptor.addingAttributes([
            .traits: [
                UIFontDescriptor.TraitKey.weight: weight.rawValue
            ]
        ])
        
        return UIFont(descriptor: descriptor, size: size)
    }
    
    /// Safely loads a custom font with fallback
    private static func font(name: String, size: CGFloat, fallback: UIFont) -> UIFont {
        return UIFont(name: name, size: size) ?? fallback
    }
    
    /// Check if all fonts are properly loaded
    static func areCustomFontsLoaded() -> Bool {
        let testFonts = [
            nunitoSans,
            sourceSerif,
            comfortaa,
            inter
        ]
        
        for fontName in testFonts {
            if UIFont(name: fontName, size: 16) == nil {
                print("⚠️ Font not found: \(fontName)")
                return false
            }
        }
        
        print("✅ All custom fonts loaded successfully")
        return true
    }
    
    /// List all available fonts (for debugging)
    static func listAvailableFonts() {
        for family in UIFont.familyNames.sorted() {
            print("Font Family: \(family)")
            for font in UIFont.fontNames(forFamilyName: family) {
                print("  - \(font)")
            }
        }
    }
    
    /// Initialize and check fonts (call this in AppDelegate)
    static func initialize() {
        print("🎨 FontManager: Initializing typography system...")
        
        if areCustomFontsLoaded() {
            print("🎨 FontManager: All fonts loaded successfully!")
        } else {
            print("⚠️ FontManager: Some fonts failed to load, using system fallbacks")
            print("📝 Available fonts:")
            listAvailableFonts()
        }
    }
}

// MARK: - UIFont Extensions for Convenience

extension UIFont {
    
    /// Convenience methods for ZenPal typography
    static var zenAppTitle: UIFont { FontManager.appTitle() }
    static var zenHeading1: UIFont { FontManager.heading1() }
    static var zenHeading2: UIFont { FontManager.heading2() }
    static var zenHeading3: UIFont { FontManager.heading3() }
    static var zenBody: UIFont { FontManager.body() }
    static var zenBodyMedium: UIFont { FontManager.bodyMedium() }
    static var zenCaption: UIFont { FontManager.caption() }
    static var zenFootnote: UIFont { FontManager.footnote() }
    static var zenButton: UIFont { FontManager.button() }
    static var zenAccent: UIFont { FontManager.accent() }
    static var zenTimer: UIFont { FontManager.timer() }
    
} 