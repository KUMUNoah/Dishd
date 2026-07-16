import SwiftUI

enum DishdFont {
    /// Wordmark + onboarding hero lines ONLY. Falls back to a serif design
    /// until YoungSerif-Regular.ttf is added to the bundle.
    static func wordmark(_ size: CGFloat) -> Font {
        if UIFont(name: "YoungSerif-Regular", size: size) != nil {
            return .custom("YoungSerif-Regular", size: size)
        }
        return .system(size: size, weight: .bold, design: .serif)
    }
}

/// The lowercase terracotta wordmark, used in the feed header and auth screens.
struct Wordmark: View {
    var size: CGFloat = 28

    var body: some View {
        Text("dishd")
            .font(DishdFont.wordmark(size))
            .foregroundStyle(DishdColor.terracotta)
    }
}
