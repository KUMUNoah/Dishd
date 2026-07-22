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

    /// Goes through an RPC, not the profiles table: this runs before sign-in,
    /// and profiles is no longer readable while unauthenticated.
    static func isUsernameAvailable(_ username: String) async -> Bool {
        struct Args: Encodable { let candidate: String }
        do {
            return try await supabase
                .rpc("username_available", params: Args(candidate: username.lowercased()))
                .execute()
                .value
        } catch {
            return true // fail open; the DB unique constraint is the backstop
        }
    }
}
