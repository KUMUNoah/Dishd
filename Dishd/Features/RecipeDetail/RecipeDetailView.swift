import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    /// The current user's save status for this recipe, if any.
    var saveStatus: String?
    var onChanged: () -> Void = {}

    @EnvironmentObject private var appState: AppState
    @State private var reviews: [ReviewWithAuthor] = []
    @State private var showComposer = false

    private var myReview: ReviewWithAuthor? {
        reviews.first { $0.userId == appState.profile?.id }
    }

    private var averageRating: Double? {
        guard !reviews.isEmpty else { return nil }
        return Double(reviews.map(\.rating).reduce(0, +)) / Double(reviews.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                thumbnail

                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(DishdColor.espresso)
                    if let platform = recipe.platform {
                        Text(platform.capitalized)
                            .font(.system(size: 13))
                            .foregroundStyle(DishdColor.taupe)
                    }
                }

                if let urlString = recipe.sourceUrl, let url = URL(string: urlString) {
                    Link(destination: url) {
                        Label("Watch original", systemImage: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DishdColor.terracotta)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(DishdColor.card)
                            .overlay(Capsule().stroke(DishdColor.border, lineWidth: 0.5))
                            .clipShape(Capsule())
                    }
                }

                if let averageRating {
                    HStack(spacing: 8) {
                        StarRatingDisplay(rating: Int(averageRating.rounded()))
                        Text(String(format: "%.1f from friends · %d review%@",
                                    averageRating, reviews.count, reviews.count == 1 ? "" : "s"))
                            .font(.system(size: 13))
                            .foregroundStyle(DishdColor.taupe)
                    }
                }

                ForEach(reviews) { review in
                    reviewCard(review)
                }

                if reviews.isEmpty {
                    Text("No reviews yet — be the first to make it.")
                        .font(.system(size: 14))
                        .foregroundStyle(DishdColor.taupe)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }

                if myReview == nil {
                    PrimaryButton(title: "Write a review") {
                        showComposer = true
                    }
                    .padding(.top, 8)
                }
            }
            .padding(20)
        }
        .background(DishdColor.cream.ignoresSafeArea())
        .toolbarBackground(DishdColor.cream, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showComposer) {
            ReviewComposerView(recipe: recipe) {
                Task {
                    await loadReviews()
                    onChanged()
                }
            }
        }
        .task { await loadReviews() }
    }

    @ViewBuilder
    private var thumbnail: some View {
        Group {
            if let urlString = recipe.thumbnailUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ZStack { DishdColor.sand; ProgressView() }
                }
            } else {
                ZStack {
                    DishdColor.sand
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                        .foregroundStyle(DishdColor.taupe)
                }
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func reviewCard(_ review: ReviewWithAuthor) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(DishdColor.honey)
                    Text(String(review.author.username.prefix(1)).uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DishdColor.espresso)
                }
                .frame(width: 28, height: 28)

                Text(review.author.username)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DishdColor.espresso)

                Spacer()
                StarRatingDisplay(rating: review.rating, size: 12)
            }

            AsyncImage(url: URL(string: review.photoUrl)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                DishdColor.sand
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let notes = review.notes {
                Text(notes)
                    .font(.system(size: 14))
                    .foregroundStyle(DishdColor.espresso)
            }
        }
        .padding(14)
        .background(DishdColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DishdColor.border, lineWidth: 0.5))
    }

    private func loadReviews() async {
        do {
            reviews = try await ReviewService.reviews(for: recipe.id)
        } catch {
            print("Reviews load failed: \(error)")
        }
    }
}
