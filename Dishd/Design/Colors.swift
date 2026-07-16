import SwiftUI

enum DishdColor {
    /// Screen backgrounds — never pure white.
    static let cream = Color(red: 0.980, green: 0.953, blue: 0.922)      // #FAF3EB
    /// Primary accent: buttons, active tab, stars, links.
    static let terracotta = Color(red: 0.784, green: 0.333, blue: 0.173) // #C8552C
    /// Primary text.
    static let espresso = Color(red: 0.231, green: 0.180, blue: 0.145)   // #3B2E25
    /// Avatar fallbacks, secondary warmth.
    static let honey = Color(red: 0.910, green: 0.690, blue: 0.294)      // #E8B04B
    /// Likes + notification badges ONLY.
    static let tomato = Color(red: 0.839, green: 0.271, blue: 0.239)     // #D6453D
    /// Secondary text, timestamps.
    static let taupe = Color(red: 0.627, green: 0.549, blue: 0.471)      // #A08C78
    /// Image placeholders.
    static let sand = Color(red: 0.914, green: 0.863, blue: 0.796)       // #E9DCCB
    /// Card surfaces sit on cream.
    static let card = Color.white
    /// Hairline borders on cards and fields.
    static let border = Color(red: 0.898, green: 0.835, blue: 0.761)     // #E5D5C2
}
