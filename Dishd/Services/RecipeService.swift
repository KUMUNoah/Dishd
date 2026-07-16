import Foundation
import Supabase

struct SavedRecipe: Codable, Identifiable, Hashable {
    let id: UUID          // save id
    let status: String
    let createdAt: Date
    let recipe: Recipe

    enum CodingKeys: String, CodingKey {
        case id, status
        case createdAt = "created_at"
        case recipe = "recipes"
    }
}

enum RecipeService {

    // MARK: - Saving

    /// Canonical lookup-or-create by source_url, then save for the current user.
    /// Returns the recipe so callers (quick post) can continue to the composer.
    @discardableResult
    static func save(title: String, sourceUrl: String?, status: String = "want_to_make") async throws -> Recipe {
        guard let userId = supabase.auth.currentUser?.id else {
            throw URLError(.userAuthenticationRequired)
        }

        let recipe = try await findOrCreateRecipe(title: title, sourceUrl: sourceUrl, userId: userId)

        struct NewSave: Encodable {
            let user_id: UUID
            let recipe_id: UUID
            let status: String
        }
        // Ignore duplicate-save errors: saving twice is a no-op, not a failure.
        do {
            try await supabase.from("saves")
                .insert(NewSave(user_id: userId, recipe_id: recipe.id, status: status))
                .execute()
        } catch {
            if !"\(error)".contains("23505") { throw error }
        }
        return recipe
    }

    private static func findOrCreateRecipe(title: String, sourceUrl: String?, userId: UUID) async throws -> Recipe {
        if let sourceUrl, !sourceUrl.isEmpty {
            let existing: [Recipe] = try await supabase.from("recipes")
                .select().eq("source_url", value: sourceUrl).execute().value
            if let found = existing.first { return found }
        }

        var metadata: Metadata?
        if let sourceUrl, !sourceUrl.isEmpty {
            metadata = await fetchMetadata(for: sourceUrl)
        }

        struct NewRecipe: Encodable {
            let title: String
            let source_url: String?
            let thumbnail_url: String?
            let platform: String?
            let created_by: UUID
        }
        let inserted: Recipe = try await supabase.from("recipes")
            .insert(NewRecipe(title: title,
                              source_url: (sourceUrl?.isEmpty == false) ? sourceUrl : nil,
                              thumbnail_url: metadata?.thumbnailUrl,
                              platform: sourceUrl.flatMap(detectPlatform),
                              created_by: userId))
            .select().single().execute().value
        return inserted
    }

    // MARK: - Fetching

    static func mySaves(status: String) async throws -> [SavedRecipe] {
        guard let userId = supabase.auth.currentUser?.id else { return [] }
        return try await supabase.from("saves")
            .select("id, status, created_at, recipes(*)")
            .eq("user_id", value: userId)
            .eq("status", value: status)
            .order("created_at", ascending: false)
            .execute().value
    }

    static func deleteSave(id: UUID) async throws {
        try await supabase.from("saves").delete().eq("id", value: id).execute()
    }

    // MARK: - Starter recipes (onboarding)

    struct StarterRecipe: Codable, Identifiable, Hashable {
        let recipe: Recipe
        let timeBracket: String

        var id: UUID { recipe.id }
        var timeLabel: String {
            switch timeBracket {
            case "under_20": "under 20 min"
            case "20_to_45": "20–45 min"
            default: "45+ min"
            }
        }

        enum CodingKeys: String, CodingKey {
            case recipe = "recipes"
            case timeBracket = "time_bracket"
        }
    }

    /// Curated picks filtered by cuisine; cook time is shown per card.
    /// The user's answer is never stored — it filters once and is discarded.
    static func starters(cuisines: [String]) async throws -> [StarterRecipe] {
        var query = supabase.from("starter_recipes").select("time_bracket, recipes(*)")
        if !cuisines.isEmpty {
            query = query.overlaps("cuisines", value: cuisines)
        }
        var rows: [StarterRecipe] = (try? await query.limit(6).execute().value) ?? []

        if rows.isEmpty {   // filter too narrow → show the general pool
            rows = try await supabase.from("starter_recipes")
                .select("time_bracket, recipes(*)").limit(6).execute().value
        }
        return rows
    }

    // MARK: - Metadata

    static func detectPlatform(_ urlString: String) -> String {
        guard let host = URL(string: urlString)?.host()?.lowercased() else { return "web" }
        if host.contains("tiktok") { return "tiktok" }
        if host.contains("instagram") { return "instagram" }
        if host.contains("youtube") || host.contains("youtu.be") { return "youtube" }
        return "web"
    }

    struct Metadata { let title: String?; let thumbnailUrl: String? }

    /// Best-effort og: tag scrape. Many platforms block this — nil is fine,
    /// the design has placeholder fallbacks everywhere.
    static func fetchMetadata(for urlString: String) async -> Metadata? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 6)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)",
                         forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let html = String(data: data, encoding: .utf8) else { return nil }
        return Metadata(title: ogContent("og:title", in: html),
                        thumbnailUrl: ogContent("og:image", in: html))
    }

    private static func ogContent(_ property: String, in html: String) -> String? {
        for pattern in [
            "<meta[^>]*property=\"\(property)\"[^>]*content=\"([^\"]+)\"",
            "<meta[^>]*content=\"([^\"]+)\"[^>]*property=\"\(property)\""
        ] {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range])
            }
        }
        return nil
    }
}
