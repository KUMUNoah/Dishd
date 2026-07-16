import Foundation
import Supabase

enum FollowState: String {
    case notFollowing, pending, following
}

struct ProfileStats {
    var made: Int
    var followers: Int
    var following: Int
}

struct AppNotification: Codable, Identifiable, Hashable {
    let id: UUID
    let type: String
    let read: Bool
    let createdAt: Date
    let actor: ReviewWithAuthor.AuthorProfile
    let actorId: UUID

    enum CodingKeys: String, CodingKey {
        case id, type, read
        case createdAt = "created_at"
        case actor = "profiles"
        case actorId = "actor_id"
    }
}

struct ProfileReview: Codable, Identifiable, Hashable {
    let id: UUID
    let rating: Int
    let notes: String?
    let photoUrl: String
    let createdAt: Date
    let recipe: Recipe

    enum CodingKeys: String, CodingKey {
        case id, rating, notes
        case photoUrl = "photo_url"
        case createdAt = "created_at"
        case recipe = "recipes"
    }
}

enum SocialService {

    // MARK: - Search

    static func searchUsers(_ query: String) async throws -> [Profile] {
        guard !query.isEmpty else { return [] }
        return try await supabase.from("profiles")
            .select()
            .ilike("username", pattern: "%\(query.lowercased())%")
            .limit(20)
            .execute().value
    }

    static func profile(id: UUID) async throws -> Profile {
        try await supabase.from("profiles")
            .select()
            .eq("id", value: id)
            .single()
            .execute().value
    }

    // MARK: - Follows

    static func follow(_ userId: UUID) async throws {
        guard let me = supabase.auth.currentUser?.id else { return }
        struct NewFollow: Encodable { let follower_id: UUID; let following_id: UUID }
        do {
            try await supabase.from("follows")
                .insert(NewFollow(follower_id: me, following_id: userId))
                .execute()
        } catch {
            if !"\(error)".contains("23505") { throw error }
        }
    }

    static func unfollow(_ userId: UUID) async throws {
        guard let me = supabase.auth.currentUser?.id else { return }
        try await supabase.from("follows").delete()
            .eq("follower_id", value: me)
            .eq("following_id", value: userId)
            .execute()
    }

    static func followState(of userId: UUID) async -> FollowState {
        guard let me = supabase.auth.currentUser?.id else { return .notFollowing }
        struct Row: Codable { let status: String }
        let rows: [Row] = (try? await supabase.from("follows")
            .select("status")
            .eq("follower_id", value: me)
            .eq("following_id", value: userId)
            .execute().value) ?? []
        switch rows.first?.status {
        case "accepted": return .following
        case "pending": return .pending
        default: return .notFollowing
        }
    }

    static func acceptRequest(from actorId: UUID) async throws {
        guard let me = supabase.auth.currentUser?.id else { return }
        try await supabase.from("follows")
            .update(["status": "accepted"])
            .eq("follower_id", value: actorId)
            .eq("following_id", value: me)
            .execute()
    }

    static func declineRequest(from actorId: UUID) async throws {
        guard let me = supabase.auth.currentUser?.id else { return }
        try await supabase.from("follows").delete()
            .eq("follower_id", value: actorId)
            .eq("following_id", value: me)
            .execute()
    }

    // MARK: - Profile data

    static func stats(for userId: UUID) async -> ProfileStats {
        async let made = count("saves", filters: [("user_id", userId.uuidString), ("status", "made")])
        async let followers = count("follows", filters: [("following_id", userId.uuidString), ("status", "accepted")])
        async let following = count("follows", filters: [("follower_id", userId.uuidString), ("status", "accepted")])
        return await ProfileStats(made: made, followers: followers, following: following)
    }

    private static func count(_ table: String, filters: [(String, String)]) async -> Int {
        var query = supabase.from(table).select("*", head: true, count: .exact)
        for (column, value) in filters { query = query.eq(column, value: value) }
        return (try? await query.execute().count) ?? 0
    }

