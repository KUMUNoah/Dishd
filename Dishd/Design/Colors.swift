import SwiftUI

/// v2 redesign — the inversion: screens are white, cream carries cards and
/// soft chips, terracotta stays the accent.
enum DishdColor {
    /// Screen backgrounds.
    static let screen = Color.white
    /// Card + soft-chip surfaces sitting on white.
    static let card = Color(red: 0.980, green: 0.953, blue: 0.922)       // #FAF3EB
    /// Hairline borders on cards, chips, and fields.
    static let border = Color(red: 0.937, green: 0.894, blue: 0.827)     // #EFE4D3
    /// Primary accent: buttons, active tab, stars, links.
    static let terracotta = Color(red: 0.784, green: 0.333, blue: 0.173) // #C8552C
    /// Primary text.
    static let espresso = Color(red: 0.231, green: 0.180, blue: 0.145)   // #3B2E25
    /// Avatar fallbacks, secondary warmth.
    static let honey = Color(red: 0.910, green: 0.690, blue: 0.294)      // #E8B04B
    /// Likes, notification dots, destructive text.
    static let tomato = Color(red: 0.839, green: 0.271, blue: 0.239)     // #D6453D
    /// Secondary text, timestamps, section labels.
    static let taupe = Color(red: 0.627, green: 0.549, blue: 0.471)      // #A08C78
    /// Image placeholders.
    static let sand = Color(red: 0.914, green: 0.863, blue: 0.796)       // #E9DCCB
    /// Deeper placeholder stripe, progress-track fill.
    static let sandDeep = Color(red: 0.890, green: 0.831, blue: 0.753)   // #E3D4C0
    /// Inactive tab-bar glyphs.
    static let iconMuted = Color(red: 0.718, green: 0.627, blue: 0.549)  // #B7A08C
    /// Disclosure chevrons.
    static let chevron = Color(red: 0.769, green: 0.706, blue: 0.627)    // #C4B4A0
    /// Tab bar hairline — lighter than card borders.
    static let hairline = Color(red: 0.945, green: 0.918, blue: 0.878)   // #F1EAE0
    /// Sheet grabber.
    static let grabber = Color(red: 0.898, green: 0.835, blue: 0.761)    // #E5D5C2
    /// Destructive surfaces: tinted fill + border.
    static let dangerTint = Color(red: 0.984, green: 0.941, blue: 0.933) // #FBF0EE
    static let dangerBorder = Color(red: 0.941, green: 0.831, blue: 0.812) // #F0D4CF
}
