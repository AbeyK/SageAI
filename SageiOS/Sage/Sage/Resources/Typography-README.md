# ZenPal Typography System

This document outlines the custom typography system implemented for the ZenPal meditation app, designed to create a calming, mindful user experience.

## Font Families

### Primary Fonts
- **Nunito Sans** - Clean, calm, and highly readable sans-serif for body text and UI elements
- **Source Serif 4** - Elegant and warm serif font for headings and titles
- **Comfortaa** - Rounded, friendly font for accent text and status labels
- **Inter** - Modern, clean fallback font

## Typography Scale

### Usage Guidelines

| Style | Font | Size | Weight | Usage |
|-------|------|------|--------|-------|
| `.zenAppTitle` | Source Serif 4 | 34pt | Bold | App branding, main title |
| `.zenHeading1` | Source Serif 4 | 28pt | SemiBold | Screen titles |
| `.zenHeading2` | Source Serif 4 | 22pt | Medium | Section headings |
| `.zenHeading3` | Nunito Sans | 18pt | SemiBold | Subsection headings |
| `.zenBody` | Nunito Sans | 16pt | Regular | Body text, descriptions |
| `.zenBodyMedium` | Nunito Sans | 16pt | Medium | Emphasized body text |
| `.zenCaption` | Nunito Sans | 14pt | Regular | Small text, captions |
| `.zenFootnote` | Nunito Sans | 12pt | Light | Very small text |
| `.zenButton` | Nunito Sans | 17pt | SemiBold | Button labels |
| `.zenAccent` | Comfortaa | 16pt | Medium | Status labels, special elements |
| `.zenTimer` | Nunito Sans | 48pt | Bold | Timer displays |

## Implementation

### Using the Typography System

```swift
// Use the convenient extensions
label.font = .zenHeading1
button.titleLabel?.font = .zenButton

// Or use the FontManager directly
label.font = FontManager.body(size: 18)
```

### Font Loading

Fonts are automatically loaded and initialized in `AppDelegate.swift`:

```swift
FontManager.initialize()
```

The system includes automatic fallbacks to system fonts if custom fonts fail to load.

## Design Philosophy

The typography system follows these principles:

1. **Calming Hierarchy** - Serif fonts for headings create warmth, sans-serif for readability
2. **Mindful Spacing** - Generous line heights and spacing for easy reading
3. **Accessibility** - High contrast ratios and readable font sizes
4. **Consistency** - Unified system across all app screens
5. **Zen Aesthetic** - Fonts chosen to evoke tranquility and mindfulness

## Font Files

The following font files are included in the app bundle:
- `NunitoSans-Regular.ttf` (Variable font)
- `SourceSerif4-Regular.ttf` (Variable font)
- `Comfortaa-Regular.ttf` (Variable font)
- `Inter-Regular.ttf` (Variable font)

All fonts are registered in `Info.plist` under the `UIAppFonts` key.

## Maintenance

To add new font styles:
1. Add the style to `FontManager.swift`
2. Add a convenience extension to `UIFont`
3. Update this documentation
4. Test across all screen sizes and accessibility settings 