    static func reviews(of userId: UUID) async throws -> [ProfileReview] {
        try await supabase.from("reviews")
            .select("id, rating, notes, photo_url, created_at, recipes(*)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute().value
    }

    static func saves(of userId: UUID) async throws -> [SavedRecipe] {
        try await supabase.from("saves")
            .select("id, status, created_at, recipes(*)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute().value
    }

    static func setPrivate(_ isPrivate: Bool) async throws {
        guard let me = supabase.auth.currentUser?.id else { return }
        try await supabase.from("profiles")
            .update(["is_private": isPrivate])
            .eq("id", value: me)
            .execute()
    }

    // MARK: - Safety (Apple UGC requirements)

    static func block(_ userId: UUID) async throws {
        guard let me = supabase.auth.currentUser?.id else { return }
        struct NewBlock: Encodable { let blocker_id: UUID; let blocked_id: UUID }
        do {
            try await supabase.from("blocks")
                .insert(NewBlock(blocker_id: me, blocked_id: userId))
                .execute()
        } catch {
            if !"\(error)".contains("23505") { throw error }
        }
        // Blocking severs the relationship both ways.
        try? await unfollow(userId)
        try? await declineRequest(from: userId)
    }

    static func unblock(_ userId: UUID) async throws {
        guard let me = supabase.auth.currentUser?.id else { return }
        try await supabase.from("blocks").delete()
            .eq("blocker_id", value: me)
            .eq("blocked_id", value: userId)
            .execute()
    }

    static func isBlocked(_ userId: UUID) async -> Bool {
        guard let me = supabase.auth.currentUser?.id else { return false }
        let count = (try? await supabase.from("blocks")
            .select("*", head: true, count: .exact)
            .eq("blocker_id", value: me)
            .eq("blocked_id", value: userId)
            .execute().count) ?? 0
        return count > 0
    }

    static func blockedUsers() async throws -> [Profile] {
        guard let me = supabase.auth.currentUser?.id else { return [] }
        struct Row: Codable { let profiles: Profile }
        let rows: [Row] = try await supabase.from("blocks")
            .select("profiles!blocks_blocked_id_fkey(*)")
            .eq("blocker_id", value: me)
            .execute().value
        return rows.map(\.profiles)
    }

    static func report(reviewId: UUID? = nil, userId: UUID? = nil, reason: String) async throws {
        guard let me = supabase.auth.currentUser?.id else { return }
        struct NewReport: Encodable {
            let reporter_id: UUID
            let review_id: UUID?
            let reported_user_id: UUID?
            let reason: String
        }
        try await supabase.from("reports")
            .insert(NewReport(reporter_id: me, review_id: reviewId,
                              reported_user_id: userId, reason: reason))
            .execute()
    }

    /// Server-side RPC deletes the auth user; cascades wipe all app data.
    static func deleteAccount() async throws {
        try await supabase.rpc("delete_user").execute()
        try? await supabase.auth.signOut()
    }

    // MARK: - Follower lists

    static func followers(of userId: UUID) async throws -> [Profile] {
        struct Row: Codable { let profiles: Profile }
        let rows: [Row] = try await supabase.from("follows")
            .select("profiles!follows_follower_id_fkey(*)")
            .eq("following_id", value: userId)
            .eq("status", value: "accepted")
            .execute().value
        return rows.map(\.profiles)
    }

    static func following(of userId: UUID) async throws -> [Profile] {
        struct Row: Codable { let profiles: Profile }
        let rows: [Row] = try await supabase.from("follows")
            .select("profiles!follows_following_id_fkey(*)")
            .eq("follower_id", value: userId)
            .eq("status", value: "accepted")
            .execute().value
        return rows.map(\.profiles)
    }

    // MARK: - Notifications

    static func unreadNotificationCount() async -> Int {
        guard let me = supabase.auth.currentUser?.id else { return 0 }
        return (try? await supabase.from("notifications")
            .select("*", head: true, count: .exact)
            .eq("user_id", value: me)
            .eq("read", value: false)
            .execute().count) ?? 0
    }

    static func deleteNotification(id: UUID) async {
        _ = try? await supabase.from("notifications").delete()
            .eq("id", value: id)
            .execute()
    }

    static func notifications() async throws -> [AppNotification] {
        guard let me = supabase.auth.currentUser?.id else { return [] }
        return try await supabase.from("notifications")
            .select("id, type, read, created_at, actor_id, profiles!notifications_actor_id_fkey(username, avatar_url)")
            .eq("user_id", value: me)
            .order("created_at", ascending: false)
            .limit(50)
            .execute().value
    }

    static func markAllRead() async {
        guard let me = supabase.auth.currentUser?.id else { return }
        _ = try? await supabase.from("notifications")
            .update(["read": true])
            .eq("user_id", value: me)
            .execute()
    }
}
