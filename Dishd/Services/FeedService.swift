import Foundation
import Supabase

struct FeedItem: Codable, Identifiable, Hashable {
    let id: UUID              // review id
    let userId: UUID
    let rating: Int
    let notes: String?
    let photoUrl: String
    let createdAt: Date
    let author: ReviewWithAuthor.AuthorProfile
    let recipe: Recipe
    let likes: [LikeRef]

    struct LikeRef: Codable, Hashable {
        let userId: UUID
        enum CodingKeys: String, CodingKey { case userId = "user_id" }
    }

    enum CodingKeys: String, CodingKey {
        case id, rating, notes, likes
        case userId = "user_id"
        case photoUrl = "photo_url"
        case createdAt = "created_at"
        case author = "profiles"
        case recipe = "recipes"
    }
}

enum FeedService {

    /// Reviews from accepted-followed users + self, newest first.
    /// RLS enforces visibility; this filter decides feed membership.
    static func feed() async throws -> [FeedItem] {
        guard let userId = supabase.auth.currentUser?.id else { return [] }

        struct FollowRef: Codable { let following_id: UUID }
        let following: [FollowRef] = try await supabase.from("follows")
            .select("following_id")
            .eq("follower_id", value: userId)
            .eq("status", value: "accepted")
            .execute().value

        var feedUserIds = following.map(\.following_id.uuidString)
        feedUserIds.append(userId.uuidString)

        return try await supabase.from("reviews")
            .select("""
                id, user_id, rating, notes, photo_url, created_at, \
                profiles!reviews_user_id_fkey(username, avatar_url), \
                recipes(*), likes(user_id)
                """)
            .in("user_id", values: feedUserIds)
            .order("created_at", ascending: false)
            .limit(50)
            .execute().value
    }

    static func like(reviewId: UUID) async throws {
        guard let userId = supabase.auth.currentUser?.id else { return }
        struct NewLike: Encodable { let user_id: UUID; let review_id: UUID }
        do {
            try await supabase.from("likes")
                .insert(NewLike(user_id: userId, review_id: reviewId))
                .execute()
        } catch {
            if !"\(error)".contains("23505") { throw error }
        }
    }

    static func unlike(reviewId: UUID) async throws {
        guard let userId = supabase.auth.currentUser?.id else { return }
        try await supabase.from("likes").delete()
            .eq("user_id", value: userId)
            .eq("review_id", value: reviewId)
            .execute()
    }
}
