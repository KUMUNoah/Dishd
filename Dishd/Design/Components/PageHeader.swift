import SwiftUI

/// Left-aligned page header: dismiss glyph then title, as the mockups draw
/// it. Rendered as page content rather than a nav bar — iOS 26 clips wide
/// leading toolbar items (it ate the title) and the bar left a white strip
/// content scrolled under.
struct PageHeader: View {
    let title: String
    let icon: String
    var action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: action) {
                Icon(icon, size: 34)
                    .foregroundStyle(DishdColor.espresso)
            }
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(DishdColor.espresso)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(DishdColor.screen)
    }
}
