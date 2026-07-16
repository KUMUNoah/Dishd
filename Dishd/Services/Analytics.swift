import Foundation
import Supabase

/// v1 analytics: events land in our own analytics_events table.
/// Fire-and-forget — analytics must never break a user action.
enum Analytics {
    static func log(_ event: String, _ properties: [String: String] = [:]) {
        Task.detached {
            struct Event: Encodable {
                let user_id: UUID?
                let event: String
                let properties: [String: String]
            }
            _ = try? await supabase.from("analytics_events")
                .insert(Event(user_id: supabase.auth.currentUser?.id,
                              event: event,
                              properties: properties))
                .execute()
        }
    }
}
