import SwiftUI

extension ToolbarContent {
    /// iOS 26 wraps every toolbar item in a Liquid Glass capsule, which puts
    /// our bare glyphs back in circles and clips the wordmark. Opt out where
    /// available; on iOS 17–18 there's no capsule to remove.
    @ToolbarContentBuilder
    func plainToolbarItem() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            self.sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
