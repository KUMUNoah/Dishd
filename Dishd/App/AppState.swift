import Foundation
import Supabase

enum AuthStatus {
    case loading
    case signedOut
    case signedIn
}

@MainActor
final class AppState: ObservableObject {
    @Published var authStatus: AuthStatus = .loading
    @Published var profile: Profile?
    @Published var needsOnboarding = false

    func startOnboarding() {
        needsOnboarding = true
    }

    func completeOnboarding() {
        needsOnboarding = false
    }

    func restoreSession() async {
        do {
            _ = try await supabase.auth.session
            await loadProfile()
            authStatus = .signedIn
        } catch {
            authStatus = .signedOut
        }
    }

    func loadProfile() async {
        guard let user = supabase.auth.currentUser else { return }
        do {
            let matches: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: user.id)
                .execute()
                .value
            if let found = matches.first {
                profile = found
            } else {
                // Self-heal: session exists but profile row is missing
                // (e.g. account created while signup trigger was broken).
                try await createMissingProfile(for: user)
            }
        } catch {
            Log.error("Profile load failed", error)
        }
    }

    private func createMissingProfile(for user: User) async throws {
        struct NewProfile: Encodable {
            let id: UUID
            let username: String
            let full_name: String?
        }
        let username = (user.userMetadata["username"]?.stringValue)
            ?? "user_\(user.id.uuidString.prefix(8).lowercased())"
        let fullName = user.userMetadata["full_name"]?.stringValue
        profile = try await supabase
            .from("profiles")
            .insert(NewProfile(id: user.id, username: username, full_name: fullName))
            .select()
            .single()
            .execute()
            .value
    }

    func didSignIn() async {
        // Only enter the app with a real session — sign-up without one
        // (e.g. pending email confirmation) must not slip through.
        do {
            _ = try await supabase.auth.session
        } catch {
            authStatus = .signedOut
            return
        }
        await loadProfile()
        authStatus = .signedIn
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        profile = nil
        authStatus = .signedOut
    }
}
