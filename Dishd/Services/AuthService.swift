import Foundation
import Supabase

enum AuthService {
    /// Signs up with username + name stashed in auth metadata;
    /// the on_auth_user_created trigger builds the profile row server-side.
    static func signUp(email: String, password: String, username: String, fullName: String) async throws {
        try await supabase.auth.signUp(
            email: email,
            password: password,
            data: [
                "username": .string(username.lowercased()),
                "full_name": .string(fullName)
            ]
        )
    }

    static func logIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(email: email, password: password)
    }

    static func isUsernameAvailable(_ username: String) async -> Bool {
        do {
            let matches: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("username", value: username.lowercased())
                .execute()
                .value
            return matches.isEmpty
        } catch {
            return true // fail open; DB unique constraint is the backstop
        }
    }
}
