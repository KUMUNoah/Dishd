import SwiftUI

/// Custom tab container. Not a TabView: safeAreaInset on TabView doesn't
/// reach the UIKit-managed pages, so content slid under the custom bar.
/// Here the bar takes real layout space and pages can never underlap it.
/// All four tabs stay mounted (opacity-swapped) so their state survives
/// switching, same as TabView.
struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var tab: DishdTab = .feed

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                FeedView()
                    .opacity(tab == .feed ? 1 : 0)
                    .allowsHitTesting(tab == .feed)
                CollectionView()
                    .opacity(tab == .recipes ? 1 : 0)
                    .allowsHitTesting(tab == .recipes)
                SearchView()
                    .opacity(tab == .search ? 1 : 0)
                    .allowsHitTesting(tab == .search)
                ownProfile
                    .opacity(tab == .profile ? 1 : 0)
                    .allowsHitTesting(tab == .profile)
            }
            DishdTabBar(selection: $tab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)   // bar stays put under the keyboard
        .background(DishdColor.screen.ignoresSafeArea())
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
