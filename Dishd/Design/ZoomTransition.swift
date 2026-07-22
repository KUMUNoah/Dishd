import SwiftUI

/// Zoom presentation: the presented screen expands out of the button that
/// opened it (Settings from the gear, the save sheet from +, report/block
/// from the ellipsis). Native on iOS 18+; standard presentation on iOS 17.
extension View {
    /// Marks the tapped control as the visual origin of the zoom.
    @ViewBuilder
    func zoomSource(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// Applied to the presented screen; pairs with `zoomSource`.
    @ViewBuilder
    func zoomsFrom(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
