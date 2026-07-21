import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var tab: DishdTab = .feed

    var body: some View {
        TabView(selection: $tab) {
            FeedView()
                .toolbar(.hidden, for: .tabBar)
                .tag(DishdTab.feed)

            CollectionView()
                .toolbar(.hidden, for: .tabBar)
                .tag(DishdTab.recipes)

            SearchView()
                .toolbar(.hidden, for: .tabBar)
                .tag(DishdTab.search)

            ownProfile
                .toolbar(.hidden, for: .tabBar)
                .tag(DishdTab.profile)
        }
        // System tab bar is hidden above; DishdTabBar replaces it because
        // iOS 26 renders the stock bar as a floating glass pill.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DishdTabBar(selection: $tab)
        }
        .tint(DishdColor.terracotta)
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
