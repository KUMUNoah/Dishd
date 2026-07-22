import SwiftUI

enum DishdTab: Hashable, CaseIterable {
    case feed, recipes, search, profile

    var icon: String {
        switch self {
        case .feed: Lucide.house
        case .recipes: Lucide.book
        case .search: Lucide.search
        case .profile: Lucide.user
        }
    }

    var label: String {
        switch self {
        case .feed: "Feed"
        case .recipes: "Recipes"
        case .search: "Search"
        case .profile: "Profile"
        }
    }
}

/// Flat white bar with a warm hairline — replaces the system tab bar, which
/// on iOS 26 renders as a floating glass pill that ignores our palette.
struct DishdTabBar: View {
    @Binding var selection: DishdTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DishdTab.allCases, id: \.self) { tab in
                let selected = selection == tab
                // Lucide is stroke-only, so colour alone marks the active tab.
                Icon(tab.icon, size: 23)
                    .foregroundStyle(selected ? DishdColor.terracotta : DishdColor.iconMuted)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { selection = tab }
                    .accessibilityLabel(tab.label)
                    .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
        .padding(.horizontal, 20)
        .background(alignment: .top) {
            ZStack(alignment: .top) {
                DishdColor.screen
                Rectangle()
                    .fill(DishdColor.hairline)
                    .frame(height: 1)
            }
        }
    }
}
