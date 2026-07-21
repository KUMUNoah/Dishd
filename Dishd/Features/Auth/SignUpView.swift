import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var appState: AppState

    @State private var name = ""
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var usernameAvailable: Bool?
    @State private var errorMessage: String?
    @State private var isWorking = false

    private var passwordsMatch: Bool {
        confirmPassword.isEmpty || password == confirmPassword
    }

    private var formValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 8
            && password == confirmPassword
            && username.count >= 3 && usernameAvailable != false
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                field("Name", text: $name)
                field("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)

                HStack {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: username) { checkUsername() }
                    if usernameAvailable == true {
                        Image(systemName: "checkmark").foregroundStyle(.green)
                    } else if usernameAvailable == false {
                        Image(systemName: "xmark").foregroundStyle(DishdColor.tomato)
                    }
                }
                .padding(14)
                .background(DishdColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))

                SecureField("Password (8+ characters)", text: $password)
                    .padding(14)
                    .background(DishdColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))

                SecureField("Re-enter password", text: $confirmPassword)
                    .padding(14)
                    .background(DishdColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(passwordsMatch ? DishdColor.border : DishdColor.tomato,
                                lineWidth: passwordsMatch ? 0.5 : 1))

                if !passwordsMatch {
                    Text("Passwords don't match.")
                        .font(.system(size: 13))
                        .foregroundStyle(DishdColor.tomato)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if usernameAvailable == false {
                    Text("That username's taken. Try another.")
                        .font(.system(size: 13))
                        .foregroundStyle(DishdColor.tomato)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(DishdColor.tomato)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(title: isWorking ? "Creating…" : "Create account",
                              isEnabled: formValid && !isWorking) {
                    Task { await submit() }
                }
                .padding(.top, 8)

                Text("By creating an account you agree to our [Terms of Service](\(Legal.termsURL)) and [Privacy Policy](\(Legal.privacyURL)).")
                    .font(.system(size: 12))
                    .foregroundStyle(DishdColor.taupe)
                    .tint(DishdColor.terracotta)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(24)
        }
        .background(DishdColor.screen)
        .navigationTitle("Create account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding(14)
            .background(DishdColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))
    }

    private func checkUsername() {
        usernameAvailable = nil
        guard username.count >= 3 else { return }
        let current = username
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard current == username else { return }
            usernameAvailable = await AuthService.isUsernameAvailable(current)
        }
    }

    private func submit() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await AuthService.signUp(email: email, password: password,
                                         username: username, fullName: name)
            Analytics.log("signup")
            appState.startOnboarding()
            await appState.didSignIn()
        } catch {
            let raw = "\(error)".lowercased()
            if raw.contains("already registered") || raw.contains("already been registered")
                || raw.contains("user_already_exists") {
                errorMessage = "That email already has an account. Try logging in."
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
}
