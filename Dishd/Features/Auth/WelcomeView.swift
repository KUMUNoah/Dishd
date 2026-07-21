import SwiftUI

/// Opening screen — sign-up primary, log in one tap away.
struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                Wordmark(size: 52)
                Text("See what your friends are actually cooking")
                    .font(.system(size: 15))
                    .foregroundStyle(DishdColor.taupe)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.horizontal, 40)

                Spacer()

                VStack(spacing: 14) {
                    NavigationLink {
                        SignUpView()
                    } label: {
                        Text("Create account")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DishdColor.terracotta)
                            .clipShape(Capsule())
                    }

                    NavigationLink {
                        LogInView()
                    } label: {
                        (Text("Already on dishd? ")
                            .foregroundStyle(DishdColor.taupe)
                        + Text("Log in")
                            .foregroundStyle(DishdColor.terracotta)
                            .fontWeight(.semibold))
                            .font(.system(size: 14))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(DishdColor.screen)
        }
        .tint(DishdColor.terracotta)
    }
}

#Preview {
    WelcomeView()
}
