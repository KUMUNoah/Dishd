import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        // Warm hairline instead of the stock gray separator.
        appearance.shadowColor = UIColor(red: 0.945, green: 0.918, blue: 0.878, alpha: 1)

        let muted = UIColor(red: 0.718, green: 0.627, blue: 0.549, alpha: 1)  // #B7A08C
        for item in [appearance.stackedLayoutAppearance,
                     appearance.inlineLayoutAppearance,
                     appearance.compactInlineLayoutAppearance] {
            item.normal.iconColor = muted
            item.normal.titleTextAttributes = [.foregroundColor: muted]
        }
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("Feed", systemImage: "house") }

            CollectionView()
                .tabItem { Label("Recipes", systemImage: "book") }

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            ownProfile
                .tabItem { Label("Profile", systemImage: "person") }
        }
        .tint(DishdColor.terracotta)
    }

    private func placeholder(_ title: String, note: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(DishdColor.espresso)
            Text(note)
                .font(.system(size: 14))
                .foregroundStyle(DishdColor.taupe)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DishdColor.screen)
    }

    private var ownProfile: some View {
        NavigationStack {
            if let profile = appState.profile {
                ProfileView(profile: profile, isOwn: true)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DishdColor.screen)
            }
        }
        .tint(DishdColor.terracotta)
    }
}
