import SwiftUI

/// Left-aligned page header: optional dismiss glyph, title, optional trailing
/// control. Rendered as page content rather than a nav bar — iOS 26 clips wide
/// leading toolbar items (it ate the title) and the bar left a white strip
/// content scrolled under.
struct PageHeader<Trailing: View>: View {
    let title: String
    var icon: String?
    var action: () -> Void
    @ViewBuilder var trailing: Trailing

    init(title: String,
         icon: String? = nil,
         action: @escaping () -> Void = {},
         @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.icon = icon
        self.action = action
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Button(action: action) {
                    Icon(icon, size: 34)
                        .foregroundStyle(DishdColor.espresso)
                }
            }
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(DishdColor.espresso)
            Spacer(minLength: 0)
            trailing
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(DishdColor.screen)
    }
}

extension PageHeader where Trailing == EmptyView {
    init(title: String, icon: String? = nil, action: @escaping () -> Void = {}) {
        self.init(title: title, icon: icon, action: action, trailing: { EmptyView() })
    }
}
