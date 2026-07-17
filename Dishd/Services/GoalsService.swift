import Foundation
import Supabase

enum GoalsService {
    static func get() async -> Goals? {
        guard let me = supabase.auth.currentUser?.id else { return nil }
        let rows: [Goals]? = try? await supabase.from("goals")
            .select("cook_per_week,new_recipes_per_month")
            .eq("user_id", value: me)
            .execute().value
        return rows?.first
    }

    static func set(_ goals: Goals) async throws {
        guard let me = supabase.auth.currentUser?.id else { return }
        struct Row: Encodable {
            let user_id: UUID
            let cook_per_week: Int
            let new_recipes_per_month: Int
            let updated_at: Date
        }
        try await supabase.from("goals")
            .upsert(Row(user_id: me,
                        cook_per_week: goals.cookPerWeek,
                        new_recipes_per_month: goals.newRecipesPerMonth,
                        updated_at: Date()))
            .execute()
    }

    struct Progress {
        let cookedThisWeek: Int
        let newRecipesThisMonth: Int
    }

    /// Reviews are the "cooked it" signal, and (user, recipe) is unique,
    /// so this month's review count == new recipes tried this month.
    static func progress() async -> Progress {
        guard let me = supabase.auth.currentUser?.id else {
            return Progress(cookedThisWeek: 0, newRecipesThisMonth: 0)
        }
        let cal = Calendar.current
        let now = Date()
        let weekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let monthStart = cal.dateInterval(of: .month, for: now)?.start ?? now
        async let week = reviewCount(userId: me, since: weekStart)
        async let month = reviewCount(userId: me, since: monthStart)
        return await Progress(cookedThisWeek: week, newRecipesThisMonth: month)
    }

    private static func reviewCount(userId: UUID, since: Date) async -> Int {
        (try? await supabase.from("reviews")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId)
            .gte("created_at", value: since.ISO8601Format())
            .execute().count) ?? 0
    }
}
