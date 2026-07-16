import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
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
        .background(DishdColor.cream)
    }

    private var ownProfile: some View {
        NavigationStack {
            if let profile = appState.profile {
                ProfileView(profile: profile, isOwn: true)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DishdColor.cream)
            }
        }
        .tint(DishdColor.terracotta)
    }
}
