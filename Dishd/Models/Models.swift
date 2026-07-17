import Foundation

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    var username: String
    var fullName: String?
    var bio: String?
    var avatarUrl: String?
    var isPrivate: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, username, bio
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case isPrivate = "is_private"
        case createdAt = "created_at"
    }
}

struct Recipe: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var sourceUrl: String?
    var thumbnailUrl: String?
    var platform: String?
    let createdBy: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, platform
        case sourceUrl = "source_url"
        case thumbnailUrl = "thumbnail_url"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

struct Save: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let recipeId: UUID
    var status: String            // "want_to_make" | "made"
    var folderId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status
        case userId = "user_id"
        case recipeId = "recipe_id"
        case folderId = "folder_id"
        case createdAt = "created_at"
    }
}

struct Review: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let recipeId: UUID
    var rating: Int
    var notes: String?
    var photoUrl: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, rating, notes
        case userId = "user_id"
        case recipeId = "recipe_id"
        case photoUrl = "photo_url"
        case createdAt = "created_at"
    }
}

struct Goals: Codable, Hashable {
    var cookPerWeek: Int
    var newRecipesPerYear: Int

    enum CodingKeys: String, CodingKey {
        case cookPerWeek = "cook_per_week"
        case newRecipesPerYear = "new_recipes_per_year"
    }
}
