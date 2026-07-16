import Foundation
import Supabase

struct ReviewWithAuthor: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let rating: Int
    let notes: String?
    let photoUrl: String
    let createdAt: Date
    let author: AuthorProfile

    struct AuthorProfile: Codable, Hashable {
        let username: String
        let avatarUrl: String?

        enum CodingKeys: String, CodingKey {
            case username
            case avatarUrl = "avatar_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, rating, notes
        case userId = "user_id"
        case photoUrl = "photo_url"
        case createdAt = "created_at"
        case author = "profiles"
    }
}

enum ReviewService {

    /// RLS applies the privacy rule server-side: this only ever returns
    /// reviews the current user is allowed to see.
    static func reviews(for recipeId: UUID) async throws -> [ReviewWithAuthor] {
        try await supabase.from("reviews")
            .select("id, user_id, rating, notes, photo_url, created_at, profiles!reviews_user_id_fkey(username, avatar_url)")
            .eq("recipe_id", value: recipeId)
            .order("created_at", ascending: false)
            .execute().value
    }

    /// Uploads the photo, then inserts the review. The on_review_created
    /// trigger moves the save to Made server-side.
    static func post(recipeId: UUID, rating: Int, notes: String, photoData: Data) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw URLError(.userAuthenticationRequired)
        }

        let path = "\(userId.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
        try await supabase.storage.from("review-photos")
            .upload(path, data: photoData, options: FileOptions(contentType: "image/jpeg"))
        let photoUrl = try supabase.storage.from("review-photos").getPublicURL(path: path)

        struct NewReview: Encodable {
            let user_id: UUID
            let recipe_id: UUID
            let rating: Int
            let notes: String?
            let photo_url: String
        }
        try await supabase.from("reviews")
            .insert(NewReview(user_id: userId,
                              recipe_id: recipeId,
                              rating: rating,
                              notes: notes.isEmpty ? nil : notes,
                              photo_url: photoUrl.absoluteString))
            .execute()
    }
}
