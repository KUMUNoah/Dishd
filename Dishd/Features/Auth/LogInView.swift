import SwiftUI

struct LogInView: View {
    @EnvironmentObject private var appState: AppState

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isWorking = false

    var body: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .padding(14)
                .background(DishdColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))

            SecureField("Password", text: $password)
                .padding(14)
                .background(DishdColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(DishdColor.tomato)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: isWorking ? "Logging in…" : "Log in",
                          isEnabled: !email.isEmpty && !password.isEmpty && !isWorking) {
                Task { await submit() }
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(24)
        .background(DishdColor.screen)
        .navigationTitle("Log in")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await AuthService.logIn(email: email, password: password)
            await appState.didSignIn()
        } catch {
            errorMessage = "Couldn't log in. Check your email and password."
        }
    }
}
