import Foundation
import Supabase

// Publishable key: safe to ship in the app binary. RLS is the security layer.
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://zzmffvjrqjweuggkgejc.supabase.co")!,
    supabaseKey: "sb_publishable_jmlWCipuBULA1pmhlsBIwA_ZQVFUjFV"
)
