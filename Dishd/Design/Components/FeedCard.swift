import SwiftUI

/// THE component — a friend's review in the feed.
struct FeedCard: View {
    let item: FeedItem
    let currentUserId: UUID?
    var onSave: () -> Void
    var onOpenRecipe: () -> Void
    var onOpenAuthor: () -> Void
    var onModerated: () -> Void

    @State private var liked: Bool
    @State private var likeCount: Int
    @State private var reported = false
    @State private var showModeration = false
    @State private var reportThanks = false

    init(item: FeedItem, currentUserId: UUID?,
         onSave: @escaping () -> Void, onOpenRecipe: @escaping () -> Void,
         onOpenAuthor: @escaping () -> Void = {},
         onModerated: @escaping () -> Void = {}) {
        self.item = item
        self.currentUserId = currentUserId
        self.onSave = onSave
        self.onOpenRecipe = onOpenRecipe
        self.onOpenAuthor = onOpenAuthor
        self.onModerated = onModerated
        _liked = State(initialValue: item.likes.contains { $0.userId == currentUserId })
        _likeCount = State(initialValue: item.likes.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            slideshow
            footer
        }
        .background(DishdColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(DishdColor.border, lineWidth: 1))
    }

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(DishdColor.honey)
                Text(String(item.author.username.prefix(1)).uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DishdColor.espresso)
            }
            .frame(width: 30, height: 30)

            Text(item.author.username)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DishdColor.espresso)

            Text(item.createdAt.formatted(.relative(presentation: .named)))
                .font(.system(size: 12))
                .foregroundStyle(DishdColor.taupe)

            Spacer()

            if item.userId != currentUserId {
                Button {
                    showModeration = true
                } label: {
                    Icon(Lucide.ellipsis, size: 15)
                        .foregroundStyle(DishdColor.taupe)
                        .padding(6)
                }
            }
        }
        .padding(12)
        .contentShape(Rectangle())
        .onTapGesture { onOpenAuthor() }
        .sheet(isPresented: $showModeration) {
            ModerationSheet(username: item.author.username,
                            reviewId: item.id,
                            userId: item.userId,
                            onBlocked: onModerated,
                            onReported: { reported = true; reportThanks = true })
        }
        .alert("Thanks — we'll take a look.", isPresented: $reportThanks) {
            Button("OK") {}
        }
    }

    private var slideshow: some View {
        TabView {
            // Slide 1 is ALWAYS the user's real photo — the honest one.
            slideImage(item.photoUrl)

            if let thumb = item.recipe.thumbnailUrl {
                slideImage(thumb)
            } else if item.recipe.sourceUrl != nil {
                // Link exists but no thumbnail: designed placeholder.
                VStack(spacing: 6) {
                    Icon(Lucide.playCircle, size: 30)
                        .foregroundStyle(DishdColor.taupe)
                    Text("View original")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DishdColor.taupe)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DishdColor.sand)
            }
            // No link at all (quick post): single photo, no second slide.
        }
        .tabViewStyle(.page(indexDisplayMode: item.recipe.sourceUrl == nil ? .never : .automatic))
        .frame(height: 260)
    }

    private func slideImage(_ urlString: String) -> some View {
        AsyncImage(url: URL(string: urlString)) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            ZStack { DishdColor.sand; ProgressView() }
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            StarRatingDisplay(rating: item.rating)

            if let notes = item.notes {
                Text(notes)
                    .font(.system(size: 14))
                    .foregroundStyle(DishdColor.espresso)
                    .lineLimit(3)
            }

            Button(action: onOpenRecipe) {
                HStack(spacing: 4) {
                    Text(item.recipe.title)
                        .font(.system(size: 14, weight: .semibold))
                    Icon(Lucide.chevronRight, size: 11)
                }
                .foregroundStyle(DishdColor.terracotta)
            }

            HStack(spacing: 16) {
                if item.userId != currentUserId {
                    Button(action: onSave) {
                        Text("Save")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 7)
                            .background(DishdColor.terracotta)
                            .clipShape(Capsule())
                    }
                }

                Button {
                    Task { await toggleLike() }
                } label: {
                    HStack(spacing: 4) {
                        Icon(liked ? Lucide.heartFill : Lucide.heart, size: 18)
                        if likeCount > 0 {
                            Text("\(likeCount)").font(.system(size: 13))
                        }
                    }
                    .foregroundStyle(DishdColor.tomato)
                }

                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(12)
    }

    private func toggleLike() async {
        if liked {
            liked = false; likeCount -= 1
            try? await FeedService.unlike(reviewId: item.id)
        } else {
            liked = true; likeCount += 1
            try? await FeedService.like(reviewId: item.id)
        }
    }
}
