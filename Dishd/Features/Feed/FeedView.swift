import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var appState: AppState
    @State private var items: [FeedItem] = []
    @State private var isLoading = true
    @State private var toast: String?
    @State private var openRecipe: Recipe?
    @State private var openProfile: Profile?
    @State private var unreadCount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView().padding(.top, 80)
                } else if items.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(items) { item in
                            FeedCard(item: item,
                                     currentUserId: appState.profile?.id,
                                     onSave: { Task { await save(item) } },
                                     onOpenRecipe: { openRecipe = item.recipe },
                                     onOpenAuthor: {
                                         Task {
                                             openProfile = try? await SocialService.profile(id: item.userId)
                                         }
                                     },
                                     onModerated: { Task { await load() } })
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 20)
                }
            }
            .refreshable { await load() }
            .background(DishdColor.screen.ignoresSafeArea())
            .toolbarBackground(DishdColor.screen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Wordmark(size: 24).fixedSize() }
                    .plainToolbarItem()
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        NotificationsView()
                            .onDisappear { unreadCount = 0 }
                    } label: {
                        // 2c: bare glyph, heavier weight, quiet tomato dot.
                        Image(systemName: "bell")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(DishdColor.espresso)
                            .overlay(alignment: .topTrailing) {
                                if unreadCount > 0 {
                                    Circle()
                                        .fill(DishdColor.tomato)
                                        .stroke(DishdColor.screen, lineWidth: 1.5)
                                        .frame(width: 9, height: 9)
                                        .offset(x: 2, y: -1)
                                }
                            }
                    }
                }
                .plainToolbarItem()
            }
            .navigationDestination(item: $openRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .navigationDestination(item: $openProfile) { profile in
                ProfileView(profile: profile)
            }
            .overlay(alignment: .bottom) {
                if let toast {
                    Text(toast)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(DishdColor.espresso.opacity(0.92))
                        .clipShape(Capsule())
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .task { await load() }
        }
        .tint(DishdColor.terracotta)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife")
                .font(.system(size: 32))
                .foregroundStyle(DishdColor.taupe)
            Text("Nothing cooking yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DishdColor.espresso)
            Text("Follow friends to see what they're making — or cook something from your list and post the first review.")
                .font(.system(size: 14))
                .foregroundStyle(DishdColor.taupe)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 44)
        }
        .padding(.top, 80)
    }

    private func save(_ item: FeedItem) async {
        do {
            try await RecipeService.save(title: item.recipe.title,
                                         sourceUrl: item.recipe.sourceUrl)
            withAnimation { toast = "Saved to Want to make" }
            try? await Task.sleep(for: .seconds(2))
            withAnimation { toast = nil }
        } catch {
            print("Feed save failed: \(error)")
        }
    }

    private func load() async {
        do {
            items = try await FeedService.feed()
        } catch {
            print("Feed load failed: \(error)")
        }
        unreadCount = await SocialService.unreadNotificationCount()
        isLoading = false
    }
}